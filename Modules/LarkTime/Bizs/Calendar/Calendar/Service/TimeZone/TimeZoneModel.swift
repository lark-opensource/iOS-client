//
//  TimeZoneModel.swift
//  Calendar
//
//  Created by 张威 on 2020/1/16.
//

import Foundation

protocol TimeZoneModel {

    typealias ID = String

    /// 时区唯一标志，eg: "America/Los_Angeles"
    var identifier: ID { get }

    /// 时区相对于 GMT 的偏移量（秒）
    /// GMT means: Greenwich Mean Time
    var secondsFromGMT: Int { get }

    func standardName(for date: Date) -> String

    func getSecondsFromGMT(date: Date) -> Int
}

// 用于外部组件输入空时区
struct FackTimeZone: TimeZoneModel {
    var identifier: ID = ""

    var secondsFromGMT: Int = 0

    func standardName(for date: Date) -> String { "" }

    func getSecondsFromGMT(date: Date) -> Int { return 0 }
}

extension Foundation.TimeZone: TimeZoneModel {
    var secondsFromGMT: Int { secondsFromGMT() }

    func standardName(for date: Date) -> String {
        if isDaylightSavingTime(for: date) {
            return localizedName(for: .daylightSaving, locale: NSLocale.current) ?? ""
        } else {
            return localizedName(for: .standard, locale: NSLocale.current) ?? ""
        }
    }

    func getSecondsFromGMT(date: Date) -> Int {
        return secondsFromGMT(for: date)
    }
}

extension TimeZoneModel {

    var gmtOffsetDescription: String {
        return getGmtOffsetDescription()
    }

    func getGmtOffsetDescription(date: Date = Date()) -> String {
        var seconds = getSecondsFromGMT(date: date)
        var isNegative = false
        if seconds < 0 {
            seconds = abs(seconds)
            isNegative = true
        }
        let hours = seconds / 3600
        let minutes = seconds % 3600 / 60
        if hours == 0 && minutes == 0 {
            return "GMT"
        }
        var desc = isNegative ? "GMT-" : "GMT+"
        if hours > 0 {
            desc += String(hours)
        }
        if minutes > 0 {
            if hours > 0 {
                desc += ":\(minutes)"
            } else {
                desc += "0:\(minutes)"
            }
        }
        return desc
    }
}
