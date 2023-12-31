//
//  AccountService.swift
//  ShareExtension
//
//  Created by Supeng on 2021/4/8.
//

import Foundation

public enum ExtensionAccountService {
    public static var isLogin: Bool {
        (currentAccountID != nil) && (currentAccountSession != nil)
    }

    public static var currentAccountID: String? {
        try? SecureUserDefaults.shared.value(with: .currentAccountID)
    }

    public static var currentAccountSession: String? {
        try? SecureUserDefaults.shared.value(with: .currentAccountSession)
    }

    public static func getUserDao(_ userId: String) -> UserDao? {
        return GlobalUserService.shared.getUserDao(userId: userId)
    }

    public static func getUserSession(_ userId: String) -> String? {
        let session = Self.getUserDao(userId)?.session
        if (session == nil || session?.count == 0) && userId == Self.currentAccountID {
            /// 如果session为空，做好兜底逻辑
            return Self.currentAccountSession
        }
        return session
    }

    public static func getUserTenantId(_ userId: String) -> String? {
        return Self.getUserDao(userId)?.tenantId
    }

    public static func getUserDeviceId(_ userId: String) -> String? {
        if  let unit = Self.getUserDao(userId)?.unit {
            return GlobalUserService.shared.getDeviceIdAndInstallId(unit: unit)?.0
        }
        return nil
    }

    public static func getUserInstallId(_ userId: String) -> String? {
        if  let unit = Self.getUserDao(userId)?.unit {
            return GlobalUserService.shared.getDeviceIdAndInstallId(unit: unit)?.1
        }
        return nil
    }

    public static func getUserUniqueId(_ userId: String) -> String? {
        return Self.getUserDao(userId)?.encryptedUserId
    }

    public static var currentUserAgent: String? {
        try? SecureUserDefaults.shared.value(with: .currentUserAgent)
    }

    public static var currentDeviceID: String? {
        try? SecureUserDefaults.shared.value(with: .currentDeviceID)
    }

    public static var currentTenentID: String? {
        try? SecureUserDefaults.shared.value(with: .currentTenentID)
    }

    public static var currentInstallID: String? {
        try? SecureUserDefaults.shared.value(with: .currentInstallID)
    }

    public static var currentUserUniqueID: String? {
        try? SecureUserDefaults.shared.value(with: .currentUserUniqueID)
    }

    public static var currentAPPVersion: String? {
        try? SecureUserDefaults.shared.value(with: .currentAPPVersion)
    }
}
