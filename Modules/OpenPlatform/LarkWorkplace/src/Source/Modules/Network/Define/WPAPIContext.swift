//
//  WPRequestInjectInfo.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/11/28.
//

import Foundation
import LarkSetting

/// 动态请求参数，通过 InjectMiddleware 注入
struct WPRequestInjectInfo {
    static let `default` = WPRequestInjectInfo()

    static let cookie = WPRequestInjectInfo(headerAuthType: .cookie)
    static let session = WPRequestInjectInfo(headerAuthType: .session)

    /// 请求填充的 header 认证类型。
    ///
    /// 用户态隔离后，相关 Lark 登陆态 token 不能再通过全局容器获取，
    /// 根据声明的类型，会在运行时通过 userResolver 获取填充。
    enum HeaderAuthType {
        // cookie 认证，会自动添加 cookie: session=xxxx header
        case cookie
        // session 认证，会自动添加 session: xxxxx
        case session
    }

    /// header 填充的认证类型
    let headerAuthType: HeaderAuthType?
    /// 自定义域名，目前仅工作台 CDN 文件使用
    let customDomain: String?
    /// 自定义请求 URL path，目前仅工作台 CDN 文件使用
    let path: String?
    /// 请求 header，会与前置 header 做 merge，相同 key 会被替换
    let bizHeaders: [String: String]
    /// 自定义请求 URL port，目前仅工作台 CDN 文件使用
    let port: Int?

    init(
        headerAuthType: HeaderAuthType? = nil,
        customDomain: String? = nil,
        path: String? = nil,
        bizHeaders: [String: String] = [:],
        port: Int? = nil
    ) {
        self.headerAuthType = headerAuthType
        self.customDomain = customDomain
        self.path = path
        self.bizHeaders = bizHeaders
        self.port = port
    }
}
