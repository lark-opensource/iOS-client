//
//  WKHTTPHandler.swift
//  LarkRustClient
//
//  Created by SolaWing on 2018/12/28.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

#if ENABLE_WKWebView
import Foundation
import WebKit
import HTTProtocol

/// 使WKWebView可以拦截HTTP和HTTPS，并使用Rust进行统一请求。
///
/// 需要拦截转发的WKWebView, 直接注册该类为WKWebViewConfiguration的对应协议的处理者即可:
///   configuration.setURLSchemeHandler(WKHTTPHandler.shared, forURLScheme: "http")
///   configuration.setURLSchemeHandler(WKHTTPHandler.shared, forURLScheme: "https")
///   WKHTTPHandler.shared.patchJSCookieSetterForSync(in: configuration.userContentController)
///
/// 或者一行调用: WKHTTPHandler.shared.enable(in: configuration)

@available(iOS 11.0, *)
public final class WKHTTPHandler: WKBaseHTTPHandler {
    public static var shared = WKHTTPHandler()

    // MARK: WKHTTPTaskDelegate
    public override func taskURLProtocol(_ task: WKHTTPTask) -> URLProtocol.Type {
        return RustHttpURLProtocol.self
    }
}
#endif
