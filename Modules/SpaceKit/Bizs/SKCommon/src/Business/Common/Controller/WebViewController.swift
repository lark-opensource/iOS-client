//  Created by Songwen Ding on 2017/11/23.

/*!
 WebViewController负责通用的Web容器，前进、后退、预览等
 */

import UIKit
import WebKit
import SKUIKit
import LarkUIKit
import SKResource
import SKFoundation
import RxSwift
import SKInfra

final public class WebViewController: BaseViewController {
    //swiftlint:disable weak_delegate
    private let navigationDelegate = WKNavigationor()
    //swiftlint:enable weak_delegate
    public var urlHandler: ((URL?) -> WKNavigationActionPolicy)? {
        didSet {
            navigationDelegate.urlHandler = urlHandler
        }
    }
    public var titleHandler: ((String?) -> Void)?

    public var header: [String: String]?
    public private(set) var url: URL!

    public lazy var webView: WKWebView = {
        let webViewConfig = WKWebViewConfiguration()
        var vConsoleEnable = false
        #if BETA || ALPHA || DEBUG
        vConsoleEnable = DocsDebugConstant.isVconsoleEnable
        #endif
        let web = DocsWebViewV2(frame: .zero, configuration: webViewConfig, vConsoleEnable: vConsoleEnable)
        return web
    }()

    private lazy var webProgressView: WebViewProgressView = {
       let pv = WebViewProgressView()
        pv.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 2)
        pv.progressBarColor = UIColor.ud.colorfulBlue.ud.lighter(by: 30)
        pv.autoresizingMask = .flexibleWidth
        return pv
    }()

    private let disposeBag = DisposeBag()

    private var titleObserve: NSKeyValueObservation?

    public required init() {
        fatalError("not supported")
    }

    public init(_ url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: = lifecyle overrides
extension WebViewController {
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.webView)
        self.webView.allowsBackForwardNavigationGestures = true
        self.webView.gestureRecognizers?.forEach({[weak self] (gesture) in
            self?.navigationController?.interactivePopGestureRecognizer?.require(toFail: gesture)
        })
        self.webView.snp.makeConstraints { (make) in
            make.top.equalTo(self.navigationBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        webView.addSubview(webProgressView)

        webView.rx.observe(Double.self, "estimatedProgress").subscribe(onNext: { [weak self] (value) in
            if let progress = value {
                self?.webProgressView.setProgress(progress, animated: true)
            }
        }).disposed(by: disposeBag)

        self.webView.customUserAgent = getDocsUserAgent()
        self.webView.uiDelegate = self

        if url.scheme == nil, let u = URL(string: "http://" + url.absoluteString) { url = u }
        navigationDelegate.rawUrl = url
        navigationDelegate.webProgressView = webProgressView
        self.webView.navigationDelegate = navigationDelegate

        // loadrequest
        var req = URLRequest(url: url)
        if let header = header {
            for (key, value) in header {
                if key.lowercased() != "cookie" { //不能在header设置，会导致cookie设置到非domain下。https://bytedance.feishu.cn/docs/doccnOL6otqYrqY5uXQuwuZRzVh#
                    req.setValue(value, forHTTPHeaderField: key)
                }
            }
        }
        
        webView.load(req)
    }

    private func getDocsUserAgent() -> String {
        var userAgent = UserAgent.defaultWebViewUA
        let language = (Locale.preferredLanguages.first ?? Locale.current.identifier).hasPrefix("zh") ? "zh" : "en"
        userAgent +=  " [\(language)] Bytedance"
        userAgent += " \("DocsSDK")/\(SpaceKit.version)"
        return userAgent
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.titleObserve = (self.webView as WKWebView).observe(\WKWebView.title, options: .new) { [weak self] (_, value) in
            guard let title = value.newValue else { return }
            self?.title = title
            self?.titleHandler?(title)
        }
    }
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.titleObserve?.invalidate()
    }
}

extension WebViewController: WKUIDelegate {
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame?.isMainFrame == true else {
            //打开appstore的链接. 这是一个取巧的办法，如果匹配是appstore链接就直接打开，后续整个webviewController 需要优化，兼容更多的情况
            let p = ".+apple.com/[a-zA-Z]+/app/id.+"
            if let url = navigationAction.request.url, NSPredicate(format: "SELF MATCHES %@", p).evaluate(with: url.absoluteString) {
                UIApplication.shared.open(url)
            } else {
                self.webView.load(navigationAction.request)
            }
            return nil
        }
        return nil
    }
}

// MARK: - Actions
extension WebViewController {
    override public func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent != nil { return }
        if self.webView.isLoading { self.webView.stopLoading() }
    }
    @objc
    override public func backBarButtonItemAction() {
        guard self.webView.canGoBack == false else {
            self.webView.goBack()
            return
        }
        super.backBarButtonItemAction()
    }
}

private class WKNavigationor: NSObject, WKNavigationDelegate {
    var urlHandler: ((URL?) -> WKNavigationActionPolicy)?
    var rawUrl: URL!
    var webProgressView: WebViewProgressView?

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var policy: WKNavigationActionPolicy = .allow
        if navigationAction.request.url == rawUrl {
            policy = .allow
        } else {
            policy = urlHandler?(navigationAction.request.url) ?? .allow
        }
        decisionHandler(policy)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(error, webView: webView)
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(error, webView: webView)
    }

    private func handleError(_ error: Error, webView: WKWebView) {
        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
            DocsLogger.info("load url, no net, show fail")
            showFailTipsOn(webView)
        }
        webProgressView?.setProgress(0, animated: true)
    }

    private func showFailTipsOn(_ webview: WKWebView) {
        webview.addSubview(failTipsView)
        failTipsView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().labeled("四周对齐")
        }
        failTipsView.config(error: ErrorInfoStruct(type: .noNet, title: BundleI18n.SKResource.Doc_Doc_NetException, domainAndCode: nil))
    }

    private lazy var failTipsView: EmptyListPlaceholderView = {
        let view = EmptyListPlaceholderView(frame: .zero)
        view.backgroundColor = UIColor.ud.N00
        return view
    }()

}
