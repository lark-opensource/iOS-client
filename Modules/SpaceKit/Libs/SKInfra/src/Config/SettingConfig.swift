//
//  SettingConfig.swift
//  SKInfra
//
//  Created by huangzhikai on 2023/4/13.
//  从SettingConfig+base

import Foundation
import LarkSetting

public enum SettingConfig {
    //    @Setting(key: "offline_res_interval")
    public static var offlineResourceUpdateInterval: Int? {
        return try? SettingManager.shared.setting(with: Int.self, key: UserSettingKey.make(userKeyLiteral: "offline_res_interval"))
    }
    
    public static var grayscalePackageConfig: [String: Any]? {
        return try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "grayscale_package_config"))
    }
    
    @Setting(.useDefaultKeys)
    public static var resourcePkgConfig: ResourcePkgConfig?
    
    @Setting(.useDefaultKeys)
    public static var larkAuthConfig: LarkAuthConfig?

}

public struct ResourcePkgConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "ccm_resource_pkg_config")

    enum CodingKeys: String, CodingKey {
        case clearEnable = "clear_enable"
        case version = "version"
        case recreatePkgWhenError = "recreate_pkg_when_error"
        
    }

    public let clearEnable: Bool
    public let version: String
    public let recreatePkgWhenError: Bool
    
}

public struct LarkAuthConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "lark_authn")
    public let realNameAuthURL: URL
    public let tenantAuthURL: URL
    enum CodingKeys: String, CodingKey {
        case realNameAuthURL = "real_name_authn_url"
        case tenantAuthURL = "lark_authn_url_mobile"
    }
}
