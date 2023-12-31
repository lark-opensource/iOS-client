//
//  SettingPushHandler.swift
//  LarkSetting
//
//  Created by Supeng on 2021/6/28.
//

import Foundation
import RustPB
import LarkRustClient
import LarkAccountInterface
import LarkEnv

final class SettingPushHandler: UserPushHandler {
    func process(push message: Settings_V1_PushUserSettingsUpdated) throws {
        SettingStorage.settingDatasource?.fetchSetting(resolver: userResolver)
    }
}
