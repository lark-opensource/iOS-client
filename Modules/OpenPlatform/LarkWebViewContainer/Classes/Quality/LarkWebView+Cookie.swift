//
//  LarkWebView+Cookie.swift
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/9/6.
//  

import Foundation
import ECOInfra
import LarkSetting

/// 同步cookies
public extension LarkWebView {
    /// loadUrl，并同步cookies
    /// - Parameter request: 需要加载的URL
    func loadWithSyncCookies(_ request: URLRequest) {
        syncCookies {
            self.load(request)
        }
    }
    
    static let cookieBatchCount = 15

    /// 同步Cookie
    /// - Parameter completionHandler: 完成回调
    func syncCookies(completionHandler: (() -> Void)? = nil) {
        logger.info("prepare sync Cookies to webview")
        if let httpCookies = HTTPCookieStorage.shared.cookies, !httpCookies.isEmpty {
            let httpCookieStore = self.configuration.websiteDataStore.httpCookieStore
            logger.info("sync Cookies has \(httpCookies.count) cookies to set")
            var count = 0
            if LarkWebSettings.lkwEncryptLogEnabel {
                var startCookies = [Any]()
                var endCookies = [Any]()
                for cookie in httpCookies {
                    if startCookies.count == LarkWebView.cookieBatchCount {
                        let startCookiesString = String(describing: startCookies)
                        logger.info("start sync Cookies to webview, infos:\(startCookiesString)")
                        startCookies.removeAll()
                    }
                    let maskedValue = cookie.value.lkw_cookie_mask()
                    let cookieInfo = [
                        "domain" : cookie.domain,
                        "path" : cookie.path,
                        "name" : cookie.name,
                        "value" : maskedValue,
                        "valuelength": String(describing: cookie.value.count),
                        "secure" : cookie.isSecure ? "true":"false",
                        "httpOnly" : cookie.isHTTPOnly ? "true":"false",
                        ]
                    startCookies.append(cookieInfo)
                    httpCookieStore.setCookie(cookie) {
                        if endCookies.count == LarkWebView.cookieBatchCount {
                            let endCookiesString = String(describing: endCookies)
                            logger.info("end sync Cookies to webview, infos:\(endCookiesString)")
                            endCookies.removeAll()
                        }
                        endCookies.append(cookieInfo)
                        count += 1
                        if count == httpCookies.count {
                            if !endCookies.isEmpty {
                                let endCookiesString = String(describing: endCookies)
                                logger.info("end sync Cookies to webview, infos:\(endCookiesString)")
                            }
                            if let completionHandler = completionHandler {
                                completionHandler()
                            }
                            logger.info("end sync Cookies to webview, count:\(count)")
                        }
                    }
                }
                if !startCookies.isEmpty {
                    let startCookiesString = String(describing: startCookies)
                    logger.info("start sync Cookies to webview, infos:\(startCookiesString)")
                }
            } else {
                for cookie in httpCookies {
                    let maskedValue = cookie.value.lkw_cookie_mask()
                    logger.info("start sync Cookies to webview, domain:\(cookie.domain), path:\(cookie.path), name:\(cookie.name), value:\(maskedValue), value length:\(cookie.value.count), isSecure:\(cookie.isSecure ? "true":"false")", additionalData: [:])
                    httpCookieStore.setCookie(cookie) {
                        logger.info("end sync Cookies to webview, domain:\(cookie.domain), path:\(cookie.path), name:\(cookie.name))", additionalData: [:])
                        count += 1
                        if count == httpCookies.count, let completionHandler = completionHandler {
                            completionHandler()
                        }
                    }
                }
            }
        } else {
            logger.info("sync Cookies to webview finish when cookies empty and call completion")
            if let completionHandler = completionHandler {
                completionHandler()
            }
        }
    }
}
