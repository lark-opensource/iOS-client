//
//  SettingConfig+Permission.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/19.
//

import Foundation
import SKInfra
import LarkSetting

extension SettingConfig {
    static var retentionDomainConfig: String? {
        return DomainSettingManager.shared.currentSetting["scs_data"]?.first
    }
}
