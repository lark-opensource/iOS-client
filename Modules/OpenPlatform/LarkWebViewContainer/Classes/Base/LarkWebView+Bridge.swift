//
//  LarkWebView+Bridge.swift
//  LarkWebViewContainer
//
//  Created by 新竹路车神 on 2020/9/25.
//

import WebKit

/// API Bridge Name
private let scriptMessageHandlerName = "invokeNative"
private let ajaxFetchHookScriptMessageHandlerName = "ajaxFetchHook"
let schemeHandlerHelperHandlerName = "schemeHandlerHelper"
public let consoleMessageHandlerName = "opWebConsoleHandler"

// swiftlint:disable extension_access_modifier
// MARK: - Bridge
extension LarkWebView {
    //  这两个方法仅供Bridge模块调用，其他模块请勿调用
    /// 注册 Bridge 信道
    func registerBridge(scriptMessageHandler: WKScriptMessageHandler) {
        configuration
            .userContentController
            .add(
                scriptMessageHandler,
                name: scriptMessageHandlerName
            )
    }
    
    func registerAjaxFetchHookBridge(scriptMessageHandler: WKScriptMessageHandler) {
        configuration
            .userContentController
            .add(
                scriptMessageHandler,
                name: ajaxFetchHookScriptMessageHandlerName
            )
    }
    
    public func registerConsoleBridge(handler: WKScriptMessageHandler) {
        configuration.userContentController.add(handler, name: consoleMessageHandlerName)
    }

    /// 反注册 Bridge 信道
    func unregisterBridge() {
        configuration
            .userContentController
            .removeScriptMessageHandler(forName: scriptMessageHandlerName)
    }
    
    func unregisterAjaxFetchHookBridge() {
        configuration
            .userContentController
            .removeScriptMessageHandler(forName: ajaxFetchHookScriptMessageHandlerName)
    }
    
    private func unregisterSchemeHandlerHelperBridge() {
        configuration
            .userContentController
            .removeScriptMessageHandler(forName: schemeHandlerHelperHandlerName)
    }
    
    func unregisterConsoleBridge() {
        configuration.userContentController.removeScriptMessageHandler(forName: consoleMessageHandlerName)
    }

    /// 清理Bridge上下文
    func clearBridgeContext() {
        //  避免内存泄漏
        unregisterBridge()
        unregisterAjaxFetchHookBridge()
        unregisterSchemeHandlerHelperBridge()
        unregisterConsoleBridge()
    }
}
// swiftlint:enable extension_access_modifier
