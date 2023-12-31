//
//  LiveWebViewContainer.swift
//  ByteViewLive
//
//  Created by yangyao on 2021/6/7.
//

import UIKit
import Foundation
import LarkUIKit
import LarkWebViewContainer
import RxSwift
import EENavigator
import LarkFoundation
import UniverseDesignIcon

// MARK: loading & retry
/// webview加载状态枚举
enum LoadingState {
    case `default`
    case willStartLoading
    case loading
    case failed
    case finish
}

struct FloatViewLayout {
    static let floatWindowWidth = 144
    static let floatWindowHeight = 81
}

public protocol LiveWebViewContainerDelegate: AnyObject {
    func showFloatView(container: LiveWebViewContainer)
    func stopAndCleanLive(container: LiveWebViewContainer)
    func stopLiveForMeeting(container: LiveWebViewContainer)
}

public final class LiveWebViewContainer: UIView {
    private let disposeBag = DisposeBag()
    
    let logger = Logger.live

    /// webview加载状态
    var state: LoadingState = .default

    /// 初始化时设置的URL
    let firstLoadURL: URL

    /// 获取webview的URL，若获取为空则默认为初始化时设置的URL
    var url: URL {
        return webView.url ?? firstLoadURL
    }

    var realLiveId: String?

    public weak var delegate: LiveWebViewContainerDelegate?

    let viewModel: LiveWebViewModel
    
    weak var liveVC: LarkLiveViewController?
    var gesture: UITapGestureRecognizer?

    lazy var loadingView = LoadingPlaceholderView()
    let liveWebBridgeDelegate: LarkLiveWebBridgeDelegate

    lazy var gestureView: UIView = {
        let view = UIView()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onViewTapped(_:)))
        self.gesture = gesture
        view.addGestureRecognizer(gesture)
        return view
    }()
    
    private lazy var liveLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkLive.Common_G_Player_Live_Label
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 10)
        return label
    }()

    private lazy var liveTagView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4.0
        view.backgroundColor = UIColor.ud.colorfulRed
        view.addSubview(liveLabel)
        liveLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(1)
            maker.bottom.equalToSuperview().offset(-1)
            maker.left.equalToSuperview().offset(3)
            maker.right.equalToSuperview().offset(-3)
        }
        return view
    }()

    private lazy var closeLiveButton: UIButton = {
        let image = BundleResources.LarkLive.livefloatclose
        // padding在主端小窗中失效，通过frame来调整点击区域大小
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.rx.tap.asDriver().drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.logger.info("closeLiveButton tapped")
            LiveNativeTracks.trackCloseInFloatWindow(liveId: self.realLiveId ?? "" , liveSessionId: self.viewModel.liveData.liveID)
            self.closeLiveWindow()
        }).disposed(by: disposeBag)

        // shadow
//        button.layer.ud.setShadowColor(UIColor(red: 0.122, green: 0.137, blue: 0.161, alpha: 0.12))
//        button.layer.shadowOpacity = 1
//        button.layer.shadowRadius = 4.0
//        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        return button
    }()

    
    init(url: URL) {
        firstLoadURL = url
        viewModel = LiveWebViewModel()
        liveWebBridgeDelegate = LarkLiveWebBridgeDelegate(viewModel: viewModel)
        super.init(frame: .zero)

        viewModel.delegate = self
        addSubview(webView)
        webView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        initWebBridge()
        addFloatControl()
        setFloatMode(false)
    }

    func initWebBridge() {
        let bridge = webView.lkwBridge
        bridge.registerBridge()
        bridge.set(larkWebViewBridgeDelegate: liveWebBridgeDelegate)
    }

    deinit {
        logger.info("live view container deinit")
    }

    func checkPlayStatus() {
        viewModel.checkPlayStatus()
    }
    /// 判断当前是有直播, 且处于播放状态
    func isLivingPlaying() -> Bool {
        return viewModel.isLivingPlaying()
    }
    /// 判断当前是否有直播
    func isLivingInPage() -> Bool {
        return viewModel.isLivingInPage()
    }

    // H5会根据window是否变化了来决定是否展示相应的样式
    func setFloatMode(_ float: Bool) {
        logger.info("set float mode: \(float)")

        setFloatViewControl(float)
        
        let params: [String : Any] = ["live_event": NativeToWebEvent.containerModeChange.rawValue,
                                      "params": ["mode": float ? NativeToWebEvent.ContainerMode.miniMode.rawValue : NativeToWebEvent.ContainerMode.normalMode.rawValue]]
        evaluateJS(params)
    }

    func evaluateJS(_ params: [String: Any]) {
        let finalMap: [String: Any] = [
            "callbackID": "lark_vc_live_bridge",
            "data": params,
            "callbackType": "continued"
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: finalMap) else { return }
        let str = String(data: data, encoding: .utf8) ?? ""
        let jsStr = "LarkWebViewJavaScriptBridge.nativeCallBack(\(str))"
        webView.evaluateJavaScript(jsStr)
    }
    
    func setFloatViewControl(_ float: Bool) {
        liveTagView.isHidden = !float
        closeLiveButton.isHidden = !float
        gestureView.isHidden = !float

        layer.masksToBounds = true
        layer.cornerRadius = float ? 8.0 : 0.0
        layer.borderWidth = float ? 0.5 : 0.0
        layer.ud.setBorderColor(float ? UIColor.ud.lineDividerDefault.withAlphaComponent(0.15) : UIColor.clear)
    }

    func addFloatControl() {
        addSubview(gestureView)
        gestureView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        addSubview(liveTagView)
        addSubview(closeLiveButton)

        liveTagView.snp.makeConstraints { make in
            make.height.equalTo(15)
            make.right.lessThanOrEqualTo(closeLiveButton.snp.left).offset(-2)
            make.top.equalToSuperview().offset(6)
            make.left.equalToSuperview().offset(6)
        }

        closeLiveButton.snp.makeConstraints { make in
            make.centerY.equalTo(liveTagView)
            make.right.equalToSuperview().offset(9)
            make.width.height.equalTo(45)
        }
    }

    @objc private func onViewTapped(_ sender: UITapGestureRecognizer) {
        logger.info("LiveFloatView on Tapped")
        LiveNativeTracks.trackBackToLivePageInFloatWindow(liveId: realLiveId ?? "", liveSessionId: viewModel.liveData.liveID)
        goLivePage()
    }

    private func goLivePage() {
        logger.info("goLivePage")
        if let url = LarkLiveManager.shared.url {
            LarkLiveManager.shared.startLive(url: url, webViewContainer: self, fromLink: false)
        } else {
            logger.error("no live link in liveData")
        }

        // 2s之后视图size不变，则表示push失败，需要将小窗的control设置回来
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let size = self.bounds.size
            if size == CGSize(width: FloatViewLayout.floatWindowWidth, height: FloatViewLayout.floatWindowHeight) {
                self.setFloatViewControl(true)
            }
        }
    }

    func closeLiveWindow() {
        LarkLiveManager.shared.stopAndCleanLive()
        logger.info("closeLiveWindow")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // fail view
    lazy var failView: UIView = {
        let view = LoadWebFailPlaceholderView()
        view.retryAction = { [weak self] in
            self?.logger.info("tap failView to retry")
            self?.failViewTap()
        }
        return view
    }()

    lazy var webView: LarkWebView = {
        logger.info("webview init")
        let configuration = WebViewControllerConfiguration(webBizType: LarkWebViewBizType("byteview"))

        configuration.webviewConfiguration.allowsInlineMediaPlayback = true
        configuration.webviewConfiguration.allowsAirPlayForMediaPlayback = true
        // websiteDataStore需要在processPool前初始化，否则cookie不会sync成功
        configuration.webviewConfiguration.websiteDataStore = WKWebsiteDataStore.default()
        configuration.webviewConfiguration.setValue(false, forKey: "allowUniversalAccessFromFileURLs")
        // 允许网页自动播放
        configuration.webviewConfiguration.mediaTypesRequiringUserActionForPlayback = []

        let config = LarkWebViewConfigBuilder()
            .setWebViewConfig(configuration.webviewConfiguration)
            .build(
                bizType: configuration.webBizType,
                isAutoSyncCookie: configuration.isAutoSyncCookie,
                secLinkEnable: configuration.secLinkEnable,
                performanceTimingEnable: configuration.performanceTimingEnable,
                vConsoleEnable: configuration.vConsoleEnable
            )

        let webview = LarkWebView(frame: .zero, config: config)
        // 业务方设置了UA才能发送JS事件，为了在demo上可以收到，主动设置
        webview.customUserAgent = LarkFoundation.Utils.userAgent
        webview.allowsBackForwardNavigationGestures = true
        webview.navigationDelegate = self
        webview.uiDelegate = self
        webview.scrollView.contentInsetAdjustmentBehavior = .never
        return webview
    }()
}

extension LiveWebViewContainer: WKNavigationDelegate {
    /// WKNavigationDelegate
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        self.logger.info("webView WebContentProcessDidTerminate, url:\(String(describing: webView.url))")
        LiveToast.showTips(with: BundleI18n.LarkLive.Common_M_ImageErrorTryAgainLater_Toast)
        
        if LarkLiveManager.shared.isLiveInFloatView {
            closeLiveWindow()
        }
    }

    ///  begin to receive web content
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        self.logger.info("didCommit navigation, url:\(String(describing: webView.url))")
        // 原有逻辑在执行didStartProvisionalNavigation时隐藏loading，但时间较早，会在web内容到达main frame之前存在一小段时间的白屏
        // 为优化用户体验，现调整为didCommit navigation时
        removeLoadingView()
    }

    /// start
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.logger.info("didStartProvisionalNavigation navigation, url:\(String(describing: webView.url))")
        startLoading()
    }

    /// start failed
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.logger.error("didFailProvisionalNavigation navigation", error: error)
        handleWebError(error: error)
    }

    /// finish
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.logger.info("didFinish navigation, url:\(String(describing: webView.url))")
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
        self.logger.info("didReceiveServerRedirectForProvisionalNavigation navigation, url:\(String(describing: webView.url))")
    }
}

extension LiveWebViewContainer: WKUIDelegate {
    /// WKUIDelegate
    ///
    /// window.open Tips: 目前 window.open 未完全按照标准实现，所以 window.open 打开的 window 暂时无法通过 window.close 关闭
    /// https://developer.mozilla.org/zh-CN/docs/Web/API/Window/open
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        self.logger.info("createWebViewWith configuration, navigationAction.request.url:\(navigationAction.request.url), navigationType:\(navigationAction.navigationType)")
        // 检查url不为空
        guard let url = navigationAction.request.url else {
            self.logger.error("createWebViewWith configuration, navigationAction.request.url is nil")
            return nil
        }

        // push新的vc打开，直接用lark的 web 打开
        // 通过from参数来维持打开后的url request请求头中的referer
        // 参考“biz.util.openLink”的实现. 历史对接人： @lizhong.limboy
        self.logger.info("createWebViewWith configuration, open by Navigator.shared.push")
        if let liveVC = liveVC {
            Navigator.shared.push(
                url,
                from: liveVC
            )
        }
        return nil
    }

    // 历史对接人 kangtao 上下文已不可考，请咨询 kangtao@bytedance.com
    /// window.alert
    /// https://developer.mozilla.org/zh-CN/docs/Web/API/Window/alert
    public func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        self.logger.info("runJavaScriptAlertPanelWithMessage \(message), isMainFrame: \(frame.isMainFrame)")
        let alertController = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )
        let completionHandlerCrashProtection = WKUIDelegateCrashProtection(completionHandler)
        alertController.addAction(UIAlertAction(
            title: BundleI18n.LarkLive.Common_G_FromView_ConfirmButton,
            style: .default,
            handler: { (_) in
                completionHandlerCrashProtection.callCompletionHandler()
            }
        ))
        liveVC?.present(alertController, animated: true, completion: nil)
    }

    /// window.confirm
    /// https://developer.mozilla.org/zh-CN/docs/Web/API/Window/confirm
    public func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        self.logger.info("runJavaScriptConfirmPanelWithMessage \(message), isMainFrame: \(frame.isMainFrame)")
        let alertController = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )
        let completionHandlerCrashProtection = WKUIDelegateCrashProtection(completionHandler, defaultCompletionHandlerParamsValue: false)
        alertController.addAction(UIAlertAction(
            title: BundleI18n.LarkLive.Common_G_FromView_ConfirmButton,
            style: .default,
            handler: { (_) in
                completionHandlerCrashProtection.callCompletionHandler(completionHandlerParamsValue: true)
            }
        ))
        alertController.addAction(UIAlertAction(
            title: BundleI18n.LarkLive.Common_G_FromView_CancelButton,
            style: .cancel,
            handler: { (_) in
                completionHandlerCrashProtection.callCompletionHandler(completionHandlerParamsValue: false)
            }
        ))
        liveVC?.present(alertController, animated: true, completion: nil)
    }

    /// window.prompt
    /// https://developer.mozilla.org/zh-CN/docs/Web/API/Window/prompt
    public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        self.logger.info("runJavaScriptTextInputPanelWithPrompt prompt{\(prompt)} & defaultText{\(defaultText)} & isMainFrame{\(frame.isMainFrame)}")
        let alertController = UIAlertController(
            title: prompt,
            message: nil,
            preferredStyle: UIAlertController.Style.alert
        )
        let completionHandlerCrashProtection = WKUIDelegateCrashProtection(completionHandler, defaultCompletionHandlerParamsValue: nil)
        alertController.addTextField { (textField) in
            if let text = defaultText {
                textField.text = text
            }
            textField.placeholder = ""
        }
        alertController.addAction(UIAlertAction(
            title: BundleI18n.LarkLive.Common_G_FromView_ConfirmButton,
            style: .default,
            handler: { [weak alertController] (_) in
                completionHandlerCrashProtection.callCompletionHandler(completionHandlerParamsValue: alertController?.textFields?.first?.text)
            }
        ))
        alertController.addAction(UIAlertAction(
            title: BundleI18n.LarkLive.Common_G_FromView_CancelButton,
            style: .cancel,
            handler: { (_) in
                completionHandlerCrashProtection.callCompletionHandler(completionHandlerParamsValue: nil)
            }
        ))
        liveVC?.present(alertController, animated: true, completion: nil)
    }
}


extension LiveWebViewContainer {
    /// 显示加载视图
    func showLoadingView() {
        self.logger.info("show loadingview")
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(2)
        }
        // 必须通过更改LoadingPlaceholderView的isHidden状态来开始/停止动画，未暴露play/stop接口 @liyuguo.jeffrey
        loadingView.isHidden = false
    }

    /// 移除加载视图
    func removeLoadingView() {
        // 必须通过更改LoadingPlaceholderView的isHidden状态来开始/停止动画，未暴露play/stop接口 @liyuguo.jeffrey
        self.logger.info("remove loadingview")
        loadingView.isHidden = true
        loadingView.removeFromSuperview()
    }

    /// 开始loading
    func startLoading() {
        removeFailView()
        state = .loading
    }

    /// 显示失败视图
    func showFailView() {
        self.logger.info("show failview")
        addSubview(failView)
        failView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        // 必须通过更改LoadWebFailPlaceholderView的isHidden状态，
        // 因为它在retryTapped方法内强行设置了isHidden=true @zhaochen.09
        failView.isHidden = false
    }

    /// 移除失败视图
    func removeFailView() {
        self.logger.info("remove failview")
        // 与上面的isHidden = false配对使用，为预防LarkUIKit内相关逻辑被更改时对这里造成影响
        failView.isHidden = true
        failView.removeFromSuperview()
    }

    /// action for tapping fail view
    func failViewTap() {
        self.logger.info("failViewTap")
        loadURL(self.url, showLoading: true)
    }

    func renewURL(with url: URL) -> URL {
        return viewModel.renewURL(with: url)
    }
    /// 加载URL，并定制是否显示loading
    func loadURL(_ url: URL, showLoading: Bool = false) {
        removeFailView()
        if showLoading {
            showLoadingView()
        }
        webView.load(URLRequest(url: url))
    }

    /// 加载失败视图
    func loadFail(error: Error) {
        removeLoadingView()
        showFailView()
        state = .failed
    }

    /// 处理网页加载异常
    func handleWebError(error: Error) {
        loadFail(error: error)
        self.logger.error("load page error: \(error)")
    }
}

extension LiveWebViewContainer: LiveWebViewModelDelegate {
    func showFloatView(viewModel: LiveWebViewModel) {
        self.delegate?.showFloatView(container: self)
    }

    func stopAndCleanLive(viewModel: LiveWebViewModel) {
        self.delegate?.stopAndCleanLive(container: self)
    }

    func stopLiveForMeeting(viewModel: LiveWebViewModel) {
        self.delegate?.stopLiveForMeeting(container: self)
    }
}
