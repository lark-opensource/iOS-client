//
//  JulianDayUtil.swift
//  CTFoundation
//
//  Created by 张威 on 2020/8/3.
//

import Foundation
import EventKit

//swiftlint:disable identifier_name
//swiftlint:disable missing_docs

public typealias JulianDay = Int
public typealias JulianDayRange = Range<JulianDay>

/// Utils about Julian Day
///
/// JulianDayUtil 的相关方法计算，基于 gregorian calendar 完成
/// - See Also: https://en.wikipedia.org/wiki/Julian_day

public struct JulianDayUtil {

    public typealias TimeZoneIdentifier = String

    /// UTC 时间戳，单位为秒
    public typealias Timestamp = Int64

    static private let calendar = Calendar(identifier: .gregorian)

    /// 1900 年第一天（1900 年 01 月 01 日）的 julianDay
    public static let julianDayFrom1900_01_01: JulianDay = julianDay(fromYear: 1900, month: 1, day: 1)
    /// 2000 年第一天（2000 年 01 月 01 日）的 julianDay
    public static let julianDayFrom2000_01_01: JulianDay = julianDay(fromYear: 2000, month: 1, day: 1)
    /// 2100 年第一天（2100 年 01 月 01 日）的 julianDay
    public static let julianDayFrom2100_01_01: JulianDay = julianDay(fromYear: 2100, month: 1, day: 1)

    private static let secondsPerDay = Int64(86_400)
    private static var unfairLock = os_unfair_lock_s()

    /// Some timeZones that do not observe daylight saving time
    /// Ref: https://docs.microsoft.com/en-us/outlook/troubleshoot/calendaring/time-zones-that-do-not-observe-daylight-saving-time
    /// 对于一些没有夏令时的时区，计算 startOfDay、julianDay 时，基于 base julian day 做一些优化，性能更好；
    /// 此处只包含部分「没有夏令时」的时区，不是全部，不是全部，不是全部！
    public static let someTimeZoneIdentifiersThatDoNotObserveDaylightSavingTime: Set<String> = [
        "Asia/Shanghai",
        "Asia/Chongqing",
        "Asia/Urumqi",
        "Asia/Taipei",
        "Asia/Hong_Kong",
        "Asia/Macau",
        "Asia/Tokyo"
    ]

    /// 基准 day (2000.01.01) 在不同时区下的开始时间戳
    private static var baseDayStartTimestamps = [TimeZoneIdentifier: Timestamp]()

    private static var weekdayFrom1900_01_01 = (_weekday(from: julianDayFrom1900_01_01) ?? .monday).rawValue

    /// 根据 year, month, day 计算 julianDay
    ///
    /// - parameter year: year number
    /// - parameter month: month number
    /// - parameter day: day number
    /// - returns: julian day
    public static func julianDay(fromYear year: Int, month: Int, day: Int) -> JulianDay {
        return (1461 * (year + 4800 + (month - 14) / 12)) / 4
            + (367 * (month - 2 - 12 * ((month - 14) / 12))) / 12
            - (3 * ((year + 4900 + (month - 14) / 12) / 100)) / 4
            + day - 32_075
    }

    /// 根据 date 计算 julian day
    ///
    /// - parameter date: date
    /// - parameter timeZone: timeZone
    /// - returns: julian day
    public static func julianDay(from date: Date, in timeZone: TimeZone) -> JulianDay {
        return julianDay(from: Timestamp(date.timeIntervalSince1970), in: timeZone)
    }

    @inline(__always)
    private static func _julianDay(from timestamp: Timestamp, in timeZone: TimeZone) -> JulianDay {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let dateComps = calendar.dateComponents(in: timeZone, from: date)
        return julianDay(fromYear: dateComps.year!, month: dateComps.month!, day: dateComps.day!)
    }

    /// 根据 timestamp 计算 julian day
    ///
    /// - parameter timestamp: Unix timestamp
    /// - parameter timeZone: timeZone
    /// - returns: julian day
    public static func julianDay(from timestamp: Timestamp, in timeZone: TimeZone) -> JulianDay {
        guard someTimeZoneIdentifiersThatDoNotObserveDaylightSavingTime.contains(timeZone.identifier) else {
            return _julianDay(from: timestamp, in: timeZone)
        }
        let startOfBaseDay = startOf2000_01_01(in: timeZone)
        guard timestamp >= startOfBaseDay else {
            return _julianDay(from: timestamp, in: timeZone)
        }
        let dayDelta = (timestamp - startOfBaseDay) / secondsPerDay
        return julianDayFrom2000_01_01 + JulianDay(dayDelta)
    }

    private static func _weekday(from julianDay: JulianDay) -> EKWeekday? {
        let timeStamp = startOfDay(for: julianDay, in: .current)
        let date = Date(timeIntervalSince1970: TimeInterval(timeStamp))
        var calendar = self.calendar
        calendar.timeZone = .current
        let dateComps = calendar.dateComponents([.weekday], from: date)
        guard let weekdayRaw = dateComps.weekday,
            let weekday = EKWeekday(rawValue: weekdayRaw) else {
            assertionFailure()
            return nil
        }
        return weekday
    }

    /// 根据 julianDay 计算 weekday；相较于直接基于 date 计算，根据 julianDay 获取 weekDay 的性能会更好
    ///
    /// - Parameter julianDay: 儒略日
    /// - Returns: 星期
    public static func weekday(from julianDay: JulianDay) -> EKWeekday {
        guard julianDay >= julianDayFrom1900_01_01 else {
            return _weekday(from: julianDay) ?? EKWeekday.sunday
        }
        let weekday = (julianDay - julianDayFrom1900_01_01 + weekdayFrom1900_01_01 - 1) % 7 + 1
        return EKWeekday(rawValue: weekday)!
    }

    /// 根据 julianDay 计算 year, month, day
    ///
    /// - returns: (year, month, day)
    public static func yearMonthDay(from julianDay: JulianDay) -> (year: Int, month: Int, day: Int) {
        let J = Int(julianDay)
        let y = 4716
        let v = 3
        let j = 1401
        let u = 5
        let m = 2
        let s = 153
        let n = 12
        let w = 2
        let r = 4
        let B = 274_277
        let p = 1461
        let C = -38
        let f = J + j + (((4 * J + B) / 146_097) * 3) / 4 + C

        let e = r * f + v
        let g = (e % p) / r
        let h = u * g + w
        let D = (h % s) / u + 1
        let M = ((h / s) + m) % n + 1
        let Y = e / p - y + (n + m - M) / n
        return (Y, M, D)
    }

    /// 获取 2000.01.01 在对应 timeZone 下的 start timestamp（第一秒）
    public static func startOf2000_01_01(in timeZone: TimeZone) -> Timestamp {
        os_unfair_lock_lock(&unfairLock)
        defer { os_unfair_lock_unlock(&unfairLock) }
        if let timestamp = baseDayStartTimestamps[timeZone.identifier] {
            return timestamp
        } else {
            let (year, month, day) = yearMonthDay(from: julianDayFrom2000_01_01)
            let dateComps = DateComponents(calendar: calendar, timeZone: timeZone, year: year, month: month, day: day)
            let date = calendar.date(from: dateComps)!
            let timtstamp = Timestamp(date.timeIntervalSince1970)
            baseDayStartTimestamps[timeZone.identifier] = timtstamp
            return timtstamp
        }
    }

    /// 获取 julianDay 对应第一时刻的时间戳；譬如 2020.02.02 00:00:00 对应的 timestamp
    ///
    /// - parameter julianDay: Julian Day
    /// - parameter timeZone: time zone
    /// - returns: 对应 day 的第一秒
    public static func startOfDay(for julianDay: JulianDay, in timeZone: TimeZone) -> Timestamp {
        let ret: Timestamp
        if julianDay >= julianDayFrom2000_01_01,
           someTimeZoneIdentifiersThatDoNotObserveDaylightSavingTime.contains(timeZone.identifier) {
            // 对于没有夏令时的 TimeZone，基于 baseDay(2020.01.01) 计算 timestamp，效率更高
            ret = startOf2000_01_01(in: timeZone) + Int64(julianDay - julianDayFrom2000_01_01) * secondsPerDay
        } else {
            let (year, month, day) = yearMonthDay(from: julianDay)
            let dateComps = DateComponents(calendar: calendar, timeZone: timeZone, year: year, month: month, day: day)
            let date = calendar.date(from: dateComps) ?? Date()
            ret = Timestamp(date.timeIntervalSince1970)
        }

        #if DEBUG
        // 校验，确保计算逻辑正确
        let date = Date(timeIntervalSince1970: TimeInterval(ret))
        let dateComps = calendar.dateComponents(in: timeZone, from: date)
        let (year, month, day) = yearMonthDay(from: julianDay)
        assert(year == dateComps.year!
            && month == dateComps.month!
            && day == dateComps.day!
            && 0 == dateComps.hour!
            && 0 == dateComps.minute!
            && 0 == dateComps.second!
            )
        #endif
        return ret
    }

    /// 获取 julianDay 对应最后时刻的时间戳；譬如 2020.02.02 23:59:59 对应的 timestamp
    ///
    /// - parameter julianDay: Julian Day
    /// - parameter timeZone: time zone
    /// - returns: 对应 day 的最后一秒
    public static func endOfDay(for julianDay: JulianDay, in timeZone: TimeZone) -> Timestamp {
        return startOfDay(for: julianDay + 1, in: timeZone) - 1
    }

    /// 计算 julian day 同一周的所有 julian day range
    ///
    /// - parameter refJulianDay: based julian day
    /// - parameter timeZone: first week day
    /// - returns: range of julian day
    public static func julianDayRange(
        inSameWeekAs refJulianDay: JulianDay,
        with firstWeekday: EKWeekday = .sunday
    ) -> JulianDayRange {
        guard let weekday = _weekday(from: refJulianDay)?.rawValue else {
            return refJulianDay..<refJulianDay + 7
        }
        let firstJulianDay = refJulianDay - (weekday - firstWeekday.rawValue + 7) % 7
        return firstJulianDay..<firstJulianDay + 7
    }

    /// 计算 julian day 同一月的所有 julian day range
    ///
    /// - parameter refJulianDay: based julian day
    /// - parameter timeZone: first week day
    /// - returns: range of julian day
    public static func julianDayRange(inSameMonthAs refJulianDay: JulianDay) -> JulianDayRange {
        let startTimestamp = startOfDay(for: refJulianDay, in: .current)
        let date = Date(timeIntervalSince1970: TimeInterval(startTimestamp))
        guard let day = calendar.dateComponents(in: .current, from: date).day else {
            assertionFailure()
            return refJulianDay..<refJulianDay + 28
        }
        let startJulianDay = refJulianDay - day + 1
        var calendar = self.calendar
        calendar.timeZone = .current
        guard let dayCount = calendar.range(of: .day, in: .month, for: date)?.count else {
            assertionFailure()
            return startJulianDay..<startJulianDay + 28
        }
        return startJulianDay..<startJulianDay + dayCount
    }

    ///根据儒略日计算 Date 返回当天的第一秒
    public static func date(from julianDay: Int, in timeZone: TimeZone = .current) -> Date {
        let startTimestamp = startOfDay(for: julianDay, in: timeZone)
        let date = Date(timeIntervalSince1970: TimeInterval(startTimestamp))
        return date
    }

}

//swiftlint:enable missing_docs
//swiftlint:enable identifier_name
