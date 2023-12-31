//
//  WebConsoleHelper.swift
//  LarkWebViewContainer
//
//  Created by ByteDance on 2023/5/31.
//

import Foundation
import WebKit
import LarkWebViewContainer
import WebBrowser
import LKCommonsLogging
import LarkSetting

private struct Tag {
    static let logTag = "[vConsole]"
    static let consoleLogTag = "LarkWebContainer: "
}

final class WebConsoleHelper: NSObject, WKScriptMessageHandler {
    static let logger = Logger.lkwlog(WebConsoleHelper.self, category: "WebConsoleHelper")
    
    static func devToolConsoleOptEnabled() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.devtool.console_log_optimize"))// user:global
    }
    
    static func sendLogToVConsole(level: LogLevel, _ msg: String, webview: LarkWebView) {
        guard Self.logToVConsoleEnabled(url: webview.url) else {
            return
        }
        if msg.contains(Tag.consoleLogTag) {
            return
        }
        let formatterStr = msg.vConsoleLogFormatter()
        var logJsStr: String?
        switch level {
        case .warn:
            logJsStr = Self.warnLogJsStr(formatterStr)
        case .error:
            logJsStr = Self.errorLogJsStr(formatterStr)
        default:
            break
        }
        if let logJsStr = logJsStr {
            webview.evaluateJavaScript(logJsStr) { _, error in
                if let error = error {
                    Self.logger.error("\(Tag.logTag) send log to vconsole failed.", error: error)
                }
            }
        }
    }
    
    static func logToVConsoleEnabled(url: URL?) -> Bool {
        guard Self.devToolConsoleOptEnabled() else {
            return false
        }
        guard let url = url else {
            return false
        }
        return Self.betaAppDebugToolEnabled() || Self.storeAppInspectorEnabled(url: url)
    }
    
    private static func betaAppDebugToolEnabled() -> Bool {
#if DEBUG || BETA || ALPHA
        return UserDefaults.standard.bool(forKey: WebBrowserDebugItem.vConsoleDebugKey)
#else
        return false
#endif
    }
    
    private static func storeAppInspectorEnabled(url: URL) -> Bool {
        guard let host = url.host else {
            return false
        }
        guard WebInspectorValidator.checkMark() else {
            return false
        }
        guard WebInspectorValidator.checkWebHost(for: host) else {
            return false
        }
        return true
    }
    
    private static func warnLogJsStr(_ string: String) -> String {
        return "javascript:(function containerWarnLog(){if(typeof vConsole !== 'undefined' || typeof __VCONSOLE_INSTANCE !== 'undefined'){console.warn('\(string)');}else{setTimeout(()=>{console.warn('\(string)');},1000)}})()"
    }

    private static func errorLogJsStr(_ string: String) -> String {
        return "javascript:(function containerErrorLog(){if(typeof vConsole !== 'undefined' || typeof __VCONSOLE_INSTANCE !== 'undefined'){console.error('\(string)');}else{setTimeout(()=>{console.error('\(string)');},1000)}})()"
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == consoleMessageHandlerName else {
            return
        }
        sendLog(message: message)
    }
    
    private func sendLog(message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            return
        }
        guard let method = body["method"] as? String, method == "console" else {
            Self.logger.info("\(Tag.logTag) method parameter not equal to console")
            return
        }
        guard let level = body["level"] as? String else {
            return
        }
        guard let webview = message.webView as? LarkWebView else {
            return
        }
        let content = body["content"] as? String ?? ""
        if level == "warn" {
            sendLog(level: .warn, content, from: webview)
        } else if level == "error" {
            sendLog(level: .error, content, from: webview)
        }
    }
    
    private func sendLog(level: LogLevel, _ msg: String, from webview: LarkWebView) {
        Self.logger.lkwlog(level: level, "\(Tag.logTag) \(msg), url: \(webview.url?.safeURLString ?? "")", traceId: webview.opTraceId())
    }
}

fileprivate extension String {
    func vConsoleLogFormatter() -> String {
        let nonQuotStr = replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "'", with: "")
        return Tag.consoleLogTag + nonQuotStr
    }
}
