//
//  WebViewFlowMonitor.swift
//  LarkPrivacyMonitor
//
//  Created by 汤泽川 on 2023/7/3.
//

import Foundation
import WebKit
import TSPrivacyKit

extension WKWebView {
    
    static let fetchContent = getFileContent(fileName: "fetch_monitor")
    static let navContent = getFileContent(fileName: "nav_monitor")
    
    @objc
    public func setupFetchMonitor() {
        let script = WKUserScript(source: WKWebView.fetchContent, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        self.configuration.userContentController.addUserScript(script)
    }

    @objc
    public func setupNavMonitor() {
        let script = WKUserScript(source: WKWebView.navContent, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        self.configuration.userContentController.addUserScript(script)
    }

    private static func getFileContent(fileName: String) -> String {
        guard let bundle = Bundle.LPMBundle else {
            assertionFailure("Fail to get LarkPrivacyMonitor bundle.")
            return ""
        }
        guard let filePath = bundle.path(forResource: fileName, ofType: "js") else {
            assertionFailure("Fail to get \(fileName).js file.")
            return ""
        }
        do {
            // lint:disable:next lark_storage_check
            return try String(contentsOfFile: filePath, encoding: .utf8)
        } catch {
            assertionFailure("Fail to read \(fileName).js content, reason: \(error)")
            return ""
        }
    }

    @objc
    public func addMessageHandler() {
        self.configuration.userContentController.removeScriptMessageHandler(forName: "SCSNetworkFlowMonitor")
        self.configuration.userContentController.add(WebViewFlowPipeline(), name: "SCSNetworkFlowMonitor")
    }
}

final class WebViewFlowPipeline: TSPKNetworkDetectPipeline {
    override class func preload() {
        WKWebView.snc_setupNetworkMonitor()
    }
}

extension WebViewFlowPipeline: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            assertionFailure("Message type error.")
            return
        }
        let url = body["url"] as? String ?? ""
        let href = body["href"] as? String ?? ""
        let referrer = body["referrer"] as? String ?? ""
        let request = WebViewRequest(url: url, href: href, referrer: referrer)
        let response = WebViewResponse(url: url, href: href, referrer: referrer)
        Self.onResponse(response, request: request, data: nil)
    }
}

fileprivate class WebViewRequest: NSObject {
    let url: String
    let href: String
    let referrer: String

    init(url: String, href: String, referrer: String) {
        self.url = url
        self.href = href
        self.referrer = referrer
    }
}

fileprivate class WebViewResponse: NSObject {
    let url: String
    let href: String
    let referrer: String

    init(url: String, href: String, referrer: String) {
        self.url = url
        self.href = href
        self.referrer = referrer
    }
}

extension WebViewRequest: TSPKCommonRequestProtocol {
    var tspk_util_headers: [String: String]? {
        nil
    }

    var tspk_util_HTTPBody: Data? {
        nil
    }

    var tspk_util_HTTPBodyStream: InputStream? {
        nil
    }

    var tspk_util_HTTPMethod: String? {
        "Unknown"
    }

    var tspk_util_eventType: String? {
        "h5"
    }

    var tspk_util_eventSource: String? {
        "webview"
    }

    var tspk_util_isRedirect: Bool {
        false
    }

    func tspk_util_setValue(_ value: String?, forHTTPHeaderField field: String?) {
        // empty
    }

    func tspk_util_value(forHTTPHeaderField field: String?) -> String? {
        nil
    }

    func tspk_util_doDrop(_ actions: [AnyHashable: Any]?) {
        // empty
    }

    // swiftlint:disable unused_setter_value
    var tspk_util_url: URL? {
        get {
            URL(string: self.url)
        }
        set(tspk_util_url) {
            // do nothing
        }
    }
    // swiftlint:enable unused_setter_value
}

extension WebViewResponse: TSPKCommonResponseProtocol {
    var tspk_util_url: URL? {
        URL(string: self.url)
    }

    var tspk_util_headers: [String: String]? {
        [
            "url": url,
            "href": href,
            "referrer": referrer
        ]
    }

    func tspk_util_value(forHTTPHeaderField field: String?) -> String? {
        tspk_util_headers?[field ?? ""]
    }
}
