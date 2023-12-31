//
//  DriveWebViewController.swift
//  SpaceKit
//
//  Created by liweiye on 2019/6/13.
//

import SnapKit
import UIKit
import WebKit
import EENavigator
import SKFoundation
import SKCommon
import RxSwift
import RxCocoa
import UniverseDesignDialog
import SKResource

class DriveWebViewController: BaseViewController, WKNavigationDelegate, UIScrollViewDelegate {
    private let bag = DisposeBag()
    private var loadingIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        return view
    }()
    private lazy var webView: DKWebView = {
        let view = DKWebView()
        view.backgroundColor = UIColor.ud.N00
        view.navigationDelegate = self
        view.scrollView.delegate = self
        return view
    }()

    let fileURL: SKFilePath
    private var displayMode: DrivePreviewMode
    weak var bizVCDelegate: DriveBizViewControllerDelegate?
    private let tapHandler = DriveTapEnterFullModeHandler()
    private let draggingHandler = DriveDraggingEnterFullModeHandler()
    weak var screenModeDelegate: DrivePreviewScreenModeDelegate?
    private var navigation: WKNavigation?
    //用于判定是否是由非用户主动滑动而触发didScroll事件的标志
    var isNonScrollEvent: Bool = true
    private var isLoaded = false
    
    // MARK: security copy
    private let token: String?
    private let hostToken: String?
    private let canCopyRelay: BehaviorRelay<Bool>
    private let canEditRelay: BehaviorRelay<Bool>
    private let enableCopySecurity: Bool
    private let copyManager: DriveCopyMananger
    var needSecurityCopy: Driver<(String?, Bool)> {
        let encryptId = ClipboardManager.shared.getEncryptId(token: hostToken)
        let refrenceToken = encryptId ?? token
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            return copyManager.monitorCopyPermission(token: refrenceToken, allowSecurityCopy: enableCopySecurity)
        } else {
            return copyManager.needSecurityCopyAndCopyEnable(token: refrenceToken,
                                                             canEdity: canEditRelay,
                                                             canCopy: canCopyRelay,
                                                             enableSecurityCopy: enableCopySecurity)
        }
    }
    // MARK: - 生命周期

    init(fileURL: SKFilePath,
         token: String?,
         hostToken: String?, // 附件宿主token, 用于单文档复制保护
         displayMode: DrivePreviewMode,
         canCopy: BehaviorRelay<Bool>,
         canEdit: BehaviorRelay<Bool>,
         enableCopySecurity: Bool = LKFeatureGating.securityCopyEnable,
         copyManager: DriveCopyMananger) {
        self.fileURL = fileURL
        self.token = token
        self.hostToken = hostToken
        self.canCopyRelay = canCopy
        self.canEditRelay = canEdit
        self.displayMode = displayMode
        self.enableCopySecurity = enableCopySecurity
        self.copyManager = copyManager
        super.init(nibName: nil, bundle: nil)
        webView.navigationDelegate = self
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        injectMargin()
        monitorPermissons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isLoaded { return }
        isLoaded = true
        SKFilePath.convertFileEncodingTypeAsync(fileURL: fileURL) { [weak self] url in
            guard let self = self else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.reloadContent(url: url.pathURL)
            }
        }
        // 如果出现缓存pdf先展示，同时右上角出现演示按钮，加载到新的fileInfo下载相似文件后重新加载需要移除右上角的演示按钮
        bizVCDelegate?.append(leftBarButtonItems: [], rightBarButtonItems: [])
    }

    // MARK: - UI

    func initUI() {
        statusBar.alpha = 0
        view.accessibilityIdentifier = "drive.web.view"
        navigationBar.isHidden = true
        view.backgroundColor = UIColor.clear
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        view.addSubview(loadingIndicatorView)
        loadingIndicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        loadingIndicatorView.startAnimating()

        if CacheService.isDiskCryptoEnable() {
            //KACrypto 禁止长按避免导出图片
            let wkUScript = WKUserScript(source: "document.documentElement.style.webkitTouchCallout='none';", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            self.webView.configuration.userContentController.addUserScript(wkUScript)
            DocsLogger.driveInfo("DriveWebViewController -- Disable webview long press while disk encrypted")
        }
    }
    
    // monitor permission changed
    private func monitorPermissons() {
        needSecurityCopy.map({ (token, _) in
            return token
        }).distinctUntilChanged()
            .drive(onNext: { [weak self] (token) in
            guard let self = self else { return }
            DocsLogger.driveInfo("DriveWebViewController -- token is nil \(token == nil)")
            self.webView.pointId = token
        }).disposed(by: bag)
        
        needSecurityCopy.map({ (_, canCopy) in
            return canCopy
        }).distinctUntilChanged()
            .drive(onNext: {[weak self] canCopy in
                guard let self = self else { return }
                if canCopy {
                    DocsLogger.driveInfo("enable user select")
                    self.enableUserSelect()
                } else {
                    DocsLogger.driveInfo("disable user select")
                    self.injectDisableUserSelect()
                }
        }).disposed(by: bag)
    }
    
    private func injectDisableUserSelect() {
        let selectionString = "var css = '*{-webkit-touch-callout:none;-webkit-user-select:none}';"
                + " var head = document.head || document.getElementsByTagName('head')[0];"
                + " var style = document.createElement('style'); style.type = 'text/css';" +
                " style.appendChild(document.createTextNode(css)); head.appendChild(style);"
            let selectionScript: WKUserScript = WKUserScript(source: selectionString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            webView.configuration.userContentController.addUserScript(selectionScript)
        reloadContent(url: fileURL.pathURL)
    }
    
    private func enableUserSelect() {
        webView.configuration.userContentController.removeAllUserScripts()
        injectMargin()
        reloadContent(url: fileURL.pathURL)
    }
    
    private func reloadContent(url: URL) {
        DocsLogger.driveInfo("DriveWebViewController -- load url: \(url), \(String(describing: url.scheme))")
        guard let navigation = webView.loadFileURL(url, allowingReadAccessTo: url) else {
            DocsLogger.driveError("cannot get navigation object")
            self.bizVCDelegate?.previewFailed(self, needRetry: false, type: self.openType, extraInfo: nil)
            return
        }
        self.navigation = navigation
    }

    /// 注入 body margin = 0 的 css style，处理 PPT 偏右的问题
    private func injectMargin() {
        let source = """
            var node = document.createElement('style');
            node.innerHTML = "body { margin:0; }";
            document.body.appendChild(node);
            """
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)
    }
    
// MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated:
            guard let url = navigationAction.request.url else {
                return
            }
            decisionHandler(.cancel)
            DocsLogger.driveDebug("drive.webVC.preview --- did click url link")
            // secLink数据上报
            self.bizVCDelegate?.statistic(action: .secLink, source: .unknow)
            Navigator.shared.push(url, from: self)
        default:
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else {
            // NSURLErrorCancelled: An asynchronous load has been canceled.
            DocsLogger.driveError("DriveWebViewController -- webview NSURLErrorCancelled: \(error.localizedDescription)")
            return
        }
        loadingIndicatorView.stopAnimating()
        DocsLogger.driveError("DriveWebViewController -- webview failed: \(error.localizedDescription)")
        bizVCDelegate?.previewFailed(self, needRetry: false, type: .webView, extraInfo: nil)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DocsLogger.driveError("DriveWebViewController -- webview failed: \(error.localizedDescription)")
        if #available(iOS 16.0, *) {
            // iOS16beta3 版本增加的属性，beta3以前的系统访问会crash，添加判断
            if let prefrence = webView.configuration.defaultWebpagePreferences,
               prefrence.responds(to: Selector(("isLockdownModeEnabled"))) {
                DocsLogger.driveError("DriveWebViewController -- webview failed isLockdownModel \(prefrence.isLockdownModeEnabled)")
                if prefrence.isLockdownModeEnabled {
                    showLockdownModeDialog()
                }
            }
        }
        loadingIndicatorView.stopAnimating()
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        DocsLogger.driveError("DriveWebViewController -- webview terminated")
        loadingIndicatorView.stopAnimating()
    }


    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let originNavigation = self.navigation, originNavigation == navigation else {
            return
        }
        loadingIndicatorView.stopAnimating()
        bizVCDelegate?.openSuccess(type: openType)
        self.navigation = nil
        setupWebViewTapGesture()
    }
// MARK: - UIScrollViewDelegate

    private func setupWebViewTapGesture() {
        tapHandler.addTapGestureRecognizer(targetView: webView) { [weak self] in
            guard let self = self else { return }
            self.isNonScrollEvent = true
            self.screenModeDelegate?.changeScreenMode()
            self.bizVCDelegate?.statistic(action: .clickDisplay, source: .unknow)
            self.isNonScrollEvent = false
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        draggingHandler.draggingStatusSwitch(targetView: scrollView) { [weak self] isScrollUp in
            guard let self = self else { return }
            guard self.isNonScrollEvent == false else { return }
            if isScrollUp {
                self.screenModeDelegate?.changePreview(situation: .fullScreen)
                self.bizVCDelegate?.statistic(action: .clickDisplay, source: .unknow)
            } else {
                self.screenModeDelegate?.changePreview(situation: .exitFullScreen)
                self.bizVCDelegate?.statistic(action: .clickDisplay, source: .unknow)
            }
        }
        self.isNonScrollEvent = false
    }
    
    private func showLockdownModeDialog() {
        var dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Perm_LockdownMode_Title())
        dialog.setContent(text: BundleI18n.SKResource.LarkCCM_Perm_LockdownMode_Description)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Perm_LockdownMode_GotIt_Button)
        self.present(dialog, animated: true)
    }
}

extension DriveWebViewController: DriveBizeControllerProtocol {
    var openType: DriveOpenType {
        return .webView
    }
    
    var panGesture: UIPanGestureRecognizer? {
        webView.scrollView.panGestureRecognizer
    }
    func willUpdateDisplayMode(_ mode: DrivePreviewMode) {
        if mode == .card {
            webView.scrollView.showsHorizontalScrollIndicator = false
            webView.scrollView.showsVerticalScrollIndicator = false
        }
    }
    
    func changingDisplayMode(_ mode: DrivePreviewMode) {
    }
    
    func updateDisplayMode(_ mode: DrivePreviewMode) {
        self.displayMode = mode
        if mode == .normal {
            webView.scrollView.showsHorizontalScrollIndicator = true
            webView.scrollView.showsVerticalScrollIndicator = true
        }
    }
}
