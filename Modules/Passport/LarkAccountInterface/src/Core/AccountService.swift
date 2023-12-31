//
//  AccountService.swift
//  LarkAccountInterface
//
//  Created by quyiming on 2020/9/25.
//

import Foundation
import RxSwift

// swiftlint:disable missing_docs

/// VerifyToken Type
public typealias VerifyToken = String

public enum VerifyScope: String, Codable {
    case unknown = "unknown"
    case contactVerify = "contact_verify" // 验证联系方式
}

public struct DisposableLoginItem {
    public var key: String
    public var value: Any

    public init(key: String, value: Any) {
        self.key = key
        self.value = value
    }
}

public struct DisposableLoginInfo {
    public let token: DisposableLoginItem
    public let userId: DisposableLoginItem
    public let deviceLoginId: DisposableLoginItem
    public let timestamp: DisposableLoginItem
    public let authAutoLogin: DisposableLoginItem

    public let unitItem: DisposableLoginItem
    public let versionItem: DisposableLoginItem
    public let tenantBrandItem: DisposableLoginItem
    public let pkgBrandItem: DisposableLoginItem
    
    public init(token: DisposableLoginItem, userId: DisposableLoginItem, deviceLoginId: DisposableLoginItem, timestamp: DisposableLoginItem, authAutoLogin: DisposableLoginItem, unitItem: DisposableLoginItem, versionItem: DisposableLoginItem, tenantBrandItem: DisposableLoginItem, pkgBrandItem: DisposableLoginItem) {
        self.token = token
        self.userId = userId
        self.deviceLoginId = deviceLoginId
        self.timestamp = timestamp
        self.authAutoLogin = authAutoLogin
        self.unitItem = unitItem
        self.versionItem = versionItem
        self.tenantBrandItem = tenantBrandItem
        self.pkgBrandItem = pkgBrandItem
    }
}

public enum DisposableLoginError: Error {
    case unLogin
    case identifierInvalid
    case paramsInvalid
    case tokenGenerationError
    case fetchConfigError(Error)
}

/// Account Service
public typealias AccountService = AccountServiceCore

/// feature switch
public protocol FeatureSwitchProtocol {
    /// get feature config value
    func config(for key: String) -> [String]
}

/// App Config
public protocol AppConfigProtocol {
    /// feature enable status
    func featureOn(for key: String) -> Bool
}

public protocol PassportConfProtocol: AnyObject {
    /// Lark App ID, 区分不同应用
    var appID: Int { get set }
    var groupId: String { get }
    var stagingFeatureId: String? { get set }
    var appsFlyerUID: String? { get set }

    /// 服务条款地址
    var serviceTermUrlProvider: (() -> String)? { get set }
    /// 隐私协议地址
    var privacyPolicyUrlProvider: (() -> String)? { get set }
    /// 用户注销协议地址
    var userDeletionAgreementUrlProvider: (() -> String)? { get set }
    /// 登录host url， 默认为 "https://internal-api-lark-api.feishu.cn"
    var apiUrlProvider: (() -> String)? { get set }
    /// 设备服务注册Url
    var deviceIdUrlProvider: (() -> String)? { get set }
    /// 一键登录三大运营商配置
    var oneKeyLoginConfig: [OneKeyLoginConfig]? { get set }
    /// 注册页副标题文案
    var registerPageSubtitleProvider: (() -> String)? { get set }
    /// 姓名输入框Placeholder
    var nameTextFieldPlaceholderProvider: (() -> String)? { get set }
    /// App 图标  size: 86pt
    /// - 使用场景
    ///    一键登录Logo
    var appIcon: UIImage? { get set }
    /// 支持 H5 的 Feature 设置了就是用H5， 否则使用Native
    /// 默认全开
    var h5ReplaceFeatureList: [H5ReplaceFeature] { get set }
    /// Feature Switch
    var featureSwitch: FeatureSwitchProtocol { get set }
    /// App Config
    var appConfig: AppConfigProtocol { get set }
}

/// H5 替换 Native 的功能
public enum H5ReplaceFeature: String, CaseIterable {
    /// 账号安全中心
    case accountSecurityCenter = "account_security_center"
}

/// 移动："mobile" 电信："telecom" 联通: "unicom"
@frozen
public enum OneKeyLoginService: String, CaseIterable {
    /// 移动："mobile"；
    case mobile
    /// 电信："telecom"；
    case telecom
    /// 联通 @"unicom"；
    case unicom
}

/// 一键登录配置
public struct OneKeyLoginConfig {
    /// carrier service
    public let service: OneKeyLoginService
    /// appId registered
    public let appId: String
    /// appId registered
    public let appKey: String

    /// initialization
    public init(service: OneKeyLoginService, appId: String, appKey: String) {
        if appId.isEmpty || appKey.isEmpty {
            assertionFailure("appID & appKey should not be empty")
        }
        self.service = service
        self.appKey = appKey
        self.appId = appId
    }
}

public enum PassportFeature: String {
    /// 加入会议
    /// - 依赖
    ///   - VC
    case joinMeeting
    /// B端 IdP 登录
    ///   - 依赖
    ///     - Google SDK
    case toBIdPLogin
    /// C端 IdP 登录
    ///   - 依赖
    ///     - Google SDK
    ///     - JsSDK
    case toCIdPLogin
    /// 账号找回
    ///   - 依赖
    ///      - 活体识别SDK
    case recoverAccount

    /// 登录注册页加入团队
    case joinTeam

    /// 安全密码设置 (设置页功能入口)
    ///  - 场景
    ///      - 工资单
    case securityPassword

    /// 保持登录态选项
    /// - 登录页 checkbox，保持登录态，默认只在M1的Mac版上开启
    case keepLoginOption

    /// 加密认证数据
    /// - session uid等, 默认只在M1的Mac版上开启
    case encryptAuthData
}

public protocol PassportSwitchProtocol: AnyObject {
    func set(_ key: PassportFeature, _ value: Bool)
    func value(_ key: PassportFeature) -> Bool
}
