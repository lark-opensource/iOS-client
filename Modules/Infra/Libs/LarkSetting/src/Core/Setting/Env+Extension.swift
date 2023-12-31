//
//  Env+Extension.swift
//  LarkSetting
//
//  Created by 王元洵 on 2022/4/15.
//

import Foundation
import LarkReleaseConfig
import LarkEnv
import LarkAccountInterface
import LarkContainer

extension Env {
    /// setting描述，MultiGeo以后，适配brand
    var settingDescription: String { Self.settingDescription(type: type, unit: unit, brand: brand) }

    /// 兼容MultiGeo之前的逻辑，不拼接brand信息
    var legacySettingDescription: String { Self.settingDescription(type: type, unit: unit, brand: nil) }

    static func settingDescription(type: Env.TypeEnum, unit: String, brand: String?) -> String {
        ReleaseConfig.kaDeployMode != .saas ? ""
        : {
            guard let brand = brand else { return "\(type.domainKey)_\(unit)" }
            return "\(type.domainKey)_\(unit)_\(brand)"
        }()
    }

    var brand: String { SettingBrand().passportService.tenantBrand.rawValue }
}

struct SettingBrand {
    @Provider var passportService: PassportService
}
