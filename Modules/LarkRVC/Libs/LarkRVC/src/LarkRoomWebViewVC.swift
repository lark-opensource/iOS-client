//
//  LarkRoomWebViewVC.swift
//  LarkRVC
//
//  Created by zhouyongnan on 2022/7/12.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import LarkWebViewContainer
import LarkUIKit
import LarkFoundation
import UniverseDesignColor
import LarkContainer
import LarkStorage

public final class LarkRoomWebViewVC: UIViewController {

    let logger = LarkRoomWebViewManager.logger

    let disposeBag = DisposeBag()
    lazy var webView: LarkWebView = createWebView()
    /// loading view
    lazy var loadingView = LoadingPlaceholderView()
    // fail view
    lazy var failView: UIView = createFailView()
    lazy var documentPath = IsoPath
        .user(id: userID)
        .in(domain: Domain.biz.byteView.child("LarkRVC"))
        .build(.document)

    private(set) var url: URL
    let userID: String
    var userInfo: [String: String] = [:]

    /// webview加载状态
    var state: LoadingState = .default

    /// 当页面deinit时，是否要添加小窗
    private (set) var needShowFloatWindowWhenClose: Bool = false
    private var fromNav: UINavigationController?

    var callback: APICallbackProtocol?

    // 页面关闭时执行回调
    public var closePageCallBack: ((LarkRoomWebViewVC) -> Void)?

    private var isInit: Bool = false

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindEvent()
        configURLWithCloseOption()
        fromNav = navigationController
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isInit {
            /// 在viewDidAppear中获取到的safeAreaInsets才是真实的，在viewDidLoad和ViewWillAppear中获取的都是0
            /// 之所以没有使用keyWindow的safeAreaInsets是因为在进入这个页面之前，keyWindow可能是横屏的，那么获取到的safeAreaInsets的top就是0
            let windowPaddingTop = view.window?.safeAreaInsets.top
            let viewPaddingTop = view.safeAreaInsets.top
            let paddingTop = windowPaddingTop ?? viewPaddingTop
            view.backgroundColor = UDColor.bgBody
            url = url.append(parameters: [LarkRoomWebViewManager.URLParams.paddingTop.rawValue: "\(paddingTop)"])
            logger.info("load larkRoomWebViewVC, paddingTop = \(paddingTop), windowPaddingTop = \(windowPaddingTop), viewPaddingTop = \(viewPaddingTop)")
            loadURL(url, showLoading: true)
            isInit = true
        }
    }

    init(userID: String, url: URL) {
        self.userID = userID
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    deinit {
        if needShowFloatWindowWhenClose {
            if let nav = self.fromNav {
                LarkRoomWebViewManager.addFloatingWindowModeIfNeeded(userID: userID, fromVC: nav, url: self.url)
            } else {
                logger.error("did not find navigationController, cannot set float window!")
            }
        }
        logger.info("LarkRoomWebViewVC has released! needShowFloatWindowWhenClose = \(needShowFloatWindowWhenClose)")
    }
}

extension LarkRoomWebViewVC {

    private func configURLWithCloseOption() {
        var forbidden: String = "false"
        if let nav = navigationController, nav.viewControllers.count == 1 {
            forbidden = "true"
        }
        let adjuestURL = url.append(parameters: ["forbiddenClose": forbidden])
        url = adjuestURL
        logger.info("configURLWithCloseOption, forbidden: \(forbidden)")
    }

    private func bindEvent() {
        LarkRoomWebViewManager.saveResultObservable.subscribe(onNext: { [weak self] result in
            self?.logger.info("saveResult: \(result)")
            if let self = self, let callback = self.callback {
                if result {
                    callback.callbackSuccess()
                } else {
                    callback.callbackFailure()
                }
            }
        }).disposed(by: disposeBag)

        if let handle = LarkRoomWebViewManager.getWatermarkInfoHandler {
            handle(userID).subscribe(onNext: { [weak self](userName, phone) in
                guard let self = self else { return }
                self.userInfo["userName"] = userName
                self.userInfo["phone"] = phone
            }).disposed(by: disposeBag)
        }
    }

    private func setupView() {
        view.backgroundColor = UDColor.bgBody
        view.addSubview(webView)
        webView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalTo(additionalSafeAreaInsets.bottom)
            make.left.right.equalToSuperview()
        }
    }

    private func createWebView() -> LarkWebView {
        let webView = LarkWebView(frame: .zero,
                                  config: webViewConfig)
        webView.backgroundColor = UDColor.bgBody
        webView.isOpaque = false
        // 注册bridge通道
        webView.lkwBridge.registerBridge()
        webView.lkwBridge.set(larkWebViewBridgeDelegate: self)
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.customUserAgent = Utils.userAgent
        return webView
    }

    private func createFailView() -> LoadFaildRetryView {
        let view = LoadWebFailPlaceholderView()
        view.retryAction = { [weak self] in
            self?.logger.info("tap failView to retry")
            self?.failViewTap()
        }
        return view
    }

    private var webViewConfig: LarkWebViewConfig {
        let builder = LarkWebViewConfigBuilder()
        if #available(iOS 13.0, *) {
            // iOS 13之后 ipad mini的ua还是ipad，但其他ipad的ua变成了pc，这里统一成mobile显示方式
            let config = WKWebViewConfiguration()
            config.defaultWebpagePreferences.preferredContentMode = .mobile
            builder.setWebViewConfig(config)
        }
        let config = builder.build(bizType: LarkWebViewBizType("LarkRVC"),
                                                      isAutoSyncCookie: true,
                                                      secLinkEnable: true,
                                                      performanceTimingEnable: true,
                                                      vConsoleEnable: false)
        return config
    }

}

extension LarkRoomWebViewVC: LarkWebViewBridgeDelegate {

    public func invoke(with message: APIMessage, webview: LarkWebView, callback: APICallbackProtocol) {
        guard let bridge = LarkRoomWebViewBridge.createBridge(with: message) else {
            LarkRoomWebViewManager.logger.error("unknown js bridge message: \(message)")
            return
        }
        LarkRoomWebViewManager.logger.info("LarkRoomWebViewVC receive JSBridge event, api:\(bridge.type), data:\(bridge.data)")
        switch bridge.type {
        case .rvc_close, .wb_close, .common_close:
            closePage(bridge: bridge)
        case .rvc_shareToChat:
            guard let meetingId = bridge.data["meetingId"] as? String,
                  let from = bridge.data["from"] as? String else {
                      LarkRoomWebViewManager.logger.error("Missing key params")
                return
            }
            LarkRoomWebViewManager.shareMeetingToChat(userID: userID, meetingId: meetingId, fromPlatform: from, fromVC: self)
        case .rvc_bind:
            guard let hasBind = bridge.data["hasBind"] as? Bool else {
                LarkRoomWebViewManager.logger.error("Missing key params")
                return
            }
            needShowFloatWindowWhenClose = hasBind
        case .rvc_closeFloatWindow:
            LarkRoomWebViewManager.logger.info("close rvc float window")
            LarkRoomWebViewManager.closeRVCFloatWindow()
        case .copyText:
            guard let text = bridge.data["text"] as? String else {
                LarkRoomWebViewManager.logger.error("Missing key params")
                return
            }
            DispatchQueue.main.async {
                LarkRoomWebViewManager.copyMessageWithSecurity?(text, true)
            }
        case .rvc_log, .wb_log, .common_log:
            guard let text = bridge.data["message"] as? String,
                  let level = bridge.data["level"] as? Int else {
                      LarkRoomWebViewManager.logger.error("Missing key params")
                return
            }
            if level == 3 { // error
                LarkRoomWebViewManager.loggerH5.error(text)
            } else if level == 2 { // warning
                LarkRoomWebViewManager.loggerH5.warn(text)
            } else { // info
                LarkRoomWebViewManager.loggerH5.info(text)
            }
        case .getUserInfo, .wb_getUserInfo:
            self.logger.info("getUserInfo isEmpty: \(userInfo.isEmpty)")
            callback.callbackSuccess(param: userInfo)
        case .cachefile, .wb_cachefile:
            guard let filename = bridge.data["filename"] as? String,
                  let fileToken = bridge.data["fileToken"] as? String,
                  let fileData = bridge.data["fileContent"] as? String else {
                      LarkRoomWebViewManager.logger.error("Missing key params")
                      callback.callbackFailure()
                      return
                  }
            if filename.contains("/") || fileToken.contains("/") {
                // filename 和filetoken中不能包含/, 否则可能被作为路径 保存到非预期为止，注入破坏代码
                // 详见：https://bytedance.feishu.cn/docx/JGeXd5vx1oGBbNxRtCvcTwK7nTh
                LarkRoomWebViewManager.logger.error("file name or fileToken content has '/' which is illegal string")
                callback.callbackFailure()
                return
            }
            guard let result = LarkRoomWebViewManager.cacheFile(userInfo: userInfo, filename: filename, fileToken: fileToken, fileData: fileData, sandboxPath: self.documentPath) else {
                callback.callbackFailure()
                return
            }
            callback.callbackSuccess(param: ["result": result])
        case .shareToChat, .wb_shareToChat:
            guard let paths = bridge.data["path"] as? [String] else {
                LarkRoomWebViewManager.logger.error("Missing key params")
                return
            }
            LarkRoomWebViewManager.sharePhotoToChat(userID: userID, paths: paths, fromVC: self)
            callback.callbackSuccess()
        case .saveImages, .wb_saveImages:
            guard let paths = bridge.data["path"] as? [String] else {
                LarkRoomWebViewManager.logger.error("Missing key params")
                return
            }
            let psdaToken = "LARK-PSDA-white_board_save_images"
            LarkRoomWebViewManager.saveImagesToPhotosAlbum(paths: paths, psdaToken: psdaToken)
            self.callback = callback
        }
    }

    func closePage(bridge: LarkRoomWebViewBridge) {
        let needFloatingWindow = bridge.data["needFloatingWindow"] as? Bool ?? false
        let toast = bridge.data["toast"] as? String ?? ""

        if let nav = self.navigationController, nav.viewControllers.count > 1 {
            logger.info("pop LarkRoomWebViewVC")
            nav.popViewController(animated: true)
        } else {
            logger.info("dismiss LarkRoomWebViewVC if needed")
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
        if let closeCallBack = closePageCallBack {
            logger.info("close call back not null, execute close call back")
            closeCallBack(self)
        }

        self.needShowFloatWindowWhenClose = needFloatingWindow

        if !toast.isEmpty {
            LarkRoomWebViewManager.showToast(content: toast)
        }
        logger.info("lark room webview viewController has been closed!")
    }
}

struct LarkRoomWebViewBridge {
    enum BridgeType: String {
        case common_close = "common.close" // 关闭
        case common_log = "common.log" // 通用h5日志
        case getUserInfo = "common.user_info"
        case cachefile = "common.cache_file"
        case shareToChat = "common.share_images"// 分享至会话
        case saveImages = "common.save_images"
        case wb_getUserInfo = "whiteboard.user_info"
        case wb_cachefile = "whiteboard.cache_file"
        case wb_shareToChat = "whiteboard.share_images"// 分享至会话
        case wb_saveImages = "whiteboard.save_images"
        case rvc_close = "rvc.close" // 关闭
        case wb_close = "whiteboard.close"

        case rvc_shareToChat = "rvc.shareMeeting"// 分享至会话
        case rvc_bind = "rvc.hasBind" // 是否绑定
        case rvc_closeFloatWindow = "rvc.closeFloatWindow" // 触发关闭RVC悬浮窗
        case copyText = "rvc.copyText" // 拷贝至粘贴板
        case rvc_log = "rvc.log" // 打印h5日志

        case wb_log = "whiteboard.log" // 打印h5日志
    }
    let type: BridgeType
    let data: [String: Any]

    static func createBridge(with message: APIMessage) -> LarkRoomWebViewBridge? {
        guard let type = BridgeType(rawValue: message.apiName) else { return nil }
        return LarkRoomWebViewBridge(type: type, data: message.data)
    }
}

extension LarkRoomWebViewVC: WKNavigationDelegate {
    ///  begin to receive web content
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // 原有逻辑在执行didStartProvisionalNavigation时隐藏loading，但时间较早，会在web内容到达main frame之前存在一小段时间的白屏
        // 为优化用户体验，现调整为didCommit navigation时
        removeLoadingView()
        var needShowNavigationBar = true
        let urlString = webView.url?.absoluteString
        if let path = webView.url?.path {
            LarkRoomWebViewManager.hiddenNavigationBarPathList.forEach { needHiddenPath in
                if needHiddenPath == path {
                    needShowNavigationBar = false
                    return
                }
            }
        }
        self.logger.info("didCommit navigation, url:\(getUrlPathString(webView.url)), needShowNavigationBar = \(needShowNavigationBar)")
        self.navigationController?.setNavigationBarHidden(!needShowNavigationBar, animated: true)
    }

    /// start
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.logger.info("didStartProvisionalNavigation navigation, url:\(getUrlPathString(webView.url))")
        startLoading()
    }

    /// start failed
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.logger.error("didFailProvisionalNavigation navigation", error: error)
        let err = error as NSError
        if err.code == NSURLErrorCancelled {
            return
        }
        handleWebError(error: error)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    /// finish
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.logger.info("didFinish navigation, url:\(getUrlPathString(webView.url))")
        state = .finish
    }

    /// nav failed
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.logger.error("didFail navigation", error: error)
        handleWebError(error: error)
    }

    /// recieve server redirect
    public func webView(_ webView: WKWebView,
                        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        self.logger.info("didReceiveServerRedirectForProvisionalNavigation navigation, url:\(getUrlPathString( webView.url))")
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    private func getUrlPathString(_ url: URL?) -> String {
        guard let urlResult = url else {
            return "(empty url)"
        }
        return "(host: \(urlResult.host ?? ""), path: \(urlResult.path))"
    }
}

class LoadWebFailPlaceholderView: LoadFaildRetryView {
    override var image: UIImage? {
        return BundleResources.LarkRVC.web_failed
    }
}
