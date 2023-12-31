//
//  URLExtensions.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/11/17.
//

import UIKit

public extension URL {

    /// URL构造器: 参数跟rest定义对照
    /// - Parameters:
    ///   - domain: 域名，在lark中会根据不同的环境进行下发，详见OPAppDomainConfig
    ///   - path: 接口路径，如open-apis/mina
    ///   - resource: 如AppExtensionMetas 、checkSession
    static func opURL(domain: String, path: String, resource: String) -> URL? {
        // 目前小程序内部相关请求都是https
        return URL(string: "https://\(domain)")?.appendingPathComponent(path).appendingPathComponent(resource)
    }
}
