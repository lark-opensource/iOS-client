//
//  Setting.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/1/9.
//

import Foundation
import LKCommonsTracker
import Homeric

public extension FeedTracker {
    struct Setting {}
}

public extension FeedTracker.Setting {
    /// 「全局设置页」的点击 -> 免打扰「展示提醒」开关
    static func ShowMuteRemind(status: Bool) {
        var params: [AnyHashable: Any] = [:]
        params["click"] = "show_mute_remind_toggle"
        params["target"] = "none"
        params["status"] = status ? "on" : "off"
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: params))
    }
}
