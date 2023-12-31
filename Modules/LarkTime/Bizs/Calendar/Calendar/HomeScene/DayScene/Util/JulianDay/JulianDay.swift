//
//  JulianDay.swift
//  Calendar
//
//  Created by 张威 on 2020/8/4.
//

import Foundation
import CTFoundation

typealias JulianDayRange = CTFoundation.JulianDayRange
typealias JulianDay = CTFoundation.JulianDay

enum JulianDayStatus: Int {
    case past = 1
    case today
    case future

    static func make(from fromJulianDay: JulianDay, to toJulianDay: JulianDay) -> Self {
        if fromJulianDay < toJulianDay {
            return .past
        } else if fromJulianDay > toJulianDay {
            return .future
        } else {
            return .today
        }
    }
}

extension JulianDayUtil {

    static func makeJulianDayRange(min: Int32?, max: Int32?) -> JulianDayRange {
        guard let minJulianDay = min, let maxJulianDay = max else {
            return 0..<0
        }
        return Int(minJulianDay)..<(Int(maxJulianDay) + 1)
    }

}
