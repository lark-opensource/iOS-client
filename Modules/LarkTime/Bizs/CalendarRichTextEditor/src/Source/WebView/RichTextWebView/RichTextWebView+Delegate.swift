//
//  DocsWebView.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/10.
//

import WebKit

protocol DocsWebViewResponderDelegate: AnyObject {
    /// 当请求canBecomeFirstResponder时调用(系统并不会询问此属性，故该逻辑可用性未知)
    func docsWebViewShouldBecomeFirstResponder(_ webView: RichTextWebView) -> Bool
    /// 当请求canResignFirstResponder时调用(系统并不会询问此属性，故该逻辑可用性未知)
    func docsWebViewShouldResignFirstResponder(_ webView: RichTextWebView) -> Bool

    func docsWebViewWillBecomeFirstResponder(_ webView: RichTextWebView)
    func docsWebViewDidBecomeFirstResponder(_ webView: RichTextWebView)
    func docsWebViewWillResignFirstResponder(_ webView: RichTextWebView)
    func docsWebViewDidResignFirstResponder(_ webView: RichTextWebView)

    // true: 禁止becomeFirstResponder  false: 不拦截
    func disableBecomeFirstResponder(_ webView: RichTextWebView) -> Bool
}

extension DocsWebViewResponderDelegate {
    func docsWebViewShouldBecomeFirstResponder(_ webView: RichTextWebView) -> Bool { return true }
    func docsWebViewShouldResignFirstResponder(_ webView: RichTextWebView) -> Bool { return true }
    func docsWebViewWillBecomeFirstResponder(_ webView: RichTextWebView) { }
    func docsWebViewDidBecomeFirstResponder(_ webView: RichTextWebView) { }
    func docsWebViewWillResignFirstResponder(_ webView: RichTextWebView) { }
    func docsWebViewDidResignFirstResponder(_ webView: RichTextWebView) { }
    func disableBecomeFirstResponder(_ webView: RichTextWebView) -> Bool { return false }
}
