//
//  TimeIntervalRange.swift
//  Calendar
//
//  Created by Miao Cai on 2020/8/31.
//

import Foundation

// MARK: Limited Time Meeting Room Reservation Support
struct TimeIntervalRange {
    public var startDate: Date
    public var endDate: Date

    init(from startDate: Date, to endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }

    func isSubinterval(of other: TimeIntervalRange) -> Bool {
        return other.startDate <= self.startDate && self.endDate <= other.endDate
    }

    func intersection(_ other: TimeIntervalRange) -> TimeIntervalRange? {
        guard self.startDate < self.endDate, other.startDate < other.endDate else {
            assertionFailure("Date Range Invaild")
            return nil
        }
        // 是否是内含
        if self.isSubinterval(of: other) {
            return self
        } else if other.isSubinterval(of: self) {
            return other
        } else if self.endDate <= other.startDate || other.endDate <= self.startDate {
            // 无交集
            return nil
        } else if self.startDate <= other.startDate,
            self.endDate >= other.startDate,
            self.endDate <= other.endDate {
            return TimeIntervalRange(from: other.startDate, to: self.endDate)
        } else {
            return TimeIntervalRange(from: self.startDate, to: other.endDate)
        }
    }

    func splitedBy(
        startTime: TimeInterval,
        endTime: TimeInterval,
        timeZone: TimeZone
    ) -> [TimeIntervalRange] {
        var timeIntervalRanges = [TimeIntervalRange]()
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = timeZone
        let startOfDay = calendar.startOfDay(for: self.startDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        let rangeSinceStartDateToEndOfThatDay = TimeIntervalRange(
            from: self.startDate,
            to: endOfDay
        )
        let requiredRangeFromDate = self.startDate.convertedToTimeIntervalRangeBy(
            startTime: startTime,
            endTime: endTime,
            timeZone: timeZone
        )
        if let dateRange = rangeSinceStartDateToEndOfThatDay.intersection(requiredRangeFromDate) {
            timeIntervalRanges.append(dateRange)
        }
        if endOfDay < self.endDate {
            let startOfNextDay = calendar.startOfDay(for: self.endDate)
            let rangeSinceStartOfNextDayToEndDate = TimeIntervalRange(
                from: startOfNextDay,
                to: self.endDate
            )
            let requiredRangeFromDate = self.endDate.convertedToTimeIntervalRangeBy(
                startTime: startTime,
                endTime: endTime,
                timeZone: timeZone
            )
            if let dateRange = rangeSinceStartOfNextDayToEndDate.intersection(requiredRangeFromDate) {
                timeIntervalRanges.append(dateRange)
            }
        }
        return timeIntervalRanges
    }
}

extension TimeIntervalRange: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate
    }
}

fileprivate extension Date {
    // 用于做时间戳转换: 在当前开始时间对应的其他时区下, 根据给定的开始和结束时间偏移量,计算对应时间戳区间
    func convertedToTimeIntervalRangeBy(
        startTime: TimeInterval,
        endTime: TimeInterval,
        timeZone: TimeZone) -> TimeIntervalRange {
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = timeZone
        let startOfDay = calendar.startOfDay(for: self)
        return TimeIntervalRange(
            from: startOfDay.addingTimeInterval(startTime),
            to: startOfDay.addingTimeInterval(endTime)
        )
    }
}
