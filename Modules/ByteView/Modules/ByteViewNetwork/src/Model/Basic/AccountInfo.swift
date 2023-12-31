//
//  AccountInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2023/6/1.
//

import Foundation

/// 账号信息
public protocol AccountInfo {
    /// 用户id
    var userId: String { get }
    /// 设备id
    var deviceId: String { get }
    /// 用户名
    var userName: String { get }
    /// 租户类型
    var tenantTag: TenantTag? { get }
    /// 租户id
    var tenantId: String { get }
    /// 用户的access token
    var accessToken: String { get }
    /// 是否是游客
    var isGuest: Bool { get }
    /// 是否是前台用户
    var isForegroundUser: Bool { get }

    var isFeishuBrand: Bool { get }

    var isChinaMainlandGeo: Bool { get }
}

public extension AccountInfo {
    var user: ByteviewUser {
        return ByteviewUser(id: userId, type: .larkUser, deviceId: deviceId)
    }

    /// 是否外部租户
    func isExternal(tenantId: String?) -> Bool {
        return canShowExternal ? self.tenantId != tenantId : false
    }

    /// 小B用户不显示外部标签
    var canShowExternal: Bool {
        if let tenantTag = self.tenantTag, tenantTag != .standard {
            return false // 小B用户不显示外部标签
        } else {
            return true
        }
    }
}
