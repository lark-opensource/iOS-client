import WebKit
import LKCommonsLogging
extension URLResponse {
    static let logger = Logger.lkwlog(FixRequestManager.self, category: "syncCookies")
    public func syncCookiesToWKHTTPCookieStore(completionHandler: @escaping () -> Void) {
        guard Thread.isMainThread else {
            assertionFailure("syncCookiesToWK must call in main thread")
            completionHandler()
            return
        }
        guard let u = url, let hs = allHeaderFields as? [String: String] else {
            completionHandler()
            return
        }
        let cs = HTTPCookie.cookies(withResponseHeaderFields: hs, for: u)
        guard !cs.isEmpty else {
            completionHandler()
            return
        }
        var count = 0
        for c in cs {
            WKWebsiteDataStore.default().httpCookieStore.setCookie(c) {
                count += 1
                URLResponse.logger.info("syncCookiesToWK，\(c.name), value:\(c.value.count), domain:\(c.domain)")
                if count == cs.count {
                    completionHandler()
                }
            }
        }
    }
}
