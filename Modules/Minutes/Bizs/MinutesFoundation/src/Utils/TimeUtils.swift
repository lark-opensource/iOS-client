//
//  TimeUtils.swift
//  Minutes_iOS
//
//  Created by panzaofeng on 2020/11/6.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation

public struct TimeUtils {
    static let timeFormatter = DateFormatter()

    /// yyy-MM-dd HH:mm:ss.SSS 格式时间戳
    static func currentTimeStr() -> String {
        let date = Date()
        timeFormatter.dateFormat = "yyy-MM-dd HH:mm:ss.SSS"
        return timeFormatter.string(from: date) as String
    }

    /// 返回 1970 年至当前时刻的秒数
    static func currentTm() -> Int {
        let timeInterval: TimeInterval = Date().timeIntervalSince1970
        return Int(timeInterval)
    }

    /// 将秒数转换为 HH:mm:ss 格式的时间字符串
    static func convertIntToTimerStr(interval: Int) -> String {
        let hourStr = String(format: "%02d", interval / 3_600)
        let minuteStr = String(format: "%02d", interval % 3_600 / 60)
        let secondStr = String(format: "%02d", interval % 60)

        return "\(hourStr):\(minuteStr):\(secondStr)"
    }
}

extension Date {
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }

    func getMonthSymbol() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.monthSymbols[self.get(.month) - 1]
    }
}

public extension TimeInterval {
    static var fullFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    static var normalFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    public func format(using fullFormatter: Bool) -> String? {
        let formatter = fullFormatter ? TimeInterval.fullFormatter : TimeInterval.normalFormatter

        return formatter.string(from: self)
    }

    // disable-lint: duplicated_code
    public func autoFormat(anchorTime: TimeInterval? = nil, fullFormat: Bool = false) -> String? {
        var useFullFormatter: Bool = false
        if fullFormat {
            useFullFormatter = true
        }
        if self > 3600 {
            useFullFormatter = true
        }
        if let someAnchorTime = anchorTime, someAnchorTime > 3600 {
            useFullFormatter = true
        }
        return format(using: useFullFormatter)
    }
    // enable-lint: duplicated_code
    public func localeDate() -> String {
        let date = Date(timeIntervalSince1970: self)
        return "\(date.dateString()) \(date.timeString(ofStyle: .short))"
    }
}

public extension TimeInterval {
    public var millisecond: Int {
        return Int((self * 1000.0).rounded())
    }
}

extension MinsWrapper where Base == Date {

    static var dateFormatters = [String: DateFormatter]()
    static let calendar = Calendar(identifier: Calendar.current.identifier)
    static let semaphore = DispatchSemaphore(value: 1)

    public var isInToday: Bool {
        return Self.calendar.isDateInToday(base)
    }

    public var isInYesterday: Bool {
        return Self.calendar.isDateInYesterday(base)
    }

    public var isInTomorrow: Bool {
        return Self.calendar.isDateInTomorrow(base)
    }

    public var isInWeekend: Bool {
        return Self.calendar.isDateInWeekend(base)
    }

    public var isInCurrentMonth: Bool {
        return Self.calendar.isDate(base, equalTo: Date(), toGranularity: .month)
    }

    public var isInCurrentYear: Bool {
        return Self.calendar.isDate(base, equalTo: Date(), toGranularity: .year)
    }

    public func string(withFormat format: String, localIdentifier: String = "zh_CN") -> String {
        let key = "\(format)_\(localIdentifier)"
        let formatter: DateFormatter
        if let df = getFormatter(forKey: key) {
            formatter = df
        } else {
            formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: localIdentifier)
            set(formatter, forKey: key)
        }
        return formatter.string(from: base)
    }

    private func getFormatter(forKey key: String) -> DateFormatter? {
        Self.semaphore.wait()
        let formatter = Self.dateFormatters[key]
        Self.semaphore.signal()
        return formatter
    }

    private func set(_ formatter: DateFormatter, forKey key: String) {
        Self.semaphore.wait()
        Self.dateFormatters[key] = formatter
        Self.semaphore.signal()
    }

}
