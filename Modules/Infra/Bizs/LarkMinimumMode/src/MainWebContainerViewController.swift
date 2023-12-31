//
//  MainWebContainerViewController.swift
//  LarkMinimumMode
//
//  Created by Supeng on 2021/5/7.
//

import Foundation
import UIKit
import SnapKit
import WebKit
import LarkContainer
import RoundedHUD
import LarkAccountInterface
import RxSwift
import LarkLocalizations
import LarkStorage

// 基本模式下，web页面无法做国际化，此页面默认写死中文文案
final class MainWebContainerViewController: UIViewController, WKScriptMessageHandlerProxyDelegate, WKNavigationDelegate, UserResolverWrapper {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return true
    }

    @ScopedInjectedLazy private var passportService: PassportService?
    @ScopedInjectedLazy private var minimumService: MinimumModeInterface?
    @ScopedInjectedLazy private var minimumAPI: MinimumModeAPI?

    private let disposeBag: DisposeBag = DisposeBag()
    let userResolver: UserResolver

    private let LKWebViewBridgeInjectedPath = "window.LKWebViewBridgeInjected"

    private let jsHandlerProxy: WKScriptMessageHandlerProxy = WKScriptMessageHandlerProxy()

    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: self.configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        return webView
    }()

    private lazy var defaultWKPreference: WKPreferences = {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.setValue(false, forKey: "allowFileAccessFromFileURLs")
        return preferences
    }()

    private lazy var configuration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true
        // websiteDataStore需要在processPool前初始化，否则cookie不会sync成功
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        configuration.processPool = WKProcessPool()
        configuration.setValue(false, forKey: "allowUniversalAccessFromFileURLs")
        configuration.preferences = self.defaultWKPreference
        let userContent = WKUserContentController()
        configuration.userContentController = userContent
        return configuration
    }()

    private let urlStr: String
    private var navigationBarHidden: Bool
    init(userResolver: UserResolver, urlStr: String, navigationBarHidden: Bool) {
        self.userResolver = userResolver
        self.urlStr = urlStr
        self.navigationBarHidden = navigationBarHidden
        super.init(nibName: nil, bundle: nil)
        jsHandlerProxy.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func syncHttpCookie() {
        // sync cookie from HTTPCookieStorage to websiteDataStore
        let cookies = HTTPCookieStorage.shared.cookies
        if let cookies = cookies {
            for cookie in cookies {
                self.configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
            }
        }
    }

    private func injectJSBridge() {
        self.configuration.userContentController.removeScriptMessageHandler(forName: "invoke")
        self.configuration.userContentController.add(jsHandlerProxy, name: "invoke")

        self.webView.evaluateJavaScript("\(LKWebViewBridgeInjectedPath) = true;", completionHandler: nil)
        self.webView.evaluateJavaScript(
            "window.dispatchEvent(new CustomEvent('WebViewJavascriptBridgeReady', {}));",
            completionHandler: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(navigationBarHidden, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(navigationBarHidden, animated: false)
        view.backgroundColor = .white
        self.view.addSubview(webView)
        webView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        guard let url = URL(string: self.urlStr) else {
            return
        }
        // 发现简单模式退出登陆，再登陆后，cookie没有被立刻存储到HTTPCookieStorage.shared.cookies，这里需要做一下延迟
        // 正常模式切换到简单模式没有问题
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.syncHttpCookie()
            self.webView.load(URLRequest(url: url))
        })
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.injectJSBridge()
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(WKNavigationActionPolicy.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(WKNavigationResponsePolicy.allow)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "invoke", let body = message.body as? [String: Any] {
            if funcMatch(body, targetFunc: "biz.basicmode.logout") {
                self.reLogin()
            } else if funcMatch(body, targetFunc: "biz.basicmode.closeBasicMode") {
                self.changeToNomalMode()
            } else if funcMatch(body, targetFunc: "biz.basicmode.openWebview") {
                if let urlStr: String = self.getArgs(body, target: "url") {
                    self.openWebView(url: urlStr)
                }
            }
        }
    }

    private func funcMatch(_ body: [String: Any], targetFunc: String) -> Bool {
        return (body["method"] as? String) ?? "" == targetFunc
    }

    private func getArgs<R>(_ body: [String: Any], target: String) -> R? {
        guard let args = body["args"] as? [String: Any] else {
            return nil
        }
        return args[target] as? R
    }

    private func reLogin() {
        guard let window = self.view.window else {
            return
        }
        let alert = UIAlertController(title: "退出登录将关闭基本功能模式并重启\(LanguageManager.bundleDisplayName)", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "退出登录", style: .default, handler: { (_) in
            let hud = RoundedHUD.showLoading(on: window, disableUserInteraction: true)
            // 退出登陆，要先切换回正常模式
            self.minimumAPI?.putDeviceMinimumMode(false)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    KVPublic.Core.minimumMode.setValue(false)
                    self?.passportService?.logout(
                        conf: .default,
                        onInterrupt: {
                            hud.remove()
                            RoundedHUD.showFailure(with: "退出登录失败，请重试", on: window)
                        }, onError: { (_) in
                            hud.remove()
                            RoundedHUD.showFailure(with: "退出登录失败，请重试", on: window)
                        }, onSuccess: { _, _ in
                            hud.remove()
                            DispatchQueue.main.async {
                                exit(0)
                            }
                        }, onSwitch: { _ in })
                }, onError: { _ in
                    hud.remove()
                    RoundedHUD.showFailure(with: "退出登录失败，请重试", on: window)
                }).disposed(by: self.disposeBag)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    private func changeToNomalMode() {
        guard let window = self.view.window else {
            return
        }
        let alert = UIAlertController(title: "关闭基本功能模式需重启\(LanguageManager.bundleDisplayName)", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "关闭", style: .default, handler: { (_) in
            let hud = RoundedHUD.showLoading(on: window, disableUserInteraction: true)
            self.minimumService?.putDeviceMinimumMode(false) { (_) in
                hud.remove()
                RoundedHUD.showFailure(with: "切换失败，请重试", on: window)
            }
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    private func openWebView(url: String) {
        let vc = MainWebContainerViewController(userResolver: userResolver, urlStr: url, navigationBarHidden: false)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

protocol WKScriptMessageHandlerProxyDelegate: AnyObject {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage)
}

private final class WKScriptMessageHandlerProxy: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandlerProxyDelegate?
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.delegate?.userContentController(userContentController, didReceive: message)
    }
}
