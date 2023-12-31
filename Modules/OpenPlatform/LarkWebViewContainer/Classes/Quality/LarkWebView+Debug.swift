//
//  LarkWebView+Debug.swift
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/9/7.
//

import Foundation
import WebKit

/// Extension to kill WebContentProcess
extension LarkWebView {
    public func openVConsole() {
        assertionFailure("由于安全合规的「星云专项」要求下掉跨境访问域名，了解到目前代码只有docs 临时in-house场景用，先临时下了vConsole功能，接入settings基建搞定以及字节cdn完成部署后重新加回来")
    }
    public func closeVConsole() {
        assertionFailure("由于安全合规的「星云专项」要求下掉跨境访问域名，了解到目前代码只有docs 临时in-house场景用，先临时下了vConsole功能，接入settings基建搞定以及字节cdn完成部署后重新加回来")
    }
    /// Kill WebView进程
    @objc
    public func killWebViewProcess() {
        // _killWebContentProcess
        #if BETA || ALPHA || DEBUG
        let funcName = "_killWebContentProcess"
        let selector = NSSelectorFromString(funcName)
        if responds(to: selector) {
            perform(selector)
            logger.info("kill WebView Process!")
        }
        #endif
    }
}
