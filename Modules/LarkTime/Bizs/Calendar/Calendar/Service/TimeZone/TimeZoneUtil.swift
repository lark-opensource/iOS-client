//
//  TimeZoneUtil.swift
//  Calendar
//
//  Created by 张威 on 2020/2/19.
//

import Foundation
import CalendarFoundation

extension TimeZoneUtil {

    public static let HiddenOffsetFlag = -1

    /// 根据多个 TimeZones，返回它们的 Offset，TimeZone 和 Offset 是多对一的关系
    ///
    /// - Parameter timeZones: time zones
    /// - Parameter date: date
    static func groupedGmtOffset(for timeZones: [TimeZoneModel?], with date: Date = Date()) -> Set<Int> {
        var set = Set<Int>()
        for timeZone in timeZones {
            if let timeZone = timeZone {
                set.insert(timeZone.getSecondsFromGMT(date: date))
            } else {
                set.insert(HiddenOffsetFlag)
            }
        }
        return set
    }

    static func areTimezonesDifferent(timezones: [TimeZone]) -> Bool {
        let group = groupedGmtOffset(for: timezones).filter { $0 != TimeZoneUtil.HiddenOffsetFlag }
        return group.count > 1
    }

}
