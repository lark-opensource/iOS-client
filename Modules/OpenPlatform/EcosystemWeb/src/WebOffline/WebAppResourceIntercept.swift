import Foundation
import LarkWebViewContainer
import TTMicroApp
public final class WebAppResourceIntercept: WKResourceInterceptProtocol {
    public init() {}
    public func shouldInterceptRequest(webView: WKWebView, request: URLRequest, completionHandler: @escaping (Result<(URLResponse, Data), Error>?) -> Void) {
        guard OfflineResourcesTool.canIntercept(with: request) else {
            completionHandler(nil)
            return
        }
        OfflineResourcesTool.fetchResources(with: request) { result in
            completionHandler(result)
        }
    }
    public var jssdk: String = CommonComponentResourceManager().fetchJSWithSepcificKey(componentName: "js_for_schemehandler") ?? ""
}
