import Foundation
public protocol WKResourceInterceptProtocol {
    /// Notify the host application of a resource request and allow the application to return the data.
    /// - Parameters:
    ///   - webView: The web view invoking the method.
    ///   - request: request that intercepted
    ///   - completionHandler: WebResourceResponse if intercepted, or nil if not intercepted
    func shouldInterceptRequest(webView: WKWebView, request: URLRequest, completionHandler: @escaping (Result<(URLResponse, Data), Error>?) -> Void)
    /// for fixRequest
    var jssdk: String { get }
}
