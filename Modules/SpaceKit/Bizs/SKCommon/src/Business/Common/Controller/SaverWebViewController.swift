//
//  SaverWebViewController.swift
//  SKCommon
//
//  Created by litao_dev on 2020/11/26.
//  

import UIKit
import WebKit
import EENavigator
import SKFoundation
import RxSwift
import SKUIKit
import SpaceInterface
import SKInfra

final public class SaverWebViewController: BaseViewController {
    var url: URL
    var webview: WKWebView
    var isFinishLoad: Bool = false
    var loadingView: DocsLoadingViewProtocol?
    private var titleObserve: NSKeyValueObservation?

    public init(url: URL) {
        self.url = url
        let config = WKWebViewConfiguration()
        let dataStore = WKWebsiteDataStore.default()
        config.websiteDataStore = dataStore
        webview = WKWebView(frame: SKDisplay.activeWindowBounds, configuration: config)
        super.init(nibName: nil, bundle: nil)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        var userAgent = UserAgent.defaultWebViewUA
        webview.customUserAgent = userAgent
        webview.navigationDelegate = self
        webview.uiDelegate = self

        view.addSubview(webview)
        webview.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
        }

        var request = URLRequest(url: url)
        setLoadingViewShow(true)
        webview.load(request)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.titleObserve = webview.observe(\WKWebView.title, options: .new) { [weak self] (_, value) in
            guard let title = value.newValue else { return }
            self?.title = title
        }
    }
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.titleObserve?.invalidate()
    }

}


// MARK: - webviewdelegate

extension SaverWebViewController: WKNavigationDelegate, WKUIDelegate {

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        var needDispatchOut = false

        if let suiteMainDomain = DomainConfig.ka.suiteMainDomain, !suiteMainDomain.isEmpty,
           let host = url.host, !host.isEmpty,
           host.contains(suiteMainDomain) {
            needDispatchOut = true
        }

        if needDispatchOut == false, isFinishLoad {
            needDispatchOut = true
        }

        guard needDispatchOut else {
            decisionHandler(.allow)
            return
        }
        let (vc, isSupport) = SKRouter.shared.open(with: url)
        if let newVC = vc {
            if isSupport || newVC is SaverWebViewController {
                navigationController?.pushViewController(newVC, animated: true)
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let response = navigationResponse.response as? HTTPURLResponse,
            let url = navigationResponse.response.url else {
                decisionHandler(.cancel)
                return
        }
        isFinishLoad = true
        decisionHandler(.allow)
        setLoadingViewShow(false)
    }

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if !(navigationAction.targetFrame?.isMainFrame ?? false) {
            webView.load(navigationAction.request)
        }
        return nil
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isFinishLoad = true


    }
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isFinishLoad = true
    }

    private func setLoadingViewShow(_ show: Bool) {
        if loadingView == nil, let newLoadingView = DocsContainer.shared.resolve(DocsLoadingViewProtocol.self) {
            if let loadingView1 = newLoadingView as? UIView {
                view.insertSubview(loadingView1, belowSubview: navigationBar)
                loadingView1.snp.makeConstraints { (make) in
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalTo(navigationBar.snp.bottom)
                }
            }
            loadingView = newLoadingView
        }
        if show {
            loadingView?.startAnimation()
        } else {
            if let loadingView1 = loadingView as? UIView {
                UIView.animate(withDuration: 1.5, animations: {
                    loadingView1.alpha = 0
                }, completion: { (_) in
                    self.loadingView?.stopAnimation()
                })
            }
        }
    }
}
