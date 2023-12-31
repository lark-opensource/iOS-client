//
//  CalendarEvent.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/3/7.
//

import Foundation

/// Widget 日程的数据model
public struct CalendarEvent: Codable, Equatable {
    public var displayTime: Date
    public var name: String
    public var subtitle: String
    public var description: String
    public var appLink: String
    public var startTime: Date
    public var endTime: Date

    public init(displayTime: Date,
                name: String,
                subtitle: String,
                description: String,
                appLink: String,
                startTime: Date,
                endTime: Date) {
        self.displayTime = displayTime
        self.name = name
        self.subtitle = subtitle
        self.description = description
        self.appLink = appLink
        self.startTime = startTime
        self.endTime = endTime
    }

    public var isAllDay: Bool {
        let duration = Int(endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970)
        let oneDaySeconds = 24 * 60 * 60
        // 时间不少于一天，且是一天的整数倍
        // NOTE: 仍然可以人为创建符合条件的非全天日程，最终解决方案是服务端添加 isAllDay 字段
        return duration >= oneDaySeconds && duration % oneDaySeconds == 0
    }

    public var isInToday: Bool {
        if startTime.isToday { return true }
        let currentTime = Date()
        if currentTime >= startTime, currentTime <= endTime { return true }
        return false
    }

    public var isInTomorrow: Bool {
        if startTime.isInTomorrow { return true }
        let tomorrowMorning = Date.nextDay
        if tomorrowMorning >= startTime, tomorrowMorning <= endTime { return true }
        return false
    }

    /// 改日程是否已开始
    public var isStarted: Bool {
        return startTime.isInPast
    }

    /// 该日程是否已过期（开始 10 分钟后视为过期，不再显示在 Widget 上）
    public var isExpired: Bool {
        // 全天日程不会过期，一直显示
        if isAllDay { return false }
        return expireTime.isInPast
    }

    /// 该日程是否已结束
    public var isFinished: Bool {
        return endTime.isInPast
    }

    /// 日程开始 10 分钟后失效不再展示
    public var expireTime: Date {
        return startTime + 10 * 60
    }

    /// 日历时间地点（会议室）
    public var eventPlace: String? {
        let trimmedPlace = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedPlace.isEmpty ? nil : trimmedPlace
    }

    public static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        guard lhs.name == rhs.name,
              lhs.subtitle == rhs.subtitle,
              lhs.description == rhs.description,
              lhs.appLink == rhs.appLink,
              lhs.startTime == rhs.startTime,
              lhs.endTime == rhs.endTime else {
            return false
        }
        return true
    }

    // 去掉日程地址
    func removePlace() -> CalendarEvent {
        var event = self
        event.description = ""
        return event
    }

    var priority: Int {
        isAllDay ? 0 : 1
    }
}

extension Array where Element == CalendarEvent {

    /// 将全天日程挪到非全天日程之后
    func sortedEvents() -> [Element] {
        return sorted { event1, event2 in
            event1.priority > event2.priority
        }
    }
}

extension CalendarEvent {

    /// 默认Event
    public static let emptyEvent = CalendarEvent(displayTime: Date(),
                                                 name: "",
                                                 subtitle: "",
                                                 description: "",
                                                 appLink: WidgetLink.calendarTab,
                                                 startTime: Date(),
                                                 endTime: Date())
    /// 添加Widget界面展示的Event
    static let snapShotEvent = CalendarEvent(displayTime: Date(),
                                             name: "Widget Sample Event 1",
                                             subtitle: "10:00-11:30",
                                             description: "F2-01 Zhonghang",
                                             appLink: WidgetLink.applinkHost,
                                             startTime: Date().addingTimeInterval(-1000),
                                             endTime: Date().addingTimeInterval(1000))

    static let sampleEvents = [
        CalendarEvent(displayTime: Date(),
                      name: "Widget Sample Event 1",
                      subtitle: "10:00-11:30",
                      description: "F2-01 Zhonghang",
                      appLink: WidgetLink.applinkHost,
                      startTime: Date().addingTimeInterval(-1000),
                      endTime: Date().addingTimeInterval(1000)),
        CalendarEvent(displayTime: Date(),
                      name: "Widget Sample Event 2",
                      subtitle: "11:00-12:30",
                      description: "F8-16 Weishi",
                      appLink: WidgetLink.applinkHost,
                      startTime: Date().addingTimeInterval(-1000),
                      endTime: Date().addingTimeInterval(1000)),
        CalendarEvent(displayTime: Date(),
                      name: "Widget Sample Event 3",
                      subtitle: "14:00-15:00",
                      description: "F8-16 Weishi",
                      appLink: WidgetLink.applinkHost,
                      startTime: Date().addingTimeInterval(-1000),
                      endTime: Date().addingTimeInterval(1000)),
        CalendarEvent(displayTime: Date(),
                      name: "Widget Sample Event 4",
                      subtitle: "19:00-20:00",
                      description: "F8-16 Weishi",
                      appLink: WidgetLink.applinkHost,
                      startTime: Date().addingTimeInterval(-1000),
                      endTime: Date().addingTimeInterval(1000))
    ]
}
