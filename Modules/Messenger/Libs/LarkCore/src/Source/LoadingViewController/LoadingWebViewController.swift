//
//  LKSecLinkWebviewViewController.swift
//  LarkCore
//
//  Created by 赵冬 on 2019/12/19.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import UniverseDesignToast

import WebKit

public final class LoadWebFailPlaceholderView: LoadFailPlaceholderView {
    override public var image: UIImage? {
        return Resources.web_failed
    }
}

open class LoadingWebViewController: BaseUIViewController, WKNavigationDelegate {

    weak public var loadingNavigationDelegate: LoadingWKNavigationDelegate?

    fileprivate var disposeBag = DisposeBag()

    private var showLoadingFirstLoad: Bool

    // 成功失败占位图
    lazy var failView: UIView = {
        let view = LoadWebFailPlaceholderView(frame: CGRect.zero)
        view.backgroundColor = UIColor.ud.N00

        let tap = UITapGestureRecognizer()
        tap.rx.event.asDriver().drive(onNext: { [weak self] _ in self?.failViewTap() })
            .disposed(by: disposeBag)
        view.addGestureRecognizer(tap)

        return view
    }()

    public func showFailView() {
        self.view.addSubview(failView)
        failView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    public func removeFailView() {
        failView.removeFromSuperview()
    }

    open func failViewTap() {
    }

    public init(showLoadingFirstLoad: Bool = true) {
        self.showLoadingFirstLoad = showLoadingFirstLoad
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func showLoadingHUD() {
        UDToast.showLoading(on: view)
    }

    private func cancelShowLoadingHUD() {
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(self.showLoadingHUD),
            object: nil
        )
    }

    //decide
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        if self.loadingNavigationDelegate?.loadingWebview?(webView,
                                          decidePolicyFor: navigationAction,
                                          decisionHandler: decisionHandler) == nil {
            decisionHandler(WKNavigationActionPolicy.allow)
        }
    }

    //decide action
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        if self.loadingNavigationDelegate?.loadingWebview?(webView,
                                          decidePolicyResFor: navigationResponse,
                                          decisionHandler: decisionHandler) == nil {
            decisionHandler(WKNavigationResponsePolicy.allow)
        }
    }

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        self.cancelShowLoadingHUD()
        UDToast.removeToast(on: view)
        self.loadingNavigationDelegate?.loadingWebview?(webView, didCommit: navigation)
    }

    //start
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if !showLoadingFirstLoad {
            self.perform(#selector(self.showLoadingHUD), with: nil, afterDelay: 0.5)
        } else {
            showLoadingFirstLoad = false
        }
        self.loadingNavigationDelegate?.loadingWebview?(webView, didStartProvisionalNavigation: navigation)
    }

    //start failed
    public func webView(_ webView: WKWebView,
                        didFailProvisionalNavigation navigation: WKNavigation!,
                        withError error: Error) {
        self.cancelShowLoadingHUD()
        UDToast.removeToast(on: view)
        loadingNavigationDelegate?.loadingWebview?(webView, didFailProvisionalNavigation: navigation, withError: error)
    }

    //finish
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.loadingNavigationDelegate?.loadingWebview?(webView, didFinish: navigation)
    }

    //nav failed
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.cancelShowLoadingHUD()
        UDToast.removeToast(on: view)
        loadingNavigationDelegate?.loadingWebview?(webView, didFail: navigation, withError: error)
    }

    //recieve server redirect
    public func webView(_ webView: WKWebView,
                        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        loadingNavigationDelegate?.loadingWebview?(webView, didReceiveServerRedirectForProvisionalNavigation: navigation)
    }

    //web terminate
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        loadingNavigationDelegate?.loadingWebviewWebviewWebContentProcessDidTerminate?(webView)
    }

    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        if let delegate = loadingNavigationDelegate,
           delegate.responds(to: #selector(delegate.loadingWebview(_:didReceive:completionHandler:))) {
            delegate.loadingWebview?(webView, didReceive: challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
