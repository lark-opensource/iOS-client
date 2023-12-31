//
//  WebViewSchemeManager.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/11/30.
//

import SKFoundation
import WebKit
import SKUIKit
import SKCommon
import SKInfra

class WebViewSchemeManager {
    fileprivate static var isWKSchemeRegistered = false
    fileprivate static var isWKProtocolRegistered = false

    fileprivate class func isCustomScheme(with url: URL) -> Bool {
        if let scheme = url.scheme, scheme.lowercased() == DocSourceURLProtocolService.scheme {
            return true
        }
        return false
    }

    class func enableCustomSchemeIfNeed(url: URL, webView: WKWebView) -> Bool {
        guard WebViewSchemeManager.isCustomScheme(with: url) == true else {
            return false
        }

        let handler = webView.configuration.urlSchemeHandler(forURLScheme: DocSourceURLProtocolService.scheme)
        if handler is DocSourceSchemeHandler {
            DocsLogger.debug("\(self) current handler for \(DocSourceURLProtocolService.scheme) is DocSourceSchemeHandler")
            return true
        } else {
            let info: [String: Any] = ["contentView": ObjectIdentifier(self), "scheme": DocSourceURLProtocolService.scheme, "handler": "\(handler?.description ?? "")"]
            DocsLogger.error("current handler is not DocSourceSchemeHandler", extraInfo: info, error: nil, component: nil)
            return false
        }
    }

    class func removeCustomDocsSourceScheme(for url: URL) -> URL {
        var resultUrl = url
        if WebViewSchemeManager.isWKSchemeRegistered != true || WebViewSchemeManager.isWKProtocolRegistered != true {
            let info = ["schema register status": WebViewSchemeManager.isWKSchemeRegistered, "protocol register status": WebViewSchemeManager.isWKProtocolRegistered]
            DocsLogger.error("schems status", extraInfo: info, error: nil, component: nil)
            // update url
            if let modifiedUrl = disableDocsSourceSchemeIfNeed(for: url) {
                DocsLogger.info("restore schema to https success")
                resultUrl = modifiedUrl
            } else {
                spaceAssertionFailure()
                DocsLogger.error("restore schema to https fail")
            }
        } else {
            // scheme and protocol is ready
        }
        return resultUrl
    }

    class func disableDocsSourceSchemeIfNeed(for url: URL?) -> URL? {
        guard let openUrl = url else { return nil }
        var httpSchemeUrl = openUrl
        if openUrl.scheme == DocSourceURLProtocolService.scheme {
            var urlComponent = URLComponents(url: openUrl, resolvingAgainstBaseURL: false)
            urlComponent?.scheme = OpenAPI.docs.currentNetScheme
            urlComponent?.url.map { httpSchemeUrl = $0 }
        }
        return httpSchemeUrl
    }
}
