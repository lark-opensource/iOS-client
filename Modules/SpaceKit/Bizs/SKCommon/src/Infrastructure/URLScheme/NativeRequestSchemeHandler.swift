import ECOInfra
import Foundation
import LarkContainer
import LarkRustHTTP
import LarkWebViewContainer
import SKFoundation
import WebKit

private var objcKey = "objcKey"

/// 请求拦截器，拦截请求到 Native 发起，和 docsource 不同的是对 header body cookie 进行了network process 的对等处理
public final class NativeRequestSchemeHandler: NSObject, WKURLSchemeHandler {
    
    private lazy var session = RustHTTPSession()
    
    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        
        var req = urlSchemeTask.request
        
        var nativeCookies = [HTTPCookie]()
        
        if let u = req.url {
            if var component = URLComponents(url: u, resolvingAgainstBaseURL: false) {
                component.scheme = "https"
                if let u2 = component.url {
                    req.url = u2
                    if let cks = HTTPCookieStorage
                        .shared
                        .cookies(for: u2) {
                        nativeCookies = cks
                    }
                } else {
                    DocsLogger.error("new url from URLComponents error, component: \(component)")
                }
            } else {
                DocsLogger.error("new URLComponents error, url: \(u)")
            }
        } else {
            DocsLogger.error("req.url is nil")
        }
        
        WKWebsiteDataStore
            .default()
            .httpCookieStore
            .getAllCookies { [weak self] cookies in
                
                guard let self = self else {
                    return
                }
                
                if self.shouldStop(urlSchemeTask: urlSchemeTask) {
                    return
                }
                
                var cookies = cookies
                
                var webCookieNames = cookies.map {
                    $0.name
                }
                
                nativeCookies.forEach { c in
                    if !webCookieNames.contains(c.name) {
                        cookies.append(c)
                    }
                }
                
                req.setwk(cookies: cookies)
                
                for ck in cookies {
                    if ck.name == "_csrf_token" {
                        req.setValue(ck.value, forHTTPHeaderField: "X-CSRFToken")
                    }
                }
                
                DocsLogger.info("NativeRequestSchemeHandler, load resource from remote net for url: \(req.url) use RustHTTPSession")
                
                let task = URLSession.shared
                    .dataTask(with: req) { [weak self] data, response, error in
                        
                        DocsLogger.info("NativeRequestSchemeHandler, load resource finish \(response)")
                        
                        guard let self = self else { return }
                        
                        DispatchQueue.main.async {
                            
                            if self.shouldStop(urlSchemeTask: urlSchemeTask) { return }
                            
                            if let error = error {
                                DocsLogger.error("NativeRequestSchemeHandler, load resource from remote net error", error: error)
                                urlSchemeTask.didFailWithError(error)
                                return
                            }
                            
                            if let response = response {
                                
                                DocsLogger.info("NativeRequestSchemeHandler, load resource from remote net url: \(response.url) data.count: \(data?.count)")
                                
                                response.syncCookiesToWKHTTPCookieStore {
                                    
                                    if self.shouldStop(urlSchemeTask: urlSchemeTask) { return }
                                    
                                    urlSchemeTask.didReceive(response)
                                    if let data = data {
                                        urlSchemeTask.didReceive(data)
                                    }
                                    urlSchemeTask.didFinish()
                                }
                            } else {
                                DocsLogger.error("no error, no response")
                                assertionFailure("no error, no response")
                                urlSchemeTask.didFailWithError(NSError(domain: "NativeRequestSchemeHandlerDomain", code: -1))
                            }
                        }
                    }
                task.resume()
            }
    }
    
    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        objc_setAssociatedObject(
            urlSchemeTask,
            &objcKey,
            "stop",
            .OBJC_ASSOCIATION_RETAIN
        )
    }
    
    func shouldStop(urlSchemeTask: WKURLSchemeTask) -> Bool {
        guard let s = objc_getAssociatedObject(urlSchemeTask, &objcKey) as? String else {
            return false
        }
        if s == "stop" {
            return true
        } else {
            return false
        }
    }
}
