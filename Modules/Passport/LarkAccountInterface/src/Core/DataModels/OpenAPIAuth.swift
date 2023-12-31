//
//  OpenAPIAuth.swift
//  LarkAccountInterface
//
//  Created by au on 2023/6/6.
//

import Foundation

public typealias OpenAPIAuthResult = Result<OpenAPIAuthPayload, OpenAPIAuthError>

public struct OpenAPIAuthParams: Codable {

    /// REQUIRED: 应用的唯一ID，在开发者后台-凭证和基础信息中可以获得
    public let appID: String

    /// 为由空格分隔的需要用户授权的三方应用权限
    public let scope: String?

    /// 用来维护请求和回调状态的附加字符串，在授权完成回调时会附加此参数，应用可以根据此字符串来判断上下文关系
    public let state: String?

    /// 应用配置的回调地址，端内网页应用发起的授权的时候需要检验发起地址和配置是否一致
    public let redirectUri: String?

    /// 开平应用类型 1=小程序 2=端内网页 3=小组件
    public let openAppType: Int?

    public init(appID: String, scope: String? = nil, state: String? = nil, redirectUri: String? = nil, openAppType: Int? = nil) {
        self.appID = appID
        self.scope = scope
        self.state = state
        self.redirectUri = redirectUri
        self.openAppType = openAppType
    }

    public var logDescription: String {
        let contents: [String: String] = [
            "appID": appID,
            "scope": scope ?? "",
            "state": state ?? "",
            "redirectUri": redirectUri ?? "",
            "openAppType": "\(openAppType ?? -1)"
        ]
        return contents.description
    }
}

/// 授权成功信息
public struct OpenAPIAuthPayload {

    public let code: String
    public let message: String?
    public let isAutoConfirm: Bool
    public let state: String?
    public let extra: [String: Any]?

    public init(code: String, message: String?, isAutoConfirm: Bool, state: String?, extra: [String: Any]?) {
        self.code = code
        self.message = message
        self.isAutoConfirm = isAutoConfirm
        self.state = state
        self.extra = extra
    }
}

/// 授权错误信息
public struct OpenAPIAuthErrorInfo {

    public let code: Int
    public let message: String

    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
}

public enum OpenAPIAuthError: Error {
    case error(OpenAPIAuthErrorInfo)
}
