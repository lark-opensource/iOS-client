//
//  SupportThirdPartFollowBrowserView.swift
//  SpaceKit
//
//  Created by 吴珂 on 2020/4/10.
//  


import SKFoundation
import WebKit
import SpaceInterface
import SKCommon
import SKUIKit
import SpaceInterface
import SKInfra

class SupportThirdPartyFollowBrowserView: UIView {
    var webView: WKWebView
    var service: SupportThirdPartyFollowService?
    weak var spaceFollowAPIDelegate: SpaceFollowAPIDelegate?
    
    private var originalUrl: String?
    
    private var loadingView = DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)
    
    private lazy var failTipsView: EmptyListPlaceholderView = {
        let view = EmptyListPlaceholderView(frame: .zero)
        view.backgroundColor = UIColor.ud.N00
        view.isHidden = true
        view.delegate = self
        addSubview(view)
        view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return view
    }()

    
    override init(frame: CGRect) {
        webView = WKWebView(frame: frame, configuration: WKWebViewConfiguration())
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        service = SupportThirdPartyFollowService(browserView: self)
        webView.configuration.userContentController.add(LeakAvoider(self), name: "invoke")
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.customUserAgent = UserAgent.defaultWebViewUA
        addSubview(webView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        webView.frame = self.bounds
    }
    
    func injectUserscript(_ jsString: String) {
        let userScript = WKUserScript(source: jsString, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(userScript)
    }
    
//    func addMessageHandler(_ handler: WKScriptMessageHandler, name: String) {
//        webView.configuration.userContentController.add(LeakAvoider(self), name: name)
//    }
    
    func openUrl(_ urlString: String) {
        DocsLogger.vcfInfo("open url in thirdparty browserview ")
        guard let url = URL(string: urlString) else {
            return
        }
        originalUrl = urlString
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func reload() {
        if webView.url != nil {
            DocsLogger.vcfInfo("reload normal")
            webView.reload()
            return
        }
        
        guard let url = originalUrl else {
            return
        }
        DocsLogger.vcfInfo("reload by failed")
        openUrl(url)
    }
    
    deinit {
        webView.configuration.userContentController.removeAllUserScripts()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "invoke")
    }
}

extension SupportThirdPartyFollowBrowserView: ErrorPageProtocol {
    func didClickReloadButton() {
        clickReload()
    }
}

extension SupportThirdPartyFollowBrowserView: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "invoke", let body = message.body as? [String: Any],
            let method = body["method"] as? String,
            let agrs = body["args"] as? [String: Any] else {
                spaceAssertionFailure()
                DocsLogger.severe("cannot handle js request", extraInfo: ["message": message.description], error: nil, component: nil)
                return
        }
        service?.handle(params: agrs, serviceName: method)
    }
}

extension SupportThirdPartyFollowBrowserView: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DocsLogger.vcfInfo("didStartProvisionalNavigation")
        showLoadingIndicator()
    }

    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let urlString = navigationAction.request.url?.absoluteString {
            if urlString.contains("#") {//处理sheet tab点击
                let tempTargetUrlHeader = urlString.components(separatedBy: "#").first
                let tempOriginalUrlHeader = webView.url?.absoluteString.components(separatedBy: "#").first
                if let targetUrlHeader = tempTargetUrlHeader, let originalUrlHeader = tempOriginalUrlHeader {
                    if targetUrlHeader.elementsEqual(originalUrlHeader) {
                        decisionHandler(.allow)
                        return
                    }
                }
            }
            decisionHandler(.cancel)
            DocsLogger.vcfInfo("click googlelink url")
            spaceFollowAPIDelegate?.follow(nil, onOperate: .vcOperation(value: .openUrl(url: urlString)))
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DocsLogger.vcfInfo("didFinish load")
        hideLoadingIndicator()
        spaceFollowAPIDelegate?.followDidRenderFinish(nil)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DocsLogger.vcfInfo("did fail provisional navigation \(error.localizedDescription)")
        showFailTipsView(error: error)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DocsLogger.vcfInfo("did fail \(error.localizedDescription)")
        showFailTipsView(error: error)
    }
    
    func showFailTipsView(error: Error) {
        hideAll()
        failTipsView.isHidden = false
        let status = LoadStatus.fail(error: error)
        let msg = status.errorMsg
        failTipsView.config(error: ErrorInfoStruct(type: .openFileWebviewFail, title: msg, domainAndCode: nil))
        bringSubviewToFront(failTipsView)
    }
    
    @objc
    func clickReload() {
        hideAll()
        reload()
    }
    
    func showLoadingIndicator() {
        hideAll()
        if let loadingView = self.loadingView {
            self.addSubview(loadingView.displayContent)
            loadingView.displayContent.frame = self.window?.bounds ?? CGRect.zero
            loadingView.displayContent.isHidden = false
            loadingView.startAnimation()
        }
    }

    func hideLoadingIndicator(completion: @escaping () -> Void = { }) {
        if let loadingView = self.loadingView {
            loadingView.stopAnimation()
            loadingView.displayContent.removeFromSuperview()
        }
        completion()
    }
    
    func hideAll() {
        failTipsView.isHidden = true
        hideLoadingIndicator()
    }

}

extension SupportThirdPartyFollowBrowserView: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        DocsLogger.vcfInfo("request open new window:\(navigationAction)")
        if let urlString = navigationAction.request.url?.absoluteString, !urlString.isEmpty {
            DocsLogger.vcfInfo("click googlelink url")
            spaceFollowAPIDelegate?.follow(nil, onOperate: .vcOperation(value: .openUrl(url: urlString)))
        }
        
        return nil
    }
}

extension SupportThirdPartyFollowBrowserView {
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        var paramsStr: String?
        if let params = params {
            let paramsStrBeforeFix = params.ext.toString()
            paramsStr = JSServiceUtil.fixUnicodeCtrlCharacters(paramsStrBeforeFix ?? "", function: function.rawValue)
        }

        let script = function.rawValue + "(\(paramsStr ?? ""))"
        callJsString(script, completionHandler: completion)
    }
    
    private func callJsString(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        let runJSBlock = { [weak self] in
            if let self = self {
                self.webView.evaluateJavaScript(javaScriptString) { (obj, error) in
                    completionHandler?(obj, error)
                    guard let error = error else { return }
                    DocsLogger.error("evaluateJavaScript for \(self) fail", error: error, component: nil)
                }
            }
        }
        
        if Thread.isMainThread {
            runJSBlock()
        } else {
            DispatchQueue.main.async {
                runJSBlock()
            }
        }
    }
}
