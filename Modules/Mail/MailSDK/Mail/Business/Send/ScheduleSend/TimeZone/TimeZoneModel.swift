//
//  TimeZoneModel.swift
//  Calendar
//
//  Created by 张威 on 2020/1/16.
//

import Foundation
import RustPB

protocol TimeZoneModel {

    typealias ID = String

    /// 时区唯一标志，eg: "America/Los_Angeles"
    var identifier: ID { get }

    /// 时区相对于 GMT 的偏移量（秒）
    /// GMT means: Greenwich Mean Time
    var secondsFromGMT: Int { get }

    var name: String { get }

    func getSecondsFromGMT(date: Date) -> Int
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
        let hours = seconds / (60 * 60)
        let minutes = seconds % (60 * 60) / 60
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

extension Foundation.TimeZone: TimeZoneModel {
    var name: String { localizedName(for: .standard, locale: NSLocale.current) ?? "" }
    var secondsFromGMT: Int { secondsFromGMT() }
    func getSecondsFromGMT(date: Date) -> Int {
        return secondsFromGMT(for: date)
    }
}

struct TimeZoneModelImpl: TimeZoneModel {
    var timezoneID: String
    var timezoneName: String
    var timezoneOffset: Int32

    var identifier: ID { timezoneID }
    var name: String { timezoneName }
    var secondsFromGMT: Int { Int(timezoneOffset) }

    func getSecondsFromGMT(date: Date) -> Int { Int(timezoneOffset) }
}
