//
//  MailNewBaseWebView.swift
//  MailSDK
//
//  Created by 马骏骁 2019/6/21 from DocSDK.WebView author guotenghu.
//
// WKWebview
//    |
//    |
// MailNewBaseWebView(滑动选区/自动显示键盘/inputaccessoryview, contentView)
//    |
//    |
// EditorWebView (自定义菜单，富文本编辑器其他逻辑）

import Foundation
import WebKit
import UIKit
import LarkRustHTTP
import LarkWebViewContainer
import LarkOPInterface

protocol MailWebviewJavaScriptDelegate: AnyObject {
    func invoke(webView: WKWebView, params: [String: Any])
}

protocol EditorWebViewResponderDelegate: AnyObject {
    /// 当请求canBecomeFirstResponder时调用(系统并不会询问此属性，故该逻辑可用性未知)
    func editorWebViewShouldBecomeFirstResponder(_ webView: WKWebView) -> Bool
    /// 当e求canResignFirstResponder时调用(系统并不会询问此属性，故该逻辑可用性未知)
    func editorWebViewShouldResignFirstResponder(_ webView: WKWebView) -> Bool

    func editorWebViewWillBecomeFirstResponder(_ webView: WKWebView)
    func editorWebViewDidBecomeFirstResponder(_ webView: WKWebView)
    func editorWebViewWillResignFirstResponder(_ webView: WKWebView)
    func editorWebViewDidResignFirstResponder(_ webView: WKWebView)
}

extension EditorWebViewResponderDelegate {
    func editorWebViewShouldBecomeFirstResponder(_ webView: WKWebView) -> Bool { return true }
    func editorWebViewShouldResignFirstResponder(_ webView: WKWebView) -> Bool { return true }
    func editorWebViewWillBecomeFirstResponder(_ webView: WKWebView) { }
    func editorWebViewDidBecomeFirstResponder(_ webView: WKWebView) { }
    func editorWebViewWillResignFirstResponder(_ webView: WKWebView) { }
    func editorWebViewDidResignFirstResponder(_ webView: WKWebView) { }
}

@objcMembers
class MailNewBaseWebView: LarkWebView, WKScriptMessageHandler, MailWebmonitorable, MailBaseWebViewAble {
    let messageName = "invoke"
    weak var superContainer: UIView?
    var identifier: String?
    var isSaasSig: Bool = false
    private var scriptMessageHandlerNames: Set<String> = []

    var mailRequestTimestamp: TimeInterval?

    private let minitor = MailWebViewMonitor()

    // 响应 js 调用
    func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage) {
        if message.name == messageName {
            guard let params = message.body as? [String: Any] else { return }
            modelProvider?()?.invoke(webView: self, params: params)
        }
    }

    /// 用以防止webview因为提前释放导致的crash
    static let defaultWKProcessPool: WKProcessPool = {
        return WKProcessPool()
    }()

    // 响应 js 调用的provider
    var modelProvider: (() -> MailWebviewJavaScriptDelegate?)?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect, config: LarkWebViewConfig) {
        super.init(frame: frame, config: config)
    }

    override init(frame: CGRect, config: LarkWebViewConfig, parentTrace: OPTrace?, webviewDelegate: LarkWebViewDelegate?) {
        super.init(frame: frame, config: config, parentTrace: parentTrace, webviewDelegate: webviewDelegate)
    }

    init() {
        let contentController = WKUserContentController()
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        let builder = LarkWebViewConfigBuilder()
        builder.setWebViewConfig(config)
        super.init(frame: CGRect.zero, config: builder.build(bizType: LarkWebViewBizType.mail))
    }

    // 注册jsBridge
    func initJSBridge() {
        scriptMessageHandlerNames.insert(messageName)
        self.configuration.userContentController.add(self, name: messageName)
        minitor.setupMonitorForWKWebView(webview: self)
    }

    // 卸载jsBridge
    func deinitJSBridge() {
        scriptMessageHandlerNames.forEach { (messageName) in
            self.configuration.userContentController.removeScriptMessageHandler(forName: messageName)
        }
    }

    // MARK: override
    override func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation? {
        let navi = super.loadHTMLString(string, baseURL: baseURL)

        mailRequestTimestamp = NSDate().timeIntervalSince1970 * 1000

        return navi
    }

    func isCrashBlank() -> Bool {
        guard let wkCompositingView = NSClassFromString("WKCompositingView") else { return false }
        let maxLoop = 6
        var currentLoop = 0

        func findCompositingView(view: UIView) -> Bool {
            guard currentLoop < maxLoop else { return false }
            currentLoop += 1
            if view.subviews.first(where: { $0.isKind(of: wkCompositingView.self) }) != nil {
                return true
            }
            for subView in view.subviews {
                return findCompositingView(view: subView)
            }
            return false
        }
        return !findCompositingView(view: self)
    }
}

// MARK: - registerSchemeForCustomProtocol 私有方法
// 没有调用的地方，先注释
//extension MailNewBaseWebView {
//    private class func browsing_contextController() -> (NSObject.Type)? {
//        guard let str = "YnJvd3NpbmdDb250ZXh0Q29udHJvbGxlcg==".fromBase64() else { return nil }
//        // str: "browsingContextController"
//        guard let obj = MailNewBaseWebView().value(forKey: str) else { return nil }
//        return type(of: obj) as? NSObject.Type
//    }
//
//    private class func perform_browsing_contextController(aSelector: Selector, schemes: Set<String>) -> Bool {
//        guard let obj = browsing_contextController(), obj.responds(to: aSelector), !schemes.isEmpty else {
//            // MailLogger.error("get browsing context controller faild")
//            return false
//        }
//        let result = !schemes.isEmpty
//        schemes.forEach({ (scheme) in
//            obj.perform(aSelector, with: scheme)
//        })
//        return result
//    }
//}
//
//extension MailNewBaseWebView {
//    @discardableResult
//    class func mailRegister(schemes: Set<String>) -> Bool {
//        guard let str = "cmVnaXN0ZXJTY2hlbWVGb3JDdXN0b21Qcm90b2NvbDo=".fromBase64() else {
//            return false
//        }
//        // str: "registerSchemeForCustomProtocol:"
//        let register = NSSelectorFromString(str)
//        return perform_browsing_contextController(aSelector: register, schemes: schemes)
//    }
//
//    @discardableResult
//    class func mailUnregister(schemes: Set<String>) -> Bool {
//        guard let str = "dW5yZWdpc3RlclNjaGVtZUZvckN1c3RvbVByb3RvY29sOg==".fromBase64() else {
//            return false
//        }
//        // str: "unregisterSchemeForCustomProtocol:"
//        let unregister = NSSelectorFromString(str)
//        return perform_browsing_contextController(aSelector: unregister, schemes: schemes)
//    }
//}

extension MailNewBaseWebView: MailWebViewDetectable {}
