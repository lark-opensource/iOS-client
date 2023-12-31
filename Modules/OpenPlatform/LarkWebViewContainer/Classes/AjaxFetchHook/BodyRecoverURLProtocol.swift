import LarkContainer
import ECOInfra
import ECOProbe
import LKCommonsLogging
import WebKit

private let bodyRecoverURLProtocolKey = "bodyRecoverURLProtocolKey"

private let larkWebBodyRecoverRequestID = "Lark-Web-Body-Recover-Request-ID"

public final class BodyRecoverURLProtocol: URLProtocol {
    
    static let logger = Logger.lkwlog(BodyRecoverURLProtocol.self, category: "BodyRecoverURLProtocol")
    
    override public class func canInit(with request: URLRequest) -> Bool {
        //  给我们处理过的请求设置一个标识符, 防止无限循环
        if let p = URLProtocol.property(forKey: bodyRecoverURLProtocolKey, in: request) as? Bool, p {
            return false
        }
        if let larkWebBodyRecoverRequestID = request.allHTTPHeaderFields?[larkWebBodyRecoverRequestID],
           !larkWebBodyRecoverRequestID.isEmpty {
            logger.info("\(request.url?.safeURLString) should recover body and canIntercept value is true")
            return true
        } else if hasResourceID(url: request.url) {
            logger.info("\(request.url?.safeURLString) should recover body and canIntercept value is true")
            return true
        } else {
            return false
        }
    }
    
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override public func startLoading() {
        let nsRequest = request as NSURLRequest
        guard let nsMReq = nsRequest.mutableCopy() as? NSMutableURLRequest else {
            let msg = "nsRequest.mutableCopy error for \(request.url?.safeURLString), as? NSMutableURLRequest is nil"
            assertionFailure(msg)
            Self.logger.error(msg)
            return
        }
        URLProtocol.setProperty(true, forKey: bodyRecoverURLProtocolKey, in: nsMReq)
        var hasGetID = false
        if let larkWebBodyRecoverRequestID = request.allHTTPHeaderFields?[larkWebBodyRecoverRequestID] {
            //  移除临时的header
            nsMReq.allHTTPHeaderFields?[larkWebBodyRecoverRequestID] = nil
            //  恢复Body
            if nsMReq.httpMethod != "GET", nsMReq.httpMethod != "OPTIONS", let recoverBody = RecoverRequestBodyManager.shared.body(with: larkWebBodyRecoverRequestID) {
                Self.logger.info("recover body for \(request.url?.safeURLString)")
                LarkWebViewAjaxBodyHelper.setBodyRequest(recoverBody, to: nsMReq)
            }
            hasGetID = true
        }
        if !hasGetID, let u = request.url {
            let resourceIDAndURL = parseURLResourceID(url: u)
            if let resourceID = resourceIDAndURL.0 {
                if nsMReq.httpMethod != "GET", nsMReq.httpMethod != "OPTIONS", let recoverBody = RecoverRequestBodyManager.shared.body(with: resourceID) {
                    LarkWebViewAjaxBodyHelper.setBodyRequest(recoverBody, to: nsMReq)
                }
                nsMReq.url = resourceIDAndURL.1
            }
        }
        //  设置 Cookie
        nsMReq.syncRequestCookie()
        DispatchQueue.main.async {
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                if let urlHost = self.request.url?.host?.lowercased() {
                    let validCookies = cookies.filter { $0.lkw_validFor(host: urlHost) }
                    let headerFields = HTTPCookie.requestHeaderFields(with: validCookies)
                    if let cookieString = headerFields["Cookie"] {
                        nsMReq.setValue(cookieString, forHTTPHeaderField: "Cookie")
                    }
                }
                var channel: ECONetworkChannel
                BodyRecoverURLProtocol.logger.error("net_framework is \(LarkWebSettings.shared.settingsModel?.offline?.ajax_hook.net_framework?.rawValue)")
                if LarkWebSettings.shared.settingsModel?.offline?.ajax_hook.net_framework == .system {
                    channel = .native
                } else {
                    channel = .rust
                }
                let task = Injected<ECONetworkClientProtocol>(name: channel.rawValue, arguments: OperationQueue(), DefaultRequestSetting).wrappedValue.dataTask(with: ECONetworkContext(from: nil, trace: OPTraceService.default().generateTrace()), request: nsMReq as URLRequest) { [weak self] _, data, response, error in
                    guard let self = self else { return }
                    if let error = error {
                        self.client?.urlProtocol(self, didFailWithError: error)
                        return
                    }
                    DispatchQueue.main.async {
                        if let res = response, let u = res.url {
                            if let hs = res.allHeaderFields as? [String: String] {
                                HTTPCookie.cookies(withResponseHeaderFields: hs, for: u).forEach { c in
                                    WKWebsiteDataStore.default().httpCookieStore.setCookie(c)
                                }
                            } else {
                                BodyRecoverURLProtocol.logger.error("res.allHeaderFields is not [String: String]")
                            }
                        }
                        DispatchQueue.global().async {
                            if let response = response {
                                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                            }
                            if let data = data {
                                self.client?.urlProtocol(self, didLoad: data)
                            }
                            self.client?.urlProtocolDidFinishLoading(self)
                        }
                    }
                }
                task.resume()
            }
        }
    }
    
    override public func stopLoading() {
        //  do nothing
    }
}

extension HTTPCookie {
    // code from apple
    func lkw_validFor(host: String) -> Bool {
        // RFC6265 - HTTP State Management Mechanism
        // https://tools.ietf.org/html/rfc6265#section-5.1.3
        //
        // 5.1.3.  Domain Matching
        // A string domain-matches a given domain string if at least one of the
        // following conditions hold:
        //
        // 1)  The domain string and the string are identical.  (Note that both
        //     the domain string and the string will have been canonicalized to
        //     lower case at this point.)
        //
        // 2) All of the following conditions hold:
        //    * The domain string is a suffix of the string.
        //    * The last character of the string that is not included in the
        //      domain string is a %x2E (".") character.
        //    * The string is a host name (i.e., not an IP address).

        guard domain.hasPrefix(".") else { return host == domain }
        return host == domain.dropFirst() || host.hasSuffix(domain)
    }
}
/// 判断 url 中是否有 ResourceID 标记
/// - Parameter url: url
/// - Returns: 是否有 ResourceID 标记
private func hasResourceID(url: URL?) -> Bool {
    guard let url = url else {
        return false
    }
    if let fragment = url.fragment, !fragment.isEmpty {
        do {
            let regex = "(%5E|\\^){4}[0-9a-zA-Z_-]+(%5E|\\^){4}"
            let re0 = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            // 查找标记
            return re0.firstMatch(in: fragment, options: [], range: NSMakeRange(0, fragment.count)) != nil
        } catch {
            BodyRecoverURLProtocol.logger.error("hasResourceID error", error: error)
        }
    }
    return false
}

/// 提取 url 中的 ResourceID 标记并且移除标记还原 URL
/// - Parameter url:
///   "https://x.y" -> "https://x.y#^^^^{resourceID}^^^^" -> ({resourceID}, "https://x.y")
///   "https://x.y#" -> "https://x.y#^^^^X{resourceID}^^^^" -> ({resourceID}, "https://x.y#")
///   "https://x.y#X" -> "https://x.y#X^^^^X{resourceID}^^^^" -> ({resourceID}, "https://x.y#X")
/// - Returns: (resourceID, originURL)
private func parseURLResourceID(url: URL) -> (String?, URL) {
    var replaceID: String?
    var newURL: URL?
    if let fragment = url.fragment, !fragment.isEmpty {
        do {
            let regex = "(%5E|\\^){4}[0-9a-zA-Z_-]+(%5E|\\^){4}"
            let re0 = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            // 查找标记
            if let match = re0.firstMatch(in: fragment, options: [], range: NSMakeRange(0, fragment.count)) {
                // 获取标记内容
                let replaceIDTag = (fragment as NSString).substring(with: match.range)
                
                // 尝试从标记中读取 replaceID 内容（删除非内容部分）
                let regex = "((^(%5E|\\^){4})|((%5E|\\^){4})$)"
                let re1 = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
                replaceID = re1.stringByReplacingMatches(in: replaceIDTag, options: [], range: NSMakeRange(0, replaceIDTag.count), withTemplate: "")
                
                // 移除标记并获得新 fragment
                let newFragment = re0.stringByReplacingMatches(in: fragment, options: [], range: NSMakeRange(0, fragment.count), withTemplate: "")
                
                // 如果 replaceID 以 X 开头，说明组装 URL 的时候，已经自带了 #，因此还原 URL 的时候，不需要移除已有的 #
                let fragmentFixTag = "X"
                
                // 组装新的去除标记后的新 URL
                if var urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    if newFragment.isEmpty, replaceID?.starts(with: fragmentFixTag) != true {
                        // 对于这种情况，要移除 #
                        urlComponent.fragment = nil
                    } else {
                        urlComponent.fragment = newFragment
                    }
                    newURL = urlComponent.url
                }
                
                // 对于以 X 开头的 replaceID，要移除 X
                if let tReplaceID = replaceID, tReplaceID.starts(with: fragmentFixTag) {
                    replaceID = String(tReplaceID[tReplaceID.index(after: tReplaceID.startIndex)...])
                }
            }
        } catch {
            BodyRecoverURLProtocol.logger.error("parseURLResourceID error", error: error)
        }
    }
    return (replaceID, newURL ?? url)
}
