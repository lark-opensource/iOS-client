//
//  WebDetectHelper.swift
//  WebBrowser
//
//  Created by ByteDance on 2022/10/20.
//

import Foundation
import LKCommonsLogging

private let logger = Logger.webBrowserLog(WebDetectHelper.self, category: "WebDetectHelper")

class DetectPageHandler: InternalSchemeResponse {
    func response(forRequest request: URLRequest) -> (URLResponse, Data)? {
        guard let url = request.url else {
            logger.error("detect page request url is nil")
            return nil
        }
        guard let component = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            logger.error("detect page URLComponents init is nil, url: \(url.safeURLString)")
            return nil
        }
        let response = InternalSchemeHandler.response(forUrl: url)
        guard let html = webBrowserDependency.webDetectPageHTML() else {
            logger.error("detect page html is nil")
            return nil
        }
        if html.isEmpty {
            logger.error("detect page html is empty")
            return nil
        }
        guard let data = html.data(using: .utf8) else {
            logger.error("detect page html.data(using: .utf8) is nil")
            return nil
        }
        return (response, data)
    }
}

public final class WebDetectHelper {
    public static func isValid(url: URL) -> Bool {
        guard url.scheme == BrowserInternalScheme && url.host == BrowserInternalLocalDomain && url.path == BrowserInternalDetectPagePath else {
            return false
        }
        return true
    }
    
    public func loadPage(_ browser: WebBrowser, fromUrl: URL?) {
        guard var components = URLComponents(string: "\(BrowserInternalScheme)://\(BrowserInternalLocalDomain)\(BrowserInternalDetectPagePath)") else {
            logger.error("detect page URLComponents init is nil")
            return
        }
        guard let urlWithQuery = components.url else {
            logger.error("detect page components.url is nil")
            return
        }
        let request = URLRequest(url: urlWithQuery)
        browser.webview.load(request)
    }
}
