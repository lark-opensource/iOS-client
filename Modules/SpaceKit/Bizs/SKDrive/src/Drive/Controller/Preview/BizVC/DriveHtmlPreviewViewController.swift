//
//  DriveHtmlPreviewViewController.swift
//  SKECM
//
//  Created by zenghao on 2021/1/18.
//

import SnapKit
import UIKit
import EENavigator
import JavaScriptCore
import SKFoundation
import SKCommon
import SKUIKit
import WebKit
import UniverseDesignColor
import UniverseDesignLoading
import RxSwift
import RxCocoa

class LeakAvoider: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    init(_ delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.delegate?.userContentController( userContentController, didReceive: message)
    }
}


class DriveHtmlPreviewViewController: UIViewController {
    private let bag = DisposeBag()
    enum HTMLPreviewJSEventName: String, CaseIterable {
        case getInitialData
        case firstScreenPainted
        case currentTabChanged
        case copyWithoutPermission
        case requestCachedData
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    private let htmlPreviewViewModel: DriveHTMLPreviewViewModel
    
    weak var bizVCDelegate: DriveBizViewControllerDelegate?
    private var displayMode: DrivePreviewMode
    /// 是否已经加载过内容
    private var isLoaded: Bool = false

    private var loadingIndicatorView: UDSpin = {
        let view = UDLoading.spin(config: UDSpinConfig(indicatorConfig: UDSpinIndicatorConfig(size: 20, color: UDColor.N400), textLabelConfig: nil))
        return view
    }()
    
    private lazy var webView: WKWebView = {
        let view = WKWebView()
        view.backgroundColor = UIColor.ud.N00
        view.navigationDelegate = self
        return view
    }()
    
    init(viewModel: DriveHTMLPreviewViewModel, displayMode: DrivePreviewMode) {
        htmlPreviewViewModel = viewModel
        self.displayMode = displayMode
        super.init(nibName: nil, bundle: nil)
        viewModel.renderDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        unregisterJSEventHandler()
        DocsLogger.driveInfo("DriveHtmlPreviewViewController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWebView()
        registerJSEventHandler()
        setupViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !isLoaded else { return }
        isLoaded = true
        htmlPreviewViewModel.loadContent()
    }
    
    private func setupViewModel() {
        htmlPreviewViewModel.needSecurityCopy.map({ (token, _) in
            return token
        }).distinctUntilChanged()
            .drive(onNext: { [weak self] (token) in
            guard let self = self else { return }
            DocsLogger.driveInfo("DriveHtmlPreviewViewController -- token is nil \(token == nil)")
            self.webView.pointId = token
        }).disposed(by: bag)
        
        htmlPreviewViewModel.needSecurityCopy.map({ (_, canCopy) in
            return canCopy
        }).distinctUntilChanged()
            .drive(onNext: {[weak self] canCopy in
                guard let self = self else { return }
                DocsLogger.driveInfo("DriveHtmlPreviewViewController -- can copy \(canCopy)")
                self.htmlPreviewViewModel.updatePermissionToJS(canCopy: canCopy)
        }).disposed(by: bag)
    }

    private func setupUI() {
        view.accessibilityIdentifier = "drive.htmlPreview.view"
        
        view.backgroundColor = UIColor.ud.N00
        view.addSubview(loadingIndicatorView)
        loadingIndicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        loadingIndicatorView.isHidden = false
        loadingIndicatorView.reset()
        
        if CacheService.isDiskCryptoEnable() {
            //KACrypto 禁止长按避免导出图片
            let wkUScript = WKUserScript(source: "document.documentElement.style.webkitTouchCallout='none';", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            webView.configuration.userContentController.addUserScript(wkUScript)
            DocsLogger.driveInfo("加密时DriveWebView禁止长按")
        }
    }
    
    private func registerJSEventHandler() {
        webView.configuration.userContentController.add(LeakAvoider(self), name: "jsObj")
    }
    
    private func unregisterJSEventHandler() {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "jsObj")
    }
    
}

// MARK: - WebView Related
extension DriveHtmlPreviewViewController {

    private func setupWebView() {
        view.insertSubview(webView, belowSubview: loadingIndicatorView)
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - WKNavigationDelegate
extension DriveHtmlPreviewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated:
            decisionHandler(.cancel)
            guard let url = navigationAction.request.url else {
                return
            }
            DocsLogger.debug("drive.htmlPreview.preview --- did click url link")
            /// secLink数据上报
            self.bizVCDelegate?.statistic(action: .secLink, source: .unknow)
            Navigator.shared.push(url, from: self)
        default:
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webViewRenderSuccess()
    }
}

extension DriveHtmlPreviewViewController: DriveHTMLRenderDelegate {
    
    func loadHTMLFileURL(_ fileURL: URL, baseURL: URL?) {
        let baseUrl = baseURL ?? fileURL.deletingLastPathComponent()
        webView.loadFileURL(fileURL, allowingReadAccessTo: baseUrl)
    }

    func evaluateJavaScript(_ script: String, completionHandler: ((Any?, Error?) -> Void)?) {
        webView.evaluateJavaScript(script, completionHandler: completionHandler)
    }

    func webViewRenderSuccess() {
        loadingIndicatorView.isHidden = true
    }
    
    func webViewRenderFailed() {
        DocsLogger.warning("webViewRenderFailed")
    }
    
    func fileUnsupport(reason: DriveUnsupportPreviewType) {
        // 添加不支持处理
    }
    
}

extension DriveHtmlPreviewViewController: WKScriptMessageHandler {

// JS message:
//    jsObj, {
//       method = getInitialData;
//       params = "";
//   }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        DocsLogger.driveInfo("receive JS Messange: \(message.name), \(message.body)")
        guard let jsonObj = message.body as? [String: Any] else {
            assertionFailure("parse JS Object failed with error: \(message.body)")
            return
        }
        
        guard let method = jsonObj["method"] as? String else {
            assertionFailure("can not get JS Object method")
            return
        }
        
        guard let params = jsonObj["params"] as? String else {
            assertionFailure("can not get JS Object params")
            return
        }
        
        DocsLogger.driveInfo("parse JS Messange: method - \(method), params - \(params)")
        if HTMLPreviewJSEventName.getInitialData.rawValue == method {
            DocsLogger.driveInfo("getInitialData")
            htmlPreviewViewModel.sendInitialDataToJS()
        } else if HTMLPreviewJSEventName.firstScreenPainted.rawValue == method {
            DocsLogger.driveInfo("firstScreenPainted")
            let canCopy = htmlPreviewViewModel.canCopy.value
            htmlPreviewViewModel.updatePermission(canCopy: canCopy)
            bizVCDelegate?.openSuccess(type: openType)
        } else if HTMLPreviewJSEventName.copyWithoutPermission.rawValue == method {
            DocsLogger.driveInfo("copyWithoutPermission")
        } else if HTMLPreviewJSEventName.currentTabChanged.rawValue == method {
            DocsLogger.driveInfo("currentTabChanged")
        } else if HTMLPreviewJSEventName.requestCachedData.rawValue == method {
            DocsLogger.driveInfo("requestCachedData")
            htmlPreviewViewModel.getCachedTabData(subId: params)
        } else {
            assertionFailure("unknown js object method")
            DocsLogger.warning("unknown js object method")
        }
        
    }
}

extension DriveHtmlPreviewViewController: DriveDynamicPermissionProtocol {
    func update(permission: DrivePermissionInfo) {
        htmlPreviewViewModel.updatePermission(canCopy: permission.canCopy)
    }
}

extension DriveHtmlPreviewViewController: DriveBizeControllerProtocol {
    var openType: DriveOpenType {
        return .htmlView
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
