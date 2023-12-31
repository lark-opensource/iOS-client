//
//  MeetingRoom+ResourceStrategy.swift
//  Calendar
//
//  Created by LiangHongbin on 2022/4/15.
//

import Foundation
import RustPB

extension Rust.ResourceStrategy {

    // 会议室最大可用时长，两个自然年
    static let maxReservableDate: Date = {
        if FG.calendarRoomsReservationTime {
            var calendar = Calendar.gregorianCalendar
            calendar.timeZone = .current
            // 取当前时间的最后一秒+2年
            let furthestDate = Date().dayEnd(calendar: calendar).adding(.year, value: 2)
            return furthestDate
        }
        return Date().adding(.year, value: 2)
    }()

    var furthestBookTime: Date {
        guard hasUntilMaxDuration else {
            assertionFailure("has no such kind of strategy !")
            return Self.maxReservableDate
        }
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = TimeZone(identifier: timezone) ?? .current
        let regularBookTime = Date().dayStart(calendar: calendar).addingTimeInterval(TimeInterval(earliestBookTime))

        let hasOverRegularBookTime = Date() > regularBookTime
        let timeOffset: TimeInterval = hasOverRegularBookTime ? 0 : 24 * 60 * 60
        let furthestBookTime = Date().dayEnd(calendar: calendar).addingTimeInterval(TimeInterval(untilMaxDuration) - timeOffset)
        return furthestBookTime
    }
    
    func getAdjustEventFurthestDate(timezone: TimeZone, endDate: Date) -> Date {
        Self.adjustEventFurthestDate(originDate: furthestBookTime, timezone: timezone, endDate: endDate)
    }

    // 获取截止时间：结合endDate判断最后一天是否可预定
    static func adjustEventFurthestDate(originDate: Date, timezone: TimeZone, endDate: Date) -> Date {
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = timezone
        let instanceTimeOffset = endDate.timeIntervalSince1970 - endDate.dayStart(calendar: calendar).timeIntervalSince1970
        var furthestDate = originDate
        let roomTimeOffset = furthestDate.timeIntervalSince1970 - furthestDate.dayStart(calendar: calendar).timeIntervalSince1970
        if instanceTimeOffset >= roomTimeOffset {
            // 取当前时间前一天的最后一秒
            let new = furthestDate.dayEnd(calendar: calendar).adding(.day, value: -1)
            furthestDate = new
        }
        return furthestDate
    }
}
