//
//  OPApplicationConfigProtocol.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/11/17.
//

import Foundation
import OPFoundation

/// 账号信息
public final class OPAppAccountConfig: NSObject {

    /// 获取lark登录以后返回的user session
    public let userSession: String

    /// 用于唯一标识一个 账户 的 token，用于隔离多账户的小程序数据
    public let accountToken: String

    /// 用户ID
    public let userID: String

    /// 租户ID
    public let tenantID: String

    public init(userSession: String, accountToken: String, userID: String, tenantID: String) {
        self.userID = userID
        self.userSession = userSession
        self.accountToken = accountToken
        self.tenantID = tenantID
    }

}

/// 基础环境信息
@objcMembers
public final class OPAppEnvironment: NSObject {

    /// lark 运行环境
    public let envType: OPEnvType


    /// lark 版本号
    public let larkVersion: String

    /// 语言设置
    public let language: String

    public init(envType: OPEnvType, larkVersion: String, language: String) {
        self.envType = envType
        self.larkVersion = larkVersion
        self.language = language
    }
}


/// 域名配置: 详见MicroAppDomainConfig
@objcMembers
public final class OPAppDomainConfig: NSObject {

    public let openDomain: String

    public let configDomain: String

    public let pstatpDomain: String

    public let vodDomain: String

    public let snssdkDomain: String

    public let referDomain: String

    public let appLinkDomain: String
    
    public let openAppInterface: String

    public let webViewSafeDomain: String // BDPWebViewComponent 只加载安全域名下的url，否则做拦截操作。

    public init(openDomain: String,
                configDomain: String,
                pstatpDomain: String,
                vodDomain: String,
                snssdkDomain: String,
                referDomain: String,
                appLinkDomain: String,
                openAppInterface: String,
                webViewSafeDomain: String) {
        self.openDomain = openDomain
        self.referDomain = referDomain
        self.configDomain = configDomain
        self.appLinkDomain = appLinkDomain
        self.pstatpDomain = pstatpDomain
        self.vodDomain = vodDomain
        self.snssdkDomain = snssdkDomain
        self.openAppInterface = openAppInterface
        self.webViewSafeDomain = webViewSafeDomain
    }
}

/// 整个引擎生命周期级别的相关配置
@objc public protocol OPApplicationConfigProtocol: NSObjectProtocol {

    var accountConfig: OPAppAccountConfig { get }

    var envConfig: OPAppEnvironment { get }

    var domainConfig: OPAppDomainConfig { get }
}
