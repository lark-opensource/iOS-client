//
//  AppConfig.swift
//  Calendar
//
//  Created by zhuheng on 2021/5/28.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import SuiteAppConfig

@propertyWrapper
struct GlobalConfig {
    private let key: String
    private let debugValue: Bool
    @Provider var appConfigService: AppConfigService
    public init(_ key: String, debugValue: Bool) {
        self.key = key
        self.debugValue = debugValue
    }

    public var wrappedValue: Bool {
        #if DEBUG
        return debugValue
        #else
        return appConfigService.feature(for: key).isOn
        #endif
    }
}

enum AppConfig {
    @GlobalConfig("event.chat", debugValue: true) static var detailChat: Bool
    @GlobalConfig("event.video", debugValue: true) static var detailVideo: Bool
    @GlobalConfig("event.minutes", debugValue: true) static var detailMinutes: Bool
    @GlobalConfig("event.description", debugValue: true) static var eventDesc: Bool
    @GlobalConfig("event.attachment", debugValue: true) static var eventAttachment: Bool
    @GlobalConfig("event.reminder", debugValue: true) static var calendarAlarm: Bool
}
