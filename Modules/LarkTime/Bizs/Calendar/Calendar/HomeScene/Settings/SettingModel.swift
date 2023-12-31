//
//  SettingModel.swift
//  Calendar
//
//  Created by zc on 2018/5/17.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import RustPB
import LarkLocalizations

typealias CalendarSkinType = SkinSetting.SkinType
typealias CalendarAlphaType = SkinSetting.AlphaType

extension CalendarSkinType {
    var rawValue: String {
        return self == .light
            ? BundleI18n.Calendar.Calendar_Settings_Modern
            : BundleI18n.Calendar.Calendar_Settings_Classic
    }
}

extension AlternateCalendarEnum {
    func toString() -> String {
        switch self {
        case .noneCalendar:
            return BundleI18n.Calendar.Calendar_Alternate_No
        case .chineseLunarCalendar:
            return BundleI18n.Calendar.Calendar_Alternate_Chinese
        @unknown default:
            return ""
        }
    }
}

/// 视图页直接用到的设置项
protocol EventViewSetting {
    /// 过去日程是否显示蒙白
    var showCoverPassEvent: Bool { get set }
    /// 深浅皮肤类型
    var skinTypeIos: CalendarSkinType { get set }
    /// 周几开始
    var firstWeekday: DaysOfWeek { get set }
    /// 辅助日历
    var alternateCalendar: AlternateCalendarEnum? { get set }
    var defaultAlternateCalendar: AlternateCalendarEnum { get }
    /// 辅助时区列表
    var additionalTimeZones: [String] { get set }
}

extension EventViewSetting {

    /// 是否需要刷新视图页
    ///
    /// - Parameter newValue: 新的setting
    func shouldUpdateEventView(_ newValue: EventViewSetting) -> Bool {
        return self.showCoverPassEvent != newValue.showCoverPassEvent ||
        self.skinTypeIos != newValue.skinTypeIos ||
        self.firstWeekday != newValue.firstWeekday ||
        self.isAlternateCalendarActive != newValue.isAlternateCalendarActive ||
        self.additionalTimeZones != newValue.additionalTimeZones
    }

    // 备选日历是否激活
    var isAlternateCalendarActive: Bool {
        (alternateCalendar ?? self.defaultAlternateCalendar) != .noneCalendar
    }

}

/// 日历总的设置
protocol Setting: EventViewSetting {
    var defaultAllDayReminder: Int32 { get set }
    var defaultNoneAllDayReminder: Int32 { get set }

    var showRejectSchedule: Bool { get set }
    // 是否 拒绝的日程不提醒
    var remindNoDecline: Bool { get set }
    // 有人拒绝日程邀请时是否通知
    var notifyWhenGuestsDecline: Bool { get set }
    var defaultEventDuration: Int32 { get set }
    var allDayReminder: Reminder? { get }
    var noneAllDayReminder: Reminder? { get }
    // 是否导入谷歌日历
    var googleCalbinded: Bool { get }
    var googleCalAccount: String { get }
    var workHourSetting: WorkHourSetting { get set }
    var hasSelectableEmailAddress: Bool { get }
    var timeZone: String { get }
    var useSystemTimeZone: Bool { get }
    var isPCHasSubTimeZone: Bool { get }
    var guestPermission: GuestPermission? { get set }
    // 辅助时区列表
    var additionalTimeZones: [String] { get set }
    // feed是否将事件feed置顶
    var feedTopEvent: Bool { get set }
    func getPB() -> CalendarSetting

    init()
    init(pb: CalendarSetting)
}

private let keyOfAlternateCalendarDefaultMap = [Lang.zh_CN: "Chinese"]

struct SettingModel: Setting {

    private var alternateCalendarDefaultMap: AlternateCalendarDefaultMap {
        get { return self.pb.calendarSettingConfig }
    }

    var defaultAlternateCalendar: AlternateCalendarEnum {
        get {
            guard let key = keyOfAlternateCalendarDefaultMap[LanguageManager.currentLanguage],
               let value = alternateCalendarDefaultMap.langAlternateCalendarMap[key]
               else {
                   return .noneCalendar
            }
            return value
        }
    }

    var alternateCalendar: AlternateCalendarEnum? {
        get {
            if self.pb.hasAlternateCalendar {
                return self.pb.alternateCalendar
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self.pb.alternateCalendar = newValue
            }
        }
    }

    /// 移动端normal视图时区设置，如果为空表示使用设备时区
    var timeZone: String {
        return self.pb.mobileNormalViewTimezone
    }

    /// mobile normal view 是否使用系统时区，若是，忽略mobile_normal_view_timezone字段
    var useSystemTimeZone: Bool {
        return self.pb.useSystemTimezoneInMobileNormalView
    }

    var googleCalAccount: String {
        return self.pb.googleCalendarEmail
    }

    var googleCalbinded: Bool {
        return self.pb.bindGoogleCalendar
    }

    var firstWeekday: DaysOfWeek {
        get { return DaysOfWeek.fromPB(pb: self.pb.weekStartDay) }
        set { self.pb.weekStartDay = newValue.toPb() }
    }

    var skinTypeIos: CalendarSkinType {
        get { return self.pb.skinTypeIos }
        set { self.pb.skinTypeIos = newValue }
    }

    var remindNoDecline: Bool {
        get { return self.pb.remindNoDecline }
        set { self.pb.remindNoDecline = newValue }
    }

    var guestPermission: GuestPermission? {
        get { return self.pb.guestPermission }
        set {
            guard let permission: GuestPermission = newValue else { return }
            let canModify = permission >= .guestCanModify
            let canInvite = permission >= .guestCanInvite
            let canSeeOther = permission >= .guestCanSeeOtherGuests
            self.pb.calendarEventEditSetting.guestCanModify = canModify
            self.pb.calendarEventEditSetting.guestCanInvite = canInvite
            self.pb.calendarEventEditSetting.guestCanSeeOtherGuests = canSeeOther
        }
    }

    var notifyWhenGuestsDecline: Bool {
        get { return self.pb.notifyWhenGuestsDecline }
        set { self.pb.notifyWhenGuestsDecline = newValue }
    }

    var defaultAllDayReminder: Int32 {
        get { return self.pb.defaultAllDayReminder }
        set { self.pb.defaultAllDayReminder = newValue }
    }

    var defaultNoneAllDayReminder: Int32 {
        get { return self.pb.defaultNoneAllDayReminder }
        set { self.pb.defaultNoneAllDayReminder = newValue }
    }

    var showCoverPassEvent: Bool {
        get { return pb.showPastEventsMaskIos }
        set { pb.showPastEventsMaskIos = newValue }
    }

    var showRejectSchedule: Bool {
        get { return self.pb.showRejectedSchedule }
        set { self.pb.showRejectedSchedule = newValue }
    }

    var defaultEventDuration: Int32 {
        get { return self.pb.defaultEventDurationV2 }
        set { self.pb.defaultEventDurationV2 = newValue }
    }

    var allDayReminder: Reminder? {
        let mintues = Int32(self.defaultAllDayReminder)
        if mintues == -1 {
            return nil
        }
        return Reminder(minutes: mintues, isAllDay: true)
    }

    var noneAllDayReminder: Reminder? {
        let mintues = Int32(self.defaultNoneAllDayReminder)
        if mintues == -1 {
            return nil
        }
        return Reminder(minutes: mintues, isAllDay: false)
    }

    private var _additionalTimeZones: [String] = []

    var additionalTimeZones: [String] {
        get {
            _additionalTimeZones
        }
        set { 
            self.pb.otherTimezones = newValue
            _additionalTimeZones = removeSameAdditionalTimeZones(otherTimeZones: pb.otherTimezones)
        }
    }

    // feed是否将事件feed置顶
    var feedTopEvent: Bool = false

    typealias WorkHourSetting = RustPB.Calendar_V1_WorkHourSetting
    typealias WorkHourSpan = RustPB.Calendar_V1_WorkHourSpan
    var workHourSetting: WorkHourSetting {
        get { return pb.workHourSetting }
        set { pb.workHourSetting = newValue }
    }

    private var pb: CalendarSetting

    init(pb: CalendarSetting) {
        self.pb = pb
        self._additionalTimeZones = removeSameAdditionalTimeZones(otherTimeZones: pb.otherTimezones)
    }

    init() {
        self.pb = CalendarSetting()
    }

    func getPB() -> CalendarSetting {
        return self.pb
    }

    private func removeSameAdditionalTimeZones(otherTimeZones: [String]) -> [String] {
        var map: [String: Int] = [:]
        return otherTimeZones.filter { timeZone in
            guard map[timeZone] == nil else { return false }
            map[timeZone] = 1
            return true
        }
    }

    var hasSelectableEmailAddress: Bool { false }

    var isPCHasSubTimeZone: Bool {
        return self.pb.showOtherTimezone && !self.pb.otherTimezones.isEmpty
    }
}

var defaultWorkHourSetting = WorkHourSetting()
func setDefaultWorkHourSetting() {
    defaultWorkHourSetting.enableWorkHour = false
    var span = WorkHourSpan()
    span.startMinute = 540
    span.endMinute = 1260
    var workHourItem = WorkHourItem()
    workHourItem.spans = [span]
    defaultWorkHourSetting.workHourItems
        = ["1": workHourItem,
           "2": workHourItem,
           "3": workHourItem,
           "4": workHourItem,
           "5": workHourItem]
}
