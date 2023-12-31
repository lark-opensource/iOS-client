//
//  DateTime.swift
//  Calendar
//
//  Created by linlin on 2017/11/21.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import CalendarFoundation

let oneDaySeconds = TimeInterval(24 * 60 * 60)
/// 从0到totalHeight代表一天从0点到24点，
/// 根据比例，计算给定yOffset在一天中对应的是几点
/// - Parameters:
///   - yOffset: 需要计算日期的yOffset
///   - totalHeight: 一天中第24小时代表的高度
///   - startTime: yOffset = 0所代表的日期。 例如 2017/11/29 0点0分。
///                实际使用过程中，可传入任意日期，日期的时分秒会在计算的时候被忽略。
///   - topIgnoreHeight: 顶部忽略的高度
///   - bottomIgnoreHeight: 底部忽略高度
/// - Returns: 给定yOffset在一天中对应的是几点，如果yOffset小于等于0或者yOffset超出totalHeight,返回nil
func dateWithYOffset(_ yOffset: CGFloat,
                     startTime: Date = Date(),
                     totalHeight: CGFloat = CalendarViewStyle.Background.wholeDayHeight,
                     topIgnoreHeight: CGFloat = CalendarViewStyle.Background.topGridMargin,
                     bottomIgnoreHeight: CGFloat = CalendarViewStyle.Background.bottomGridMargin) -> Date {
    guard
        totalHeight > topIgnoreHeight + bottomIgnoreHeight,
        yOffset >= topIgnoreHeight,
        yOffset <= totalHeight - bottomIgnoreHeight,
        bottomIgnoreHeight >= 0,
        topIgnoreHeight >= 0 else {
        return Date()
    }
    let heightDiff = totalHeight - topIgnoreHeight - bottomIgnoreHeight
    let secondsOffset = TimeInterval((yOffset - topIgnoreHeight) / heightDiff) * oneDaySeconds
    return Date(timeInterval: secondsOffset.rounded(), since: startTime.dayStart())
}

/// 从0到totalHeight代表一天从0点到24点
/// 根据比例，计算给定的日期，在toalHeight所应该占据的高度
/// - Parameters:
///   - date: 所需要计算的date
///   - totalHeight: 一天中第24小时代表的高度
///   - topIgnoreHeight: 顶部忽略的高度
///   - bottomIgnoreHeight: 底部忽略高度
/// - Returns: 给定日期，中的时分秒，整体应该在totalHeight中应该占据的高度
func yOffsetWithDate(_ date: Date,
                     inTheDay: Date,
                     totalHeight: CGFloat = CalendarViewStyle.Background.wholeDayHeight,
                     topIgnoreHeight: CGFloat = CalendarViewStyle.Background.topGridMargin,
                     bottomIgnoreHeight: CGFloat = CalendarViewStyle.Background.bottomGridMargin,
                     calendar: Calendar? = nil) -> CGFloat {
    guard
        totalHeight > topIgnoreHeight + bottomIgnoreHeight,
        bottomIgnoreHeight >= 0,
        topIgnoreHeight >= 0 else {
        return 0
    }
    let calendar = calendar ?? gregorianCalendar()
    let dateComponents = calendar.dateComponents([.hour, .minute, .second], from: date)
    let startHour = dateComponents.hour ?? 0
    let startMin = dateComponents.minute ?? 0
    let startSecond = dateComponents.second ?? 0
    let totalSeconds = TimeInterval(startHour * 60 * 60 + startMin * 60 + startSecond)
    let start = inTheDay.dayStart()
    let heightDiff = totalHeight - topIgnoreHeight - bottomIgnoreHeight
    if date.timeIntervalSince1970 - start.timeIntervalSince1970 >= 86_400 {
        return heightDiff + topIgnoreHeight
    } else {
        return heightDiff * CGFloat(totalSeconds / oneDaySeconds) + topIgnoreHeight
    }
}

/// 自动调整时间，拖拽的最小变化时间
func normorlizeDate(_ date: Date, minEventChangeMinutes: Int) -> Date {
    let calendar = Calendar(identifier: .gregorian)
    let dateComponents = calendar.dateComponents([.minute, .second], from: date)
    var startMin = dateComponents.minute ?? 0
    let startSecond = dateComponents.second ?? 0
    let totalSeconds = startMin * 60 + startSecond
    var normlizedMinute = 0
    while startMin - minEventChangeMinutes > 0 {
        startMin -= minEventChangeMinutes
        normlizedMinute += minEventChangeMinutes
    }
    startMin = dateComponents.minute ?? 0
    let remainSeconds = (startMin - normlizedMinute) * 60 + startSecond
    if remainSeconds > minEventChangeMinutes * 60 / 2 {
        normlizedMinute += minEventChangeMinutes
    }
    return Date(timeInterval: TimeInterval(normlizedMinute * 60 - totalSeconds), since: date)
}

func getDateFromInt64(_ int: Int64) -> Date {
    let doubleTSP = Double(int)
    let date = Date(timeIntervalSince1970: doubleTSP)
    return date
}

/// 根据儒略日计算Date，此算法只对格里高利历有效 https://en.wikipedia.org/wiki/Julian_day
func getDate(julianDay: Int32, calendar: Calendar? = nil) -> Date {
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

    var comps = DateComponents()
    comps.year = Y
    comps.month = M
    comps.day = D

    let calendar = calendar ?? gregorianCalendar()
    guard let date = calendar.date(from: comps) else {
        assertionFailureLog()
        return Date()
    }

    return date
}

/// 计算儒略日，此算法只对格里高利历有效 https://en.wikipedia.org/wiki/Julian_day
func getJulianDay(date: Date, calendar: Calendar? = nil) -> Int32 {
    let (year, month, day) = getYearMonthDay(date: date, calendar: calendar)
    let julianDay = (1461 * (year + 4800 + (month - 14) / 12)) / 4 +
        (367 * (month - 2 - 12 * ((month - 14) / 12))) / 12 -
        (3 * ((year + 4900 + (month - 14) / 12) / 100)) / 4 +
        day - 32_075
    return Int32(julianDay)
}

private func gregorianCalendar() -> Calendar {
    return Calendar(identifier: .gregorian)
}

func getYearMonthDay(date: Date, calendar: Calendar? = nil) -> (Int, Int, Int) {
    let calendar = calendar ?? gregorianCalendar()
    let dataCom: DateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    let year: Int = dataCom.year!
    let month: Int = dataCom.month!
    let day: Int = dataCom.day!
    return (year, month, day)
}

/// 计算儒略分
func getJulianMinute(date: Date) -> Int32 {
    return Int32(60 * date.hour + date.minute)
}
func getJulianMinute(date: Date, calendar: Calendar) -> Int32 {
    let componets = calendar.dateComponents([.hour, .minute], from: date)
    return Int32(60 * componets.hour! + componets.minute!)
}

func daysBetween(date1: Date, date2: Date) -> Int {
    let calendar = Calendar.gregorianCalendar
    let date1 = calendar.startOfDay(for: date1)
    let date2 = calendar.startOfDay(for: date2)
    let components = calendar.dateComponents([Calendar.Component.day], from: date1, to: date2)
    return components.day ?? 0
}
