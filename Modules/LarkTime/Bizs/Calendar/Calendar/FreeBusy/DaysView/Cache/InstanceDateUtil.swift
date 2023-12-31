//
//  InstanceDateUtil.swift
//  Calendar
//
//  Created by zhuheng on 2020/7/8.
//

import Foundation
import CalendarFoundation

final class InstanceDateUtil {
    static func getJulianDays(start: Date, end: Date, timeZoneId: String? = nil) -> Set<Int32> {
        let calendar = TimeZoneUtil.getCalendar(timeZoneId: timeZoneId)
        let startJulianDay = getJulianDay(date: start, calendar: calendar)
        let endJulianDay = getJulianDay(date: end, calendar: calendar)
        var days: Set<Int32> = Set()
        for day in startJulianDay...endJulianDay {
            days.insert(day)
        }
        return days
    }

}
