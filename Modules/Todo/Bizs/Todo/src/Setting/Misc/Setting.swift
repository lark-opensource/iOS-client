//
//  Setting.swift
//  Todo
//
//  Created by 白言韬 on 2021/2/25.
//

import Foundation
import LKCommonsLogging
import LKCommonsTracker

struct Setting { }

// MARK: - Logger

extension Setting {
    static let logger = Logger.log(Setting.self, category: "Todo.Setting")
}

// MARK: - Tracker

// swiftlint:disable identifier_name
// warn: 枚举名字会被直接作为name填充，不要轻易修改
enum SettingTrackerName: String {
    case todo_daily_reminder_settings
}

extension Setting {
    static func tracker(_ name: SettingTrackerName, params: [AnyHashable: Any] = [:]) {
        Tracker.post(TeaEvent(name.rawValue, params: params))
    }
}
