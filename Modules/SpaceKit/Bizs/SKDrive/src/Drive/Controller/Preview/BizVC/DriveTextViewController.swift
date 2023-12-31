//
//  DriveTextViewController.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/11/25.
//

import EENavigator
import JavaScriptCore
import SnapKit
import SKUIKit
import WebKit
import SKCommon
import SKFoundation
import UniverseDesignColor
import UniverseDesignLoading
import RxSwift
import RxCocoa
import UniverseDesignToast
import SKResource

class DriveTextViewController: UIViewController {
    
    enum RenderSource {
        case url(fileURL: URL, baseURL: URL)
        case content(String)
    }
    
    let bag = DisposeBag()
    private var renderWebviewSource: RenderSource?
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    private lazy var webView: DKWebView = {
        let view = DKWebView()
        view.backgroundColor = UIColor.ud.N00
        view.navigationDelegate = self
        return view
    }()

    private lazy var textView: DKTextView = {
        let view = DKTextView()
        view.isEditable = false
        view.backgroundColor = UDColor.primaryOnPrimaryFill
        view.systemMenuInterceptor = self
        return view
    }()

    private var loadingIndicatorView: UDSpin = {
        let view = UDLoading.spin(config: UDSpinConfig(indicatorConfig: UDSpinIndicatorConfig(size: 20, color: UDColor.N400), textLabelConfig: nil))
        return view
    }()

    private var displayMode: DrivePreviewMode
    private let tapHandler = DriveTapEnterFullModeHandler()
    private var tapTimer: Timer?
    /// 是否需要加载内容
    private var shouldLoaded: Bool = true
    /// 是否已经加载过内容
    private var isLoaded: Bool = false

    weak var bizVCDelegate: DriveBizViewControllerDelegate?
    weak var screenModeDelegate: DrivePreviewScreenModeDelegate?
    private let viewModel: DriveTextPreviewViewModel

    init(viewModel: DriveTextPreviewViewModel, displayMode: DrivePreviewMode) {
        self.viewModel = viewModel
        self.displayMode = displayMode
        super.init(nibName: nil, bundle: nil)
        viewModel.renderDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.setup()
        setupUI()
        monitorPermissions()
    }

    private func monitorPermissions() {
        viewModel.needSecurityCopyDriver.map({ (token, _) in
            return token
        }).distinctUntilChanged()
            .drive(onNext: { [weak self] (token) in
            guard let self = self else { return }
            DocsLogger.driveInfo("DriveTextViewController -- token is nil \(token == nil)")
                self.textView.pointId = token
                self.webView.pointId = token
            }).disposed(by: bag)
        
        viewModel.needSecurityCopyDriver.map({ (_, canCopy) in
            return canCopy
        }).distinctUntilChanged()
            .drive(onNext: {[weak self] canCopy in
                guard let self = self else { return }
                DocsLogger.driveInfo("DriveTextViewController -- can Copy \(canCopy)")
                if !canCopy {
                    self.injectDisableUserSelect()
                } else {
                    self.enableUserSelect()
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
       reloadWebview()
    }
    
    private func enableUserSelect() {
        webView.configuration.userContentController.removeAllUserScripts()
        reloadWebview()
    }
    private func setupUI() {
        view.accessibilityIdentifier = "drive.text.view"
        view.backgroundColor = UIColor.ud.N00
        view.addSubview(loadingIndicatorView)
        loadingIndicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        startLoading()
        if CacheService.isDiskCryptoEnable() {
            //KACrypto 禁止长按避免导出图片
            let wkUScript = WKUserScript(source: "document.documentElement.style.webkitTouchCallout='none';", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            self.webView.configuration.userContentController.addUserScript(wkUScript)
            DocsLogger.driveInfo("forbid long presss when encrypted")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isLoaded { return }
        guard shouldLoaded else { return }
        isLoaded = true
        viewModel.loadContent()
    }
    
    private func startLoading() {
        loadingIndicatorView.isHidden = false
        loadingIndicatorView.reset()
    }
    private func stopLoading() {
        loadingIndicatorView.isHidden = true
    }
    
    private func reloadWebview() {
        guard let renderSource = self.renderWebviewSource else {
            DocsLogger.driveInfo("drive.text.preview --- web view not rendered")
            return
        }
        switch renderSource {
        case .url(let fileURL, let baseURL):
            webView.loadFileURL(fileURL, allowingReadAccessTo: baseURL)
        case .content(let content):
            webView.loadHTMLString(content, baseURL: nil)
        }
    }
}

/// TextView Related
extension DriveTextViewController {

    private func setupTextView() {
        UIView.performWithoutAnimation {
            view.insertSubview(textView, belowSubview: loadingIndicatorView)
            textView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            view.layoutIfNeeded()
        }
    }

    private func renderRichTextView(content: NSAttributedString) {
        textView.attributedText = content
        stopLoading()
        DocsLogger.driveInfo("drive.text.preview --- loading complete with richTextView")
        tapHandler.addTapGestureRecognizer(targetView: self.textView) { [weak self] in
            self?.screenModeDelegate?.changeScreenMode()
        }
        bizVCDelegate?.openSuccess(type: openType)
    }
}

// MARK: - WebView Related
extension DriveTextViewController {

    private func setupWebView() {
        UIView.performWithoutAnimation {
            view.insertSubview(webView, belowSubview: loadingIndicatorView)
            webView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            view.layoutIfNeeded()
        }
    }
}

// MARK: - WKNavigationDelegate
extension DriveTextViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated:
            self.tapTimer?.invalidate()
            decisionHandler(.cancel)
            guard let url = navigationAction.request.url else {
                return
            }
            DocsLogger.debug("drive.text.preview --- did click url link")
            /// secLink数据上报
            self.bizVCDelegate?.statistic(action: .secLink, source: .unknow)
            Navigator.shared.push(url, from: self)
        default:
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard viewModel.renderMode != .plainText else {
            stopLoading()
            bizVCDelegate?.openSuccess(type: openType)
            setupWebViewTapGesture()
            return
        }
        viewModel.loadWebContent()
    }
}

// MARK: - DriveTextRenderDelegate
extension DriveTextViewController: DriveTextRenderDelegate {

    func renderPlainText(content: String) {
        setupWebView()
        let textTemplate = """
        <html>
            <head> <meta name="viewport" content="width=device-width, initial-scale=1"> </head>
            <body> <pre style="word-wrap: break-word; white-space: pre-wrap;">%@</pre> </body>
        </html>
        """
        let renderContent = String(format: textTemplate, content)
        self.renderWebviewSource = .content(renderContent)
        self.webView.loadHTMLString(renderContent, baseURL: nil)
    }

    func renderRichText(content: NSAttributedString) {
        setupTextView()
        renderRichTextView(content: content)
    }

    func loadHTMLFileURL(_ fileURL: URL, baseURL: URL) {
        self.renderWebviewSource = .url(fileURL: fileURL, baseURL: baseURL)
        webView.loadFileURL(fileURL, allowingReadAccessTo: baseURL)
    }

    func evaluateJavaScript(_ script: String, completionHandler: ((Any?, Error?) -> Void)?) {
        webView.evaluateJavaScript(script, completionHandler: completionHandler)
    }

    func webViewRenderSuccess() {
        setupWebView()
        setupWebViewTapGesture()
        stopLoading()
        bizVCDelegate?.openSuccess(type: openType)
    }

    private func setupWebViewTapGesture() {
        tapHandler.addTapGestureRecognizer(targetView: webView) { [weak self] in
            guard let self = self else { return }
            self.tapTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) {[weak self] _ in
                self?.screenModeDelegate?.changeScreenMode()
                self?.tapTimer?.invalidate()
            }
        }
    }

    func renderFailed() {
        shouldLoaded = false
        stopLoading()
        bizVCDelegate?.previewFailed(self, needRetry: false, type: openType, extraInfo: nil)
    }

    func fileUnsupport(reason: DriveUnsupportPreviewType) {
        shouldLoaded = false
        stopLoading()
        bizVCDelegate?.unSupport(self, reason: reason, type: openType)
    }
}

extension DriveTextViewController: DriveBizeControllerProtocol {
    var openType: DriveOpenType {
        return .textView
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

extension DriveTextViewController: SKSystemMenuInterceptorProtocol {
    func canPerformSystemMenuAction(_ action: Selector, withSender sender: Any?) -> Bool? {
        if action == #selector(UIResponderStandardEditActions.selectAll(_:)) {
            // 屏蔽 UIMenuController 中的 "全选" 按钮
            // 全选是系统默认的按钮，无法通过设置 UIMenuController 屏蔽
            return false
        }
        return nil
    }

    // MARK: - UIMenu Interceptor
    func interceptCopy(_ sender: Any?) -> Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let (allow, completion) = viewModel.checkCopyPermission()
            completion(self)
            // intercept 与 allow 是相反的概念
            return !allow
        } else {
            return legacyInterceptCopy()
        }
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func legacyInterceptCopy() -> Bool {
        let result = viewModel.needCopyIntercept()
        if let iscacIntercept = result.iscacIntercept, iscacIntercept {
            CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmCopy, fileBizDomain: .ccm, docType: .file, token: viewModel.token)
        } else if let reason = result.reason, let type = result.type, result.needInterceptCopy {
            UDToast.docs.showMessage(reason, on: view.window ?? view, msgType: type)
        }
        return result.needInterceptCopy
    }
}
