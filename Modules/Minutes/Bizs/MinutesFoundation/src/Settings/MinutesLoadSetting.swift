//
//  MinutesLoadSetting.swift
//  MinutesFoundation
//
//  Created by yangyao on 2022/10/10.
//

import Foundation
import LarkSetting

struct MinutesLoadSetting: SettingDecodable {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "vc_minutes_paging_load_setting_ios")

    let isEnable: Bool
    let pageCount: Int
    let initialPageCount: Int
}
