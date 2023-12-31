//
//  CCMSettings.swift
//  SKFoundation
//
//  Created by ByteDance on 2023/7/26.
//

import Foundation
import LarkContainer
import LarkSetting

public extension CCMExtension where Base == UserResolver {

    func dynamicSetting<T: Decodable>(_ key: UserSettingKey, decodeStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) -> T? {
        let value: T? = try? base.settings.setting(with: T.self, key: key, decodeStrategy: decodeStrategy)
        return value
    }

    func staticSetting<T: Decodable>(_ key: UserSettingKey, decodeStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) -> T? {
        let value: T? = try? base.settings.staticSetting(with: T.self, key: key, decodeStrategy: decodeStrategy)
        return value
    }

    func dynamicRawSetting(_ key: UserSettingKey) -> [String: Any]? {
        let value = try? base.settings.setting(with: key)
        return value
    }

    func staticRawSetting(_ key: UserSettingKey) -> [String: Any]? {
        let value = try? base.settings.staticSetting(with: key)
        return value
    }
}

public struct CCMSettingKeys {
    
    public static let ios17CompatibleConfig = "ccm_ios17_compatible_config"
    
    public struct CS {
        //public static let ios17CompatibleConfig = "ccm_ios17_compatible_config"
    }
}
