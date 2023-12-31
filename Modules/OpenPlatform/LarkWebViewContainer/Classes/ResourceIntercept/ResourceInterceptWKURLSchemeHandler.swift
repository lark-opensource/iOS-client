import ECOInfra
import LarkContainer
import WebKit
private var objcKey = "objcKey"
class ResourceInterceptWKURLSchemeHandler: NSObject, WKURLSchemeHandler {
    private let delegate: WKResourceInterceptProtocol
    init(delegate: WKResourceInterceptProtocol) {
        self.delegate = delegate
        super.init()
    }
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        var req = urlSchemeTask.request
        let interceptSafeURLString = req.url?.absoluteString.safeURLString
        req.tryFixRequest()
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            req.setwk(cookies: cookies)
            self.delegate.shouldInterceptRequest(webView: webView, request: req) { [weak self] result in
                guard let self = self else { return }
                logger.info("web offline wkurlschemehandler, start load resource for url: \(interceptSafeURLString)")
                DispatchQueue.main.async {
                    if self.shouldStop(urlSchemeTask: urlSchemeTask) { return }
                    if let result = result {
                        switch result {
                        case .success(let responseAndData):
                            responseAndData.0.syncCookiesToWKHTTPCookieStore {
                                if self.shouldStop(urlSchemeTask: urlSchemeTask) { return }
                                logger.info("web offline wkurlschemehandler, load resource success for url: \(interceptSafeURLString) and data length:\(responseAndData.1.count)")
                                urlSchemeTask.didReceive(responseAndData.0)
                                urlSchemeTask.didReceive(responseAndData.1)
                                urlSchemeTask.didFinish()
                            }
                        case .failure(let err):
                            logger.error("web offline wkurlschemehandler, load resource faile for url: \(interceptSafeURLString) and errormsg:\(err.localizedDescription)")
                            if let error = err as? NSError, error.userInfo[NSURLErrorFailingURLErrorKey] == nil {
                                if error.userInfo == nil {
                                    var newError = NSError(domain: error.domain, code: error.code, userInfo: [NSURLErrorFailingURLErrorKey:req.url])
                                    urlSchemeTask.didFailWithError(newError)
                                } else {
                                    var newUserInfo = error.userInfo.merging([NSURLErrorFailingURLErrorKey:req.url]) { (current, _) in current }
                                    var newError = NSError(domain: error.domain, code: error.code, userInfo: newUserInfo)
                                    urlSchemeTask.didFailWithError(newError)
                                }
                            } else {
                                urlSchemeTask.didFailWithError(err)
                            }
                        }
                        return
                    }
                    var channel: ECONetworkChannel
                    if LarkWebSettings.shared.settingsModel?.offline?.ajax_hook.net_framework == .system {
                        channel = .native
                    } else {
                        channel = .rust
                    }
                    logger.info("web offline wkurlschemehandler, load resource from remote net for url: \(interceptSafeURLString) at channel:\(channel.rawValue)")
                    let task = Injected<ECONetworkClientProtocol>(name: channel.rawValue, arguments: OperationQueue(), DefaultRequestSetting).wrappedValue.dataTask(with: ECONetworkContext(from: nil, trace: OPTraceService.default().generateTrace()), request: req) { [weak self] _, data, response, error in
                        guard let self = self else { return }
                        DispatchQueue.main.async {
                            if self.shouldStop(urlSchemeTask: urlSchemeTask) { return }
                            if let error = error {
                                urlSchemeTask.didFailWithError(error)
                                return
                            }
                            if let response = response {
                                response.syncCookiesToWKHTTPCookieStore {
                                    if self.shouldStop(urlSchemeTask: urlSchemeTask) { return }
                                    urlSchemeTask.didReceive(response)
                                    if let data = data {
                                        urlSchemeTask.didReceive(data)
                                    }
                                    urlSchemeTask.didFinish()
                                }
                            } else {
                                assertionFailure("no error, no response")
                                urlSchemeTask.didFailWithError(NSError(domain: "ResourceInterceptWKURLSchemeHandlerDomain", code: -1))
                            }
                        }
                    }
                    task.resume()
                }
            }
        }
    }
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        objc_setAssociatedObject(urlSchemeTask, &objcKey, "stop", .OBJC_ASSOCIATION_RETAIN)
    }
    private func shouldStop(urlSchemeTask: WKURLSchemeTask) -> Bool {
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
