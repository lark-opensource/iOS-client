//
//  WebMetaLegacyExtensionItem.swift
//  WebBrowser
//
//  Created by 字节跳动 on 2022/3/7.
//

import Foundation
import LarkCompatible
import LarkExtensions
import LKCommonsLogging
import ECOProbe

private let logger = Logger.webBrowserLog(WebMetaLegacyExtensionItem.self, category: "WebMetaLegacyExtensionItem")
final public class WebMetaLegacyExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "WebMetaLegacy"
    public lazy var browserDelegate: WebBrowserProtocol? = WebMetaLegacyWebBrowserDelegate()
    public init() {}
}
final public class WebMetaLegacyWebBrowserDelegate: WebBrowserProtocol {
    public func browser(_ browser: WebBrowser, didURLChanged url: URL?) {
        guard let url = url else { return }
        let queryDict = url.lf.queryDictionary
        guard let setBounces = queryDict["lark_set_bounces"]?.lowercased() else { return }
        var setBouncesValue: Bool?
        switch setBounces {
        case "true":
            setBouncesValue = true
        case "false":
            setBouncesValue = false
        default:
            setBouncesValue = nil
        }
        guard let setBouncesValue = setBouncesValue else { return }
        browser.webview.scrollView.bounces = setBouncesValue
        
        if WebMetaNavigationBarExtensionItem.isURLCustomQueryMonitorEnabled() {
            let appId = browser.configuration.appId ?? browser.currrentWebpageAppID()
            OPMonitor("openplatform_web_container_URLCustomQuery")
                .addCategoryValue("name", "lark_set_bounces")
                .addCategoryValue("content", setBounces)
                .addCategoryValue("url", url.safeURLString)
                .addCategoryValue("appId", appId)
                .setPlatform([.tea, .slardar])
                .tracing(browser.getTrace())
                .flush()
        }
    }
}
