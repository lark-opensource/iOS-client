//
//  Date+Extension.swift
//  LarkSearch
//
//  Created by SuPeng on 5/8/19.
//

import Foundation
import DateToolsSwift

extension Date: LarkSearchExtensionCompatible {}

public extension LarkSearchExtension where BaseType == Date {
    func compare(date: Date) -> ComparisonResult {
        if base.year > date.year {
            return .orderedDescending
        } else if base.year < date.year {
            return .orderedAscending
        } else {
            if base.month > date.month {
                return .orderedDescending
            } else if base.month < date.month {
                return .orderedAscending
            } else {
                if base.day > date.day {
                    return .orderedDescending
                } else if base.day < date.day {
                    return .orderedAscending
                } else {
                    return .orderedSame
                }
            }
        }
    }

    func greatOrEqualTo(date: Date) -> Bool {
        let compareResult = base.ls.compare(date: date)
        if compareResult == .orderedSame || compareResult == .orderedDescending {
            return true
        }
        return false
    }

    func lessOrEqualTo(date: Date) -> Bool {
        let compareResult = base.ls.compare(date: date)
        if compareResult == .orderedSame || compareResult == .orderedAscending {
            return true
        }
        return false
    }

    var beginDate: Date {
        return Date(year: base.year, month: base.month, day: base.day)
    }

    var endDate: Date {
        return Date(timeInterval: 24 * 60 * 60 - 0.1, since: beginDate)
    }
}
