//
//  MailWebViewMonitor.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/3/20.
//

import Foundation
import WebKit
import Homeric
import LarkStorage

private let kLogMonitorName = "lkMailStatLogMonitor"
private let kLogInitTimeName = "lkMailStatLogInitTime"

class MailWebViewMonitor: NSObject {
    private lazy var queue: DispatchQueue = {
        return DispatchQueue(label: "com.lark.mailsdk.webviewmonitor")
    }()
}

protocol MailWebmonitorable {
    var mailRequestTimestamp: TimeInterval? { get set }
}

extension MailWebViewMonitor {
    func setupMonitorForWKWebView(webview: WKWebView) {
        // 判断有没有注册过
        var hasInject = false
        let empty = emptyScript()
        for item in webview.configuration.userContentController.userScripts where item.source == empty {
            hasInject = true
            break
        }
        if !hasInject {
            // flag
            let emptyScr = WKUserScript(source: empty, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            webview.configuration.userContentController.addUserScript(emptyScr)
            // monitor script
            let monitorScr = WKUserScript(source: monitorScript(), injectionTime: .atDocumentStart, forMainFrameOnly: false)
            webview.configuration.userContentController.addUserScript(monitorScr)

            func addHandler(action: String) {
                webview.configuration.userContentController.add(self, name: action)
            }

            addHandler(action: kLogMonitorName)
            addHandler(action: kLogInitTimeName)
        }
    }
}

// MARK: handler
extension MailWebViewMonitor {
    func handleStatisticsAction(_ params: Any) {
        guard let dic = params as? [String: Any] else {
            return
        }

        var eventValues: [String: Any] = [:]
        if let ev = dic["event"] as? [String: Any] {
            if let category = ev["category"] as? String {
                eventValues["category"] = category
            }
            if let title = ev["title"] as? String {
                eventValues["title"] = title
            }
            if let msg = ev["msg"] as? String {
                eventValues["msg"] = msg
            }
        }

        queue.async {
            // parse
//            mailAssertionFailure("\(Homeric.MAIL_WEBVIEW_JAVASCRIPT_ERROR) msg: \(eventValues["msg"]  ?? "Null")")
            MailTracker.log(event: Homeric.MAIL_WEBVIEW_JAVASCRIPT_ERROR, params: eventValues)
        }
    }

    func handleInitTime(message: WKScriptMessage) {
        if var monitorable = message.webView as? MailWebmonitorable, let requestTime = monitorable.mailRequestTimestamp {
            let duration = Date().timeIntervalSince1970 * 1000 - requestTime
            monitorable.mailRequestTimestamp = nil
            queue.async {
                MailTracker.log(event: Homeric.MAIL_MESSAGE_LIST_WEBVIEW_DOM_COST_TIME, params: ["render_time": duration])
            }
        }
    }

    func detectWhiteScreenIfNeed(message: WKScriptMessage) {
        if let webview = message.webView as? MailWebViewDetectable {
            MailWebViewDetector.shared.detect(webview: webview) { (done, res) in
                if res == .domNodeLess {
                    MailTracker.log(event: Homeric.MAIL_MESSAGE_LIST_WEBVIEW_WHITESCREEN, params: [:])
                }
            }
        }
    }
}

// MARK: WKScriptMessageHandler
extension MailWebViewMonitor: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == kLogMonitorName {
            handleStatisticsAction(message.body)
        } else if message.name == kLogInitTimeName {
            handleInitTime(message: message)
            // 检测白屏情况
            detectWhiteScreenIfNeed(message: message)
        }
    }
}

// MARK: script
extension MailWebViewMonitor {
    func emptyScript() -> String {
        return "window.mailiOSEmptyMonitorInjection = {}"
    }

    func monitorScript() -> String {
        let path = I18n.resourceBundle.bundlePath + "/commonJS" + "/performance.js"
        var content = ""
        do {
            content = try String.read(from: AbsPath(path), encoding: .utf8)
        } catch {
            MailLogger.error("\(error)")
        }
        return content
    }
}
