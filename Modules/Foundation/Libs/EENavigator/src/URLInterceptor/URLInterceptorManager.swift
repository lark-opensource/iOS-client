//
//  URLInterceptor.swift
//  Lark
//
//  Created by liuwanlin on 2019/1/9.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LKCommonsLogging

private typealias URLInterceptorMiddleware = (URL, NavigatorFrom) -> Bool
private typealias URLInterceptor = (String?, URL, NavigatorFrom) -> Bool

/// 注册外部跳转用
/// TODO: 用户隔离区分, 这里应该是要根据URL规范来获取user使用
public final class URLInterceptorManager {
    public static let shared = URLInterceptorManager()
    private static let logger = Logger.log(URLInterceptorManager.self, category: "Lark")
    private var interceptors: [URLInterceptor] = []
    private var middlewares: [URLInterceptorMiddleware] = []

    // Middleware 在所有 URLInterceptor 之前处理，如果返回 true 则不再执行 URLInterceptor
    public func register(middleware: @escaping (URL, NavigatorFrom) -> Bool) {
        middlewares.append(middleware)
    }

    public func register(_ pattern: String, handler: @escaping (URL, NavigatorFrom) -> Void) {
        interceptors.append { (matchedPattern, url, from) -> Bool in
            if matchedPattern == pattern {
                handler(url, from)
                return true
            }
            return false
        }
    }

    public func handle(_ url: URL, from: NavigatorFrom) {
        for middleware in middlewares {
            if middleware(url, from) {
                // MiddleWare 已经处理完成，不再处理
                return
            }
        }

        let response = Navigator.shared.response(for: url, test: true)
        var matched = false
        if (response.request.context[ContextKeys.matched] as? Bool) == true {
            let parameters = response.request.parameters
            let matchedPattern = parameters[ContextKeys.matchedPattern] as? String
            var idx = 0
            while idx < interceptors.count {
                if interceptors[idx](matchedPattern, url, from) {
                    matched = true
                    break
                }
                idx += 1
            }
        }

        if !matched {
            URLInterceptorManager.logger.info(
                "unregistered interceptor",
                additionalData: ["url": url.logInfo]
            )
        }
    }

    public func handle(_ url: URL, from: NavigatorFrom, options: [UIApplication.OpenURLOptionsKey: Any]) {
        if let bundleId = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String {
            // will remove bundle_id in query, then append new bundle_id
            let url = url.append(name: "bundle_id", value: bundleId)
            self.handle(url, from: from)
        } else {
            URLInterceptorManager.logger.info("unable to parse bundleId")
            self.handle(url, from: from)
        }
    }

    @available(iOS 13.0, *)
    public func handle(_ url: URL, from: NavigatorFrom, options: UIScene.OpenURLOptions) {
        if let bundleId = options.sourceApplication {
            // will remove bundle_id in query, then append new bundle_id
            let url = url.append(name: "bundle_id", value: bundleId)
            self.handle(url, from: from)
        } else {
            URLInterceptorManager.logger.info("unable to parse bundleId")
            self.handle(url, from: from)
        }
    }
}
