//
//  File.swift
//  LarkAccountInterface
//
//  Created by Yiming Qu on 2020/8/9.
//

import Foundation
import EENavigator

public struct SimplifyLoginBody: PlainBody {

    public static let pattern = "//client/account/simplify/login"

    public let userName: String?

    public init(userName: String? = nil) {
        self.userName = userName
    }
}

public struct GuestLoginBody: PlainBody {

    public static let pattern = "//client/account/guest/login"

    public let userName: String?

    public init(userName: String? = nil) {
        self.userName = userName
    }
}

/// 账号管理：登录凭证修改
public struct AccountManagementBody: PlainBody {
    public static let pattern = "//client/passport/account_management"

    public init() {}
}

/// 登录设备管理
public struct MineAccountBody: CodablePlainBody {
    public static let pattern = "//client/mine/account"

    public init() {}
}

public struct SSOVerifyBody: CodablePlainBody {

    public static let pattern: String = "//client/verify"

    public let qrCode: String
    public let bundleId: String
    public let schema: String

    public init(qrCode: String, bundleId: String, schema: String) {
        self.qrCode = qrCode
        self.bundleId = bundleId
        self.schema = schema
    }
}
