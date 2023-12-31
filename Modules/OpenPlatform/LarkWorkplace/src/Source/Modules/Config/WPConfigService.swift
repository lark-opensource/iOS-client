//
//  WPConfigService.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/5/5.
//

import Foundation
import LarkSetting

protocol WPConfigService: AnyObject {
    func fgValue(for key: WPFGKey, realTime: Bool) -> Bool

    // LarkSetting 用户态接口目前不支持 SettingDefaultDecodable 协议
    // WPConfigService 默认兼容了 SettingDefaultDecodable 协议
    // 工作台场景统一使用 SettingDefaultDecodable，要求必须含有默认值
    func settingValue<T: SettingDefaultDecodable> (
        _ type: T.Type, decodeStrategy: JSONDecoder.KeyDecodingStrategy, realTime: Bool
    ) -> T where T.Key == UserSettingKey
}

extension WPConfigService {
    func fgValue(for key: WPFGKey) -> Bool {
        return self.fgValue(for: key, realTime: false)
    }

    func settingValue<T: SettingDefaultDecodable>(
        _ type: T.Type,
        decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase
    ) -> T  where T.Key == UserSettingKey {
        return self.settingValue(type, decodeStrategy: decodeStrategy, realTime: false)
    }
}

final class WPConfigServiceImpl: WPConfigService {
    private let fgService: FeatureGatingService
    private let settingService: SettingService

    init(fgService: FeatureGatingService, settingService: SettingService) {
        self.fgService = fgService
        self.settingService = settingService
    }

    func fgValue(for key: WPFGKey, realTime: Bool) -> Bool {
        if realTime {
            return fgService.dynamicFeatureGatingValue(with: key.key)
        } else {
            return fgService.staticFeatureGatingValue(with: key.key)
        }
    }

    func settingValue<T: SettingDefaultDecodable>(
        _ type: T.Type, decodeStrategy: JSONDecoder.KeyDecodingStrategy, realTime: Bool
    ) -> T  where T.Key == UserSettingKey {
        if realTime {
            let value = try? settingService.setting(with: type, decodeStrategy: decodeStrategy)
            return value ?? T.defaultValue
        } else {
            let value = try? settingService.staticSetting(with: type, decodeStrategy: decodeStrategy)
            return value ?? T.defaultValue
        }
    }
}
