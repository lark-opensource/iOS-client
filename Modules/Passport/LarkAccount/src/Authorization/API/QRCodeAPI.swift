//
//  QRCodeAPI.swift
//  Lark
//
//  Created by Sylar on 2017/11/16.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import EENavigator

enum QRLoginType: String {
    case qrCode = "qr_code"                  // 正常扫码登录
    case authAutoLogin = "qr_pwd_less_auth"  // 授权免登 https://bytedance.feishu.cn/docx/doxcneveCZpLL4s6xywwhGfIWQc?comment_id=7101879243793104900
}

public struct I18nAgreement: Codable {
    public let enUS: I18nAgreementInfo
    public let zhCN: I18nAgreementInfo
    public let jaJP: I18nAgreementInfo

    public init(enUS: I18nAgreementInfo, zhCN: I18nAgreementInfo, jaJP: I18nAgreementInfo) {
        self.enUS = enUS
        self.zhCN = zhCN
        self.jaJP = jaJP
    }

    enum CodingKeys: String, CodingKey {
        case enUS = "en_us"
        case zhCN = "zh_cn"
        case jaJP = "ja_jp"
    }
}

public struct I18nAgreementInfo: Codable {
    public let clauseUrl: String
    public let privacyPolicyUrl: String

    public init(clauseUrl: String, privacyPolicyUrl: String) {
        self.clauseUrl = clauseUrl
        self.privacyPolicyUrl = privacyPolicyUrl
    }

    enum CodingKeys: String, CodingKey {
        case clauseUrl = "clause_url"
        case privacyPolicyUrl = "privacy_policy_url"
    }
}

protocol QRCodeAPI {

    /// 校验扫码获得的token
    ///
    /// - Returns:
    func checkTokenForLogin(token: String, loginType: QRLoginType) -> Observable<V3.Step>

    /// 确认用该token来登录PC
    ///
    /// - Returns:
    func confirmTokenForLogin(token: String, scope: String, isMultiLogin: Bool, loginType: QRLoginType) -> Observable<V3.Step>

    /// 取消用该token来登录
    ///
    /// - Returns:
    func cancelTokenForLogin(token: String, loginType: QRLoginType) -> Observable<Void>
}

/// third party auth info
public struct ThirdPartyAuthInfo: Codable {
    public let appName: String
    public let subtitle: String
    public let appIconUrl: String   // 应用没有图标时候为空
    public let identityTitle: String
    public let scopeTitle: String
    public let buttonTitle: String?
    public let permissionScopes: [PermissionScope]
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?
    public let i18nAgreement: I18nAgreement?

    public init(appName: String,
                subtitle: String,
                scopeTitle: String,
                appIconUrl: String,
                identityTitle: String,
                buttonTitle: String?,
                permissionScopes: [PermissionScope],
                i18nAgreement: I18nAgreement?) {
        self.appName = appName
        self.subtitle = subtitle
        self.scopeTitle = scopeTitle
        self.appIconUrl = appIconUrl
        self.identityTitle = identityTitle
        self.buttonTitle = buttonTitle
        self.permissionScopes = permissionScopes
        self.i18nAgreement = i18nAgreement
    }

    enum CodingKeys: String, CodingKey {
        case appName = "app_name"
        case subtitle
        case appIconUrl = "app_icon"
        case scopeTitle = "scope_title"
        case identityTitle = "identity_title"
        case buttonTitle = "button"
        case permissionScopes = "permission_scopes"
        case usePackageDomain = "use_package_domain"
        case i18nAgreement = "i18n_agreement"
    }
}

/// suite intenal auth info
public struct SuiteAuthInfo: Codable {
    public let appName: String
    public let subtitle: String
    public let subtitleOption: Bool

    public init(appName: String, subtitle: String, subtitleOption: Bool) {
        self.appName = appName
        self.subtitle = subtitle
        self.subtitleOption = subtitleOption
    }

    enum CodingKeys: String, CodingKey {
        case appName = "title"
        case subtitle = "subtitle"
        case subtitleOption = "subtitle_option"
    }
}

/// auth scope tell what kind of permission is needed
public struct PermissionScope: Codable {
    public let key: String
    public let text: String
    public var required: Bool

    public init(key: String, text: String, required: Bool) {
        self.key = key
        self.text = text
        self.required = required
    }
}

public struct AuthAutoLoginInfo: Codable {
    public let title: String
    public let subtitle: String
}

/// auth info need, when logging in by auth token
public struct LoginAuthInfo: Codable {
    public let template: Template?
    public let thirdPartyAuthInfo: ThirdPartyAuthInfo?
    public let suiteAuthInfo: SuiteAuthInfo?
    public let authAutoLoginInfo: AuthAutoLoginInfo?
    public let buttonList: [V4ButtonInfo]?

    public var isSuite: Bool {
        return template == .suite
    }

    public init(
                template: Template?,
                thirdPartyAuthInfo: ThirdPartyAuthInfo?,
                suiteAuthInfo: SuiteAuthInfo?,
                authAutoLoginInfo: AuthAutoLoginInfo?,
                buttonList: [V4ButtonInfo]?) {
        self.template = template
        self.thirdPartyAuthInfo = thirdPartyAuthInfo
        self.suiteAuthInfo = suiteAuthInfo
        self.authAutoLoginInfo = authAutoLoginInfo
        self.buttonList = buttonList
    }

    enum CodingKeys: String, CodingKey {
        case template = "template"
        case suiteAuthInfo = "suite"
        case thirdPartyAuthInfo = "authz"
        case authAutoLoginInfo = "pwd_less_auth"
        case buttonList = "button_list"
    }

    /// auth info template type
    public enum Template: String, Codable {
        case suite
        case authz
        case authAutoLogin = "pwd_less_auth"
        case authAutoLoginError = "pwd_less_auth_failed"
    }
}

public struct QRCodeAuthControllerBody: CodablePlainBody {

    public static let pattern = "//client/login/auth"

    public let token: String
    public let loginAuthInfo: LoginAuthInfo

    public init(token: String, loginAuthInfo: LoginAuthInfo) {
        self.token = token
        self.loginAuthInfo = loginAuthInfo
    }
}

struct QRCodeError: Error {

    enum TypeEnum {
        case unknown
        case networkIsNotAvailable
        case qrcodeStatusUnusual
        case internalRustClientError
        case otherBusinessError
    }

    let displayMessage: String
    let type: TypeEnum

    init(type: TypeEnum = .unknown, displayMessage: String = I18N.Lark_Passport_BadServerData) {
        self.displayMessage = displayMessage
        self.type = type
    }
}

extension QRCodeError: CustomStringConvertible {
    var description: String { displayMessage }
}

extension QRCodeError: LocalizedError {
    var errorDescription: String? { description }
}
