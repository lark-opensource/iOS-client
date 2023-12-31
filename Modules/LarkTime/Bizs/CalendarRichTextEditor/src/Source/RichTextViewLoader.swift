//
//  WebViewLoader.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/19.
// swiftlint:disable line_length

import UIKit
import Foundation
import WebKit
import LarkExtensions
import LarkFeatureGating

final class RichTextViewLoader {

    weak var webView: WKWebView?

    var clientInfos = [String: String]()

    var terminateCount: Int = 0

    private var canWebViewReload: Bool = true

    private var needsReload: Bool = false

    private var domainPool: Array = [String]()
    private var spaceApiDomain: String = ""
    private var mainDomain: String = ""

    private var currentUrl: URL? {
        // 日历前端使用这个 host 发送请求，需要和他们保持一致
        var suffix = ""
        if spaceApiDomain.isEmpty {
            Logger.error("richTextView spaceApiDomain = isEmpty")
            assertionFailure()
        }
        let host = spaceApiDomain.isEmpty ? "internal-api.feishu.cn" : spaceApiDomain
        let useDocV2 = LarkFeatureGating.shared.getStaticBoolValue(for: FeatureGatingKey.docV2.rawValue)
        suffix = useDocV2 ?
            "://\(host)/calendar_v2/mobile_index.html" : "://\(host)/calendar_v2/mobile_index_old.html"
        return URL(string: SourceSchemeHandler.scheme + suffix)
    }

    init(_ webView: WKWebView) {
        self.webView = webView
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    func injectDomain(domainPool: [String], spaceApiDomain: String, mainDomain: String) {
        self.domainPool = domainPool
        self.spaceApiDomain = spaceApiDomain
        self.mainDomain = mainDomain
        guard let thisWebView = webView else {
            Logger.info("injectDomain webview is nil")
            return
        }
        Logger.info("richTextView injectDomain")

        var domainPoolStr = ""
        domainPool.forEach { (domain) in
            domainPoolStr += "'\(domain)',"
        }

        let jsSource = """
            var domainConfig = {
              common: {
                domainPool: [
                  \(domainPoolStr)
                ],
              },
              space_api: [
                '\(spaceApiDomain)',
              ],
              urlMapper: {
                downloadLark: 'https://\(mainDomain)/download',
              },
            };
        """
        let config = thisWebView.configuration
        let controller = config.userContentController
            controller.addUserScript(WKUserScript(
                source: jsSource,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false))
    }

    @discardableResult
    func loadCalendar() -> Bool {
        guard let url = self.currentUrl else { return false }
        terminateCount = 0
        Logger.info("RTTextView load calendar resource", extraInfo: ["url": url.absoluteString])
        webView?.load(URLRequest(url: url))
        return true
    }

    func isTemplateURL(_ url: URL) -> Bool {
        return url.absoluteString == currentUrl?.absoluteString
    }

    func reloadWhenTerminate() -> Bool {
        needsReload = true
        terminateCount += 1
        if webView?.url == nil {
            Logger.info("RichTextView reload url is nil")
        }
        return true
    }

    @objc
    private func appWillEnterForeground() {
        canWebViewReload = false
        reloadIfNeeded()
    }

    @objc
    private func appDidEnterBackground() {
        canWebViewReload = false
    }

    private func reloadIfNeeded() {
        if canWebViewReload && needsReload {
            Logger.info("RichTextView will reload")
            needsReload = false
            webView?.reload()
        } else if needsReload {
            Logger.info("RichTextView will delay reload")
        }
    }

//    private func makeCookie() -> [HTTPCookie] {
//        guard let url = currentUrl, let token = User.current.token else { return [] }
//        return ["bear-session", "session"].compactMap {
//            return url.cookie(value: token, forName: $0)
//        }
//    }

    var webRequestHeaders: [String: String] {
        var userAgent = defaultWebViewUA
        let language = (Locale.preferredLanguages.first ?? Locale.current.identifier).hasPrefix("zh") ? "zh" : "en"
        userAgent += " [\(language)] Bytedance"
        let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        userAgent += " \("DocsSDK")/\(version)"
        self.clientInfos.forEach({ (key, value) in
            userAgent += " \(key)/\(value)"
        })
        var dict: [String: String] = [:]
        dict["User-Agent"] = userAgent
        return dict
    }

    var defaultWebViewUA: String = {
        #if DEBUG
        return "Mozilla/5.0 (\(UIDevice.current.lu.modelName()); CPU \(UIDevice.current.systemName) \(UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X) AppleWebKit/604.4.7 (KHTML, like Gecko) Mobile/15C153 Lark/2.4.0"
        #else
        return "Mozilla/5.0 (\(UIDevice.current.lu.modelName()); CPU \(UIDevice.current.systemName) \(UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X) AppleWebKit/604.4.7 (KHTML, like Gecko) Mobile/15C153"
        #endif
    }()
}
