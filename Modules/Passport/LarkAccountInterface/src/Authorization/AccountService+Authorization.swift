//
//  AccountService.swift
//  LarkAccountInterface
//
//  Created by quyiming on 2020/9/25.
//

import Foundation

/// 用户态授权服务
public protocol PassportAuthorizationService: AnyObject {

    /// 初始化授权
    func checkAuth(info: SSOAuthType, result: @escaping (Result<UIViewController?, Error>) -> Void)

    /// 检查是否是 SSO SDK URL
    func handleSSOSDKUrl(_ url: URL) -> Bool

    /// 获取登录授权码
    func getAuthorizationCode(
        req: AuthCodeReq,
        result: @escaping (Result<AuthCodeResp, Error>) -> Void
    )
}

/// SSO  授权类型
@frozen
public enum SSOAuthType {
    /// 扫码授权
    case qrCode(_ token: String)
    /// Web 跳转授权
    case url(_ token: String, _ bundleId: String, _ schema: String)
    /// SSO SDK 授权
    case sdk(_ appId: String, _ state: String, _ otherParams: [String: String])
    /// 授权免登 https://bytedance.feishu.cn/docx/doxcneveCZpLL4s6xywwhGfIWQc?comment_id=7101879243793104900
    case authAutoLogin(_ token: String, _ bundleId: String, _ schema: String)
}

/// 获取授权码请求
public struct AuthCodeReq {
    /// 接入应用ID
    public let appId: String
    /// 接入应用回调URI
    public let redirectUri: String?
    /// 请求权限 不同权限以空格隔开 "scopeA scopeB"  （保留，暂时不需要）
    public let scope: String?
    /// 包名
    public let packageId: String?
    /// 状态校验
    public let state: String?

    /// 初始化
    /// - Parameters:
    ///   - appId: 接入应用ID 必填
    ///   - redirectUri: 接入应用回调URI 不填默认使用AppID自动生成
    ///   - packageId: 包名 不填默认取当前 bundleID
    ///   - scope: 请求权限 不同权限以空格隔开 "scopeA scopeB"  不填留空（暂时不需要）
    ///   - state: 用户状态校验 不填会生成一个UUID作为校验
    public init(
        appId: String,
        redirectUri: String? = nil,
        packageId: String? = nil,
        scope: String? = nil,
        state: String? = nil
    ) {
        self.appId = appId
        self.redirectUri = redirectUri
        self.scope = scope
        self.packageId = packageId
        self.state = state
    }
}

/// 授权码请求结果
public struct AuthCodeResp: Codable {
    /// 授权码
    public let code: String
    /// 状态码
    public let state: String
}
