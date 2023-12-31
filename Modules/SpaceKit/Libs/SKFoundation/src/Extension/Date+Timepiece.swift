//
//  Date+Timepiece.swift
//  Timepiece
//
//  Created by Naoto Kaneko on 10/2/16.
//  Copyright © 2016 Naoto Kaneko. All rights reserved.
//
//  Included OSS: Timepiece
//  Copyright (c) 2016 Naoto Kaneko
//  spdx license identifier: MIT

import Foundation

extension Date: SKExtensionCompatible {}

extension SKExtension where Base == Date {

    /// The year.
    public var year: Int {
        return base.dateComponents.year ?? 0
    }

    /// The month.
    public var month: Int {
        return base.dateComponents.month ?? 0
    }

    /// The day.
    public var day: Int {
        return base.dateComponents.day ?? 0
    }

    /// The hour.
    public var hour: Int {
        return base.dateComponents.hour ?? 0
    }

    /// The minute.
    public var minute: Int {
        return base.dateComponents.minute ?? 0
    }

    /// The second.
    public var second: Int {
        return base.dateComponents.second ?? 0
    }

    /// The nanosecond.
    public var nanosecond: Int {
        return base.dateComponents.nanosecond ?? 0
    }

    /// The weekday.
    public var weekday: Int {
        return base.dateComponents.weekday ?? 0
    }

    /// The weekOfMonth
    public var weekOfMonth: Int {
        return base.dateComponents.weekOfMonth ?? 0
    }

    /// Creates a new instance representing today.
    ///
    /// - returns: The created `Date` instance representing today.
    public static func today() -> Date {
        let now = Date()
        return Date(year: now.sk.year, month: now.sk.month, day: now.sk.day)
    }

    /// Creates a new instance representing yesterday
    ///
    /// - returns: The created `Date` instance representing yesterday.
    public static func yesterday() -> Date {
        return (today() - 1.sk.day)!
    }

    /// Creates a new instance representing tomorrow
    ///
    /// - returns: The created `Date` instance representing tomorrow.
    public static func tomorrow() -> Date {
        return (today() + 1.sk.day)!
    }
    
    public static func otherDay(_ otherDay: Int) -> Date {
        return (today() + otherDay.sk.day)!
    }
    /// Creates a new instance by changing the date components
    ///
    /// - Parameters:
    ///   - year: The year.
    ///   - month: The month.
    ///   - day: The day.
    ///   - hour: The hour.
    ///   - minute: The minute.
    ///   - second: The second.
    ///   - nanosecond: The nanosecond.
    /// - Returns: The created `Date` instnace.
    public func changed(year: Int? = nil, month: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil, nanosecond: Int? = nil) -> Date? {
        var dateComponents = base.dateComponents
        dateComponents.year = year ?? base.sk.year
        dateComponents.month = month ?? base.sk.month
        dateComponents.day = day ?? base.sk.day
        dateComponents.hour = hour ?? base.sk.hour
        dateComponents.minute = minute ?? base.sk.minute
        dateComponents.second = second ?? base.sk.second
        dateComponents.nanosecond = nanosecond ?? base.sk.nanosecond

        return base.calendar.date(from: dateComponents)
    }

//    /// Creates a new instance by changing the year.
//    ///
//    /// - Parameter year: The year.
//    /// - Returns: The created `Date` instance.
//    public func changed(year: Int) -> Date? {
//        return changed(year: year, month: nil, day: nil, hour: nil, minute: nil, second: nil, nanosecond: nil)
//    }
//
//    /// Creates a new instance by changing the month.
//    ///
//    /// - Parameter month: The month.
//    /// - Returns: The created `Date` instance.
//    public func changed(month: Int) -> Date? {
//        return changed(year: nil, month: month, day: nil, hour: nil, minute: nil, second: nil, nanosecond: nil)
//    }
//
//    /// Creates a new instance by changing the day.
//    ///
//    /// - Parameter day: The day.
//    /// - Returns: The created `Date` instance.
//    public func changed(day: Int) -> Date? {
//        return changed(year: nil, month: nil, day: day, hour: nil, minute: nil, second: nil, nanosecond: nil)
//    }
//
//    /// Creates a new instance by changing the hour.
//    ///
//    /// - Parameter hour: The hour.
//    /// - Returns: The created `Date` instance.
//    public func changed(hour: Int) -> Date? {
//        return changed(year: nil, month: nil, day: nil, hour: hour, minute: nil, second: nil, nanosecond: nil)
//    }
//
//    /// Creates a new instance by changing the minute.
//    ///
//    /// - Parameter minute: The minute.
//    /// - Returns: The created `Date` instance.
//    public func changed(minute: Int) -> Date? {
//        return changed(year: nil, month: nil, day: nil, hour: nil, minute: minute, second: nil, nanosecond: nil)
//    }
//
//    /// Creates a new instance by changing the second.
//    ///
//    /// - Parameter second: The second.
//    /// - Returns: The created `Date` instance.
//    public func changed(second: Int) -> Date? {
//        return changed(year: nil, month: nil, day: nil, hour: nil, minute: nil, second: second, nanosecond: nil)
//    }
//
//    /// Creates a new instance by changing the nanosecond.
//    ///
//    /// - Parameter nanosecond: The nanosecond.
//    /// - Returns: The created `Date` instance.
//    public func changed(nanosecond: Int) -> Date? {
//        return changed(year: nil, month: nil, day: nil, hour: nil, minute: nil, second: nil, nanosecond: nanosecond)
//    }
//
//    /// Creates a new instance by changing the weekday.
//    ///
//    /// - Parameter weekday: The weekday.
//    /// - Returns: The created `Date` instance.
//    public func changed(weekday: Int) -> Date? {
//        return base - (base.sk.weekday - weekday).sk.days
//    }

//    /// Creates a new instance by truncating the components
//    ///
//    /// - Parameter components: The components to be truncated.
//    /// - Returns: The created `Date` instance.
//    func truncated(_ components: [Calendar.Component]) -> Date? {
//        var dateComponents = base.dateComponents
//
//        for component in components {
//            switch component {
//            case .month:
//                dateComponents.month = 1
//            case .day:
//                dateComponents.day = 1
//            case .hour:
//                dateComponents.hour = 0
//            case .minute:
//                dateComponents.minute = 0
//            case .second:
//                dateComponents.second = 0
//            case .nanosecond:
//                dateComponents.nanosecond = 0
//            default:
//                continue
//            }
//        }
//
//        return base.calendar.date(from: dateComponents)
//    }

//    /// Creates a new instance by truncating the components
//    ///
//    /// - Parameter component: The component to be truncated from.
//    /// - Returns: The created `Date` instance.
//    func truncated(from component: Calendar.Component) -> Date? {
//        switch component {
//        case .month:
//            return truncated([.month, .day, .hour, .minute, .second, .nanosecond])
//        case .day:
//            return truncated([.day, .hour, .minute, .second, .nanosecond])
//        case .hour:
//            return truncated([.hour, .minute, .second, .nanosecond])
//        case .minute:
//            return truncated([.minute, .second, .nanosecond])
//        case .second:
//            return truncated([.second, .nanosecond])
//        case .nanosecond:
//            return truncated([.nanosecond])
//        default:
//            return base
//        }
//    }

    /// Creates a new `String` instance representing the receiver formatted in given date style and time style.
    ///
    /// - parameter dateStyle: The date style.
    /// - parameter timeStyle: The time style.
    ///
    /// - returns: The created `String` instance.
    func stringIn(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = dateStyle
        dateFormatter.timeStyle = timeStyle

        return dateFormatter.string(from: base)
    }

//    @available(*, unavailable, renamed: "stringIn(dateStyle:timeStyle:)")
//    func string(inDateStyle dateStyle: DateFormatter.Style, andTimeStyle timeStyle: DateFormatter.Style) -> String {
//        return stringIn(dateStyle: dateStyle, timeStyle: timeStyle)
//    }

    /// Creates a new `String` instance representing the date of the receiver formatted in given date style.
    ///
    /// - parameter dateStyle: The date style.
    ///
    /// - returns: The created `String` instance.
    public func dateString(in dateStyle: DateFormatter.Style) -> String {
        return stringIn(dateStyle: dateStyle, timeStyle: .none)
    }

    /// Creates a new `String` instance representing the time of the receiver formatted in given time style.
    ///
    /// - parameter timeStyle: The time style.
    ///
    /// - returns: The created `String` instance.
    public func timeString(in timeStyle: DateFormatter.Style) -> String {
        return stringIn(dateStyle: .none, timeStyle: timeStyle)
    }

    public func isInSameMonth(_ date: Date) -> Bool {
        return base.calendar.isDate(base, equalTo: date, toGranularity: .month)
    }

    public func isInSameWeek(_ date: Date, firstWeekday: Int) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = firstWeekday
        return calendar.isDate(base, equalTo: date, toGranularity: .weekOfYear)
    }

    public func startOfWeek(firstWeekday: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = firstWeekday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: base)
        return calendar.date(from: components) ?? base
    }

    public func isInSameDay(_ date: Date) -> Bool {
        return base.calendar.isDate(base, equalTo: date, toGranularity: .day)
    }

    public func isInSameYear(_ date: Date) -> Bool {
        return base.calendar.isDate(base, equalTo: date, toGranularity: .year)
    }

    private static let utcToLocalFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    //将UTC的 xx:xx 转换成当前时区的 xx:xx, 抹去时差
    public func utcToLocalDate(_ localTimezone: TimeZone = TimeZone.current) -> Date {
        let formatter = Date.sk.utcToLocalFormatter
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        let utcStr = formatter.string(from: base)
        formatter.timeZone = localTimezone
        return formatter.date(from: utcStr) ?? Date()
    }

    public func dayEnd() -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: base.calendar.startOfDay(for: base))!
    }

    public func dayStart() -> Date {
        return base.calendar.startOfDay(for: base)
    }

    public func startOfMonth() -> Date {
        return base.calendar.date(from: Calendar.current.dateComponents([.year, .month], from: base.calendar.startOfDay(for: base)))!
    }

    public func endOfMonth() -> Date {
        return base.calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth())!.sk.dayEnd()
    }
}

extension Date {

    var dateComponents: DateComponents {
        return calendar.dateComponents([.era, .year, .month, .day, .hour, .minute, .second, .nanosecond, .weekday, .weekOfMonth], from: self)
    }

    // Returns user's calendar to be used to return `DateComponents` of the receiver.
    var calendar: Calendar {
        return .current
    }

    /// Creates a new instance with specified date components.
    ///
    /// - parameter era:        The era.
    /// - parameter year:       The year.
    /// - parameter month:      The month.
    /// - parameter day:        The day.
    /// - parameter hour:       The hour.
    /// - parameter minute:     The minute.
    /// - parameter second:     The second.
    /// - parameter nanosecond: The nanosecond.
    /// - parameter calendar:   The calendar used to create a new instance.
    ///
    /// - returns: The created `Date` instance.
    public init(era: Int?, year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, nanosecond: Int, on calendar: Calendar) {
        let now = Date()
        var dateComponents = calendar.dateComponents([.era, .year, .month, .day, .hour, .minute, .second, .nanosecond], from: now)
        dateComponents.era = era
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second
        dateComponents.nanosecond = nanosecond

        let date = calendar.date(from: dateComponents)
        self.init(timeInterval: 0, since: date!)
    }

    /// Creates a new instance with specified date componentns.
    ///
    /// - parameter year:       The year.
    /// - parameter month:      The month.
    /// - parameter day:        The day.
    /// - parameter hour:       The hour.
    /// - parameter minute:     The minute.
    /// - parameter second:     The second.
    /// - parameter nanosecond: The nanosecond. `0` by default.
    ///
    /// - returns: The created `Date` instance.
    public init(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, nanosecond: Int = 0) {
        self.init(era: nil, year: year, month: month, day: day, hour: hour, minute: minute, second: second, nanosecond: nanosecond, on: .current)
    }

    /// Creates a new Instance with specified date components
    ///
    /// - parameter year:  The year.
    /// - parameter month: The month.
    /// - parameter day:   The day.
    ///
    /// - returns: The created `Date` instance.
    public init(year: Int, month: Int, day: Int) {
        self.init(year: year, month: month, day: day, hour: 0, minute: 0, second: 0)
    }

    /// Creates a new instance added a `DateComponents`
    ///
    /// - parameter left:  The date.
    /// - parameter right: The date components.
    ///
    /// - returns: The created `Date` instance.
    public static func + (left: Date, right: DateComponents) -> Date? {
        return Calendar.current.date(byAdding: right, to: left)
    }

    /// Creates a new instance subtracted a `DateComponents`
    ///
    /// - parameter left:  The date.
    /// - parameter right: The date components.
    ///
    /// - returns: The created `Date` instance.
    public static func - (left: Date, right: DateComponents) -> Date? {
        return Calendar.current.date(byAdding: -right, to: left)
    }
}
