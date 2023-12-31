//
//  WidgetData.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/3/15.
//

import Foundation

public struct WidgetData: Codable, Equatable {

    public var isMinimumMode: Bool
    public var isLogin: Bool
    public var events: [CalendarEvent]
    public var actions: [TodayWidgetAction]

    /// 从 events 中过滤出当日有效的日程
    public var todayEvents: [CalendarEvent] {
        return events.filter {
            $0.startTime.isToday && !$0.expireTime.isInPast
        }
    }

    public init(isMinimumMode: Bool, isLogin: Bool, events: [CalendarEvent], actions: [TodayWidgetAction]) {
        self.isMinimumMode = isMinimumMode
        self.isLogin = isLogin
        self.events = events
        self.actions = actions
    }

    public init(events: [CalendarEvent], actions: [TodayWidgetAction]) {
        self.init(isMinimumMode: false, isLogin: true, events: events, actions: actions)
    }

    public static var minimumModeData: WidgetData {
        return WidgetData(isMinimumMode: true, isLogin: false, events: [.emptyEvent], actions: [])
    }

    public static var notLoginData: WidgetData {
        return WidgetData(isMinimumMode: false, isLogin: false, events: [.emptyEvent], actions: [])
    }
}

public extension Date {

    /// 判断当前日期是否在今天
    public var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// 判断当前日期是否在昨天
    public var isInYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }

    /// 判断当前日期是否在明天
    public var isInTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }

    /// 判断当前日期是否是过去
    public var isInPast: Bool {
        return self < Date()
    }

    /// 获取明天的 Date 实例
    public static var nextDay: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: morning) ?? Date()
    }

    private static var morning: Date {
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 1, of: Date()) ?? Date()
    }
}
