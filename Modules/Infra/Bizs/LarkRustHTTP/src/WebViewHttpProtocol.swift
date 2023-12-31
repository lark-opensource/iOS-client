//
//  WebViewHttpProtocol.swift
//  LarkRustHTTP
//
//  Created by SolaWing on 2019/3/31.
//

#if ENABLE_UI_WEB_VIEW
/// WebView使用全局环境里的Protocol. 该类设置为只捕获WebView的Request
/// (WKWebView需要调用私有API放开URLProtocol的限制，且会丢失Body。推荐使用iOS11 `WKHTTPHandler`的方案)
///
/// 如果直接将RustHttpURLProtocol注册进全局环境, 那将不需要注册这个类
import UIKit
import Foundation
public final class WebViewHttpProtocol: RustHttpURLProtocol {
    public override class func canInit(with request: URLRequest) -> Bool {
        guard let scheme = request.url?.scheme?.lowercased() else { return false }
        // 据观察UIWebView发起的请求都会带上当前页为mainDocumentURL, 而其它URLSession的调用一般都不会设置mainDocumentURL
        // 所以用这个来判断
        return (scheme == "https" || scheme == "http") && request.mainDocumentURL != nil
    }
    public override class func canInit(with task: URLSessionTask) -> Bool {
        guard let request = task.currentRequest, let scheme = request.url?.scheme?.lowercased() else { return false }
        return (scheme == "https" || scheme == "http") && request.mainDocumentURL != nil
    }
}
#endif
