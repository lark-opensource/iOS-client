//
//  CalendarWidgetModel.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/3/7.
//

import Foundation

/// Timeline Entry
public struct CalendarWidgetModel: Codable, Equatable {

    public var events: [CalendarEvent]

    public init(events: [CalendarEvent]) {
        self.events = events
    }

    public var hasEvent: Bool {
        return !validEvents.isEmpty
    }

    public var validEvents: [CalendarEvent] {
        events.filter { !$0.isExpired }
    }

    public var todayEvents: [CalendarEvent] {
        return validEvents.filter { $0.isInToday }.sortedEvents()
    }

    public var tomorrowEvents: [CalendarEvent] {
        return validEvents.filter { $0.isInTomorrow }.sortedEvents()
    }

    /// 筛选出到达某个时间仍未过期的日程
    public func getValidEvent(at time: Date) -> [CalendarEvent] {
        return events.filter { $0.expireTime > time }
    }
}

extension CalendarWidgetModel {

    public static let emptyData = CalendarWidgetModel(events: [])

    /// 未登录的Entry
    public static let notLoginModel = CalendarWidgetModel(events: [.emptyEvent])

    /// 无日程的Entry
    public static let noEventModel = CalendarWidgetModel(events: [.emptyEvent])

    /// 添加 Widget 页面的Entry
    public static let multiEventModel = CalendarWidgetModel(events: CalendarEvent.sampleEvents)
}
