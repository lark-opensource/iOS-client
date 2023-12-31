//
//  ZeroTrustConfig.swift
//  ZeroTrust
//
//  Created by kongkaikai on 2020/11/2.
//

import Foundation

/// 一些通用配置Key
public struct ZeroTrustConfig {
    /// Seal零信任网络安全证书
    public static var zeroTrustFeatureGatingKey: String { "lark.browser.security.sealcert" }

    private static let fixedTenantID = "1"

    /// 读取SettingV3的配置的Key
    @inline(__always)
    static let supportHostSettingV3Key = "seal_certificate_config"

    /// 读取SettingV3的配置的Key, 租户配置的Key
    /// - Parameter tenantID: 租户ID
    /// - Returns: 租户的Hosts配置Key
    @inline(__always)
    static func supportHostTenantKey(with tenantID: String) -> String {
        "seal_certificate_trust_host_\(tenantID)"
    }

    @inline(__always)
    static var fixedSupportHostTenantKey: String {
        supportHostTenantKey(with: fixedTenantID)
    }

    /// 存到本地UserDefault的key
    /// - Parameter tenantID: 租户ID
    /// - Returns: UserDefaultKey
    @inline(__always)
    static func supportHostUserSpaceKey(with tenantID: String) -> String {
        "zero_trust_seal_certificate_support_host_key_\(tenantID)"
    }

    /// 存P12的Label
    /// - Parameter tenantID: 租户ID
    /// - Returns: Label string
    @inline(__always)
    static func saveP12Label(with tenantID: String) -> String {
        "zero_trust_seal_cert_\(tenantID)"
    }

    // 存到本地UserDefault，一期由于初始化时序问题改成固定Key
    // lint:disable lark_storage_check
    public static var fixedSupportHost: [String]? {
        get {
            let key = supportHostUserSpaceKey(with: fixedTenantID)
            return UserDefaults.standard.array(forKey: key) as? [String]
        }
        set {
            let key = supportHostUserSpaceKey(with: fixedTenantID)
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
    // lint:enable lark_storage_check

    /// 存P12的Label，一期由于初始化时序问题改成固定Key
    @inline(__always)
    public static var fixedSaveP12Label: String {
        saveP12Label(with: fixedTenantID)
    }
}
