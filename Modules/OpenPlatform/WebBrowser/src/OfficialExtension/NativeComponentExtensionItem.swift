//
//  NativeComponentExtensionItem.swift
//  WebBrowser
//
//  Created by yi on 2021/9/13.
//
// 同层能力

import LKCommonsLogging
import WebKit
import LarkWebviewNativeComponent
import LarkWebViewContainer

private let logger = Logger.webBrowserLog(NativeComponentExtensionItem.self, category: "LarkWebviewNativeComponentExtensionItem")

final public class NativeComponentExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "NativeComponent"
    public var lifecycleDelegate: WebBrowserLifeCycleProtocol? = NativeComponentWebBrowserLifeCycle()

    public var navigationDelegate: WebBrowserNavigationProtocol? = NativeComponentWebBrowserNavigation()

    public init() {
    }

}
final public class NativeComponentWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    public func viewDidLoad(browser: WebBrowser) {
        logger.info("viewDidLoad")
        // 开启同层能力
        LarkNativeComponent.enableNativeComponent(webView: browser.webview, components: [])
    }
}
final public class NativeComponentWebBrowserNavigation: WebBrowserNavigationProtocol {
    public func browser(_ browser: WebBrowser, didStartProvisionalNavigation navigation: WKNavigation!) {
        logger.info("didStartProvisionalNavigation")
        // 重新加载网页时清空同层实例
        LarkNativeComponent.clearNativeComponents(webView: browser.webview)
    }
}
