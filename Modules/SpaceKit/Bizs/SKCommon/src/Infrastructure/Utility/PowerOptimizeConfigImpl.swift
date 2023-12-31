//
//  PowerOptimizeConfigImpl.swift
//  SKCommon
//
//  Created by ByteDance on 2023/11/16.
//

import Foundation
import LarkContainer
import LarkSetting
import SKInfra
import SKFoundation

final class PowerOptimizeConfigImpl {
    
    private let powerlogConfig: [String: Any]
    
    init(userResolver: UserResolver) {
        let settingService = userResolver.settings
        let settingKey = UserSettingKey.make(userKeyLiteral: "ccm_powerlog_config")
        let dict = (try? settingService.setting(with: settingKey)) ?? [:]
        self.powerlogConfig = dict
    }
}

extension PowerOptimizeConfigImpl: PowerOptimizeConfigProvider {
    
    public var evaluateJSOptEnable: Bool {
        let enable = powerlogConfig["evaluateJSOptEnable"] as? Bool
        return enable ?? false
    }
    
    public var evaluateJSOptList: [String] {
        let list = powerlogConfig["evaluateJSOptList"] as? [String]
        return list ?? []
    }
    
    public var dateFormatOptEnable: Bool {
        let enable = powerlogConfig["dateFormatOptEnable"] as? Bool
        return enable ?? false
    }
    
    public var fePkgFilePathsMapOptEnable: Bool {
        let enable = powerlogConfig["fePkgFilePathsMapOptEnable"] as? Bool
        return enable ?? false
    }
    
    public var vcPowerDowngradeEnable: Bool {
        return UserScopeNoChangeFG.CS.msDowngradeNewStrategyEnable
    }
}
