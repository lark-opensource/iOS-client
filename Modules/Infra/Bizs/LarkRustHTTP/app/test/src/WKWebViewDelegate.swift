//
//  WKWebViewDelegate.swift
//  LarkRustClientTests
//
//  Created by SolaWing on 2019/1/3.
//  Copyright © 2019年 Bytedance. All rights reserved.
//

#if ENABLE_WKWebView
import Foundation
import WebKit
import RxSwift
@testable import LarkRustClient
@testable import LarkRustHTTP

/// Convert Delegate to Closure
class WKWebViewDelegate: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    enum Notification {
        case start(navigation: WKNavigation)
        case redirect(navigation: WKNavigation)
        case commit(navigation: WKNavigation)
        case finish(navigation: WKNavigation, error: Error?)
        case crash
        case message(WKScriptMessage)
    }
    enum Delegate {
        case request(action: WKNavigationAction, handler: (WKNavigationActionPolicy) -> Void)
        case response(response: WKNavigationResponse, handler: (WKNavigationResponsePolicy) -> Void)
        case challenge(challenge: URLAuthenticationChallenge, handler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) // swiftlint:disable:this line_length
    }
    let onEvent = PublishSubject<(WKWebViewDelegate, Notification)>()
    func notify(_ notification: Notification) {
        debug(reflect(notification)) // track log
        onEvent.onNext((self, notification))
    }
    var onMainFrameStart: Single<WKNavigation> {
        return Single.create { single in
            self.onEvent.subscribe {
                if case let .next(_, .start(navigation)) = $0 {
                    single( SingleEvent.success(navigation) )
                }
            }
        }
    }
    var onMainFrameFinish: Completable {
        return Completable.create { complete in
            self.onEvent.subscribe {
                switch $0 {
                case let .next(_, .finish(navigation, error)) where navigation == self.mainNavigation:
                    if let error = error {
                        complete( .error(error) )
                    } else {
                        complete( .completed )
                    }
                default: break // ignore other event, 也不会发送非next的消息
                }
            }
        }
    }
    var onReceiveMessage: Observable<WKScriptMessage> {
        return onEvent.compactMap {
            if case let .message(jsMessage) = $0.1 { return jsMessage }
            return nil
        }
    }
    /// return true to ignore default handle
    var delegateHandler: ((WKWebViewDelegate, Delegate) -> Bool)?
    func didDelegate(_ action: Delegate) -> Bool {
        debug(reflect(action))
        return delegateHandler?(self, action) ?? false
    }

    var mainNavigation: WKNavigation?
    // MARK: Delegate Method
    // swiftlint:disable:next line_length
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        notify(.message(message))
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if didDelegate(.request(action: navigationAction, handler: decisionHandler)) {
            return
        }
        decisionHandler(.allow)
    }
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if didDelegate(.response(response: navigationResponse, handler: decisionHandler)) {
            return
        }
        decisionHandler(.allow)
    }
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        mainNavigation = navigation
        notify(.start(navigation: navigation))
    }
    public func webView(_ webView: WKWebView,
                        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        notify(.redirect(navigation: navigation))
    }
    // 这两个fail一个在commit前出错调用，一个commit后出错调用. 两个fail，一个finish，哪个调用都代表导航结束
    public func webView(_ webView: WKWebView,
                        didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        notify(.finish(navigation: navigation, error: error))
        mainNavigation = nil
    }
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        notify(.commit(navigation: navigation))
    }
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        notify(.finish(navigation: navigation, error: nil))
        if navigation == mainNavigation { mainNavigation = nil }
    }
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        notify(.finish(navigation: navigation, error: error))
    }
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge,
                        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if didDelegate(.challenge(challenge: challenge, handler: completionHandler)) {
            return
        }
        completionHandler(.performDefaultHandling, nil)
    }
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        notify(.crash)
    }
}
#endif
