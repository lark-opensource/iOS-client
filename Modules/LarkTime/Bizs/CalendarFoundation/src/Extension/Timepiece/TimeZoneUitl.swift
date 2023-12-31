//
//  TimeZoneUtil.swift
//  Calendar
//
//  Created by sunxiaolei on 2020/2/12.
//

import Foundation

public final class TimeZoneUtil {
    public class func getCalendar(timeZoneId: String?) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let timeZoneId = timeZoneId {
            calendar.timeZone = TimeZone(identifier: timeZoneId) ?? TimeZone.current
        }
        return calendar
    }

    // 将srcDate在srcTz下的年月日时分秒日期信息，转换为destTz下对应的时间
    public class func dateTransForm(srcDate: Date, srcTzId: String, destTzId: String) -> Date {
        if srcTzId == destTzId {
            return srcDate
        }
        let dateComponents = getCalendar(timeZoneId: srcTzId).dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: srcDate)

        return getCalendar(timeZoneId: destTzId).date(from: dateComponents) ?? srcDate
    }

    // 将srcDay的日期改成destDay日期，时分秒信息不变
    public class func changeDateDay(srcDay: Date, tzId: String, destDay: Date) -> Date? {
        let calendar = getCalendar(timeZoneId: tzId)
        let srcDateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: srcDay)
        var destDateCompents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: destDay)

        destDateCompents.hour = srcDateComponents.hour
        destDateCompents.minute = srcDateComponents.minute
        destDateCompents.second = srcDateComponents.second
        destDateCompents.nanosecond = srcDateComponents.nanosecond

        return calendar.date(from: destDateCompents)
    }
}
