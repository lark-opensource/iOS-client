//
//  Int+Timepiece.swift
//  Timepiece
//
//  Created by Naoto Kaneko on 2014/08/15.
//  Copyright (c) 2014年 Naoto Kaneko. All rights reserved.
//
//  Included OSS: Timepiece
//  Copyright (c) 2014 Naoto Kaneko
//  spdx license identifier: MIT

import Foundation

extension Int: SKExtensionCompatible {}

public extension SKExtension where Base == Int {

    var year: DateComponents {
        return DateComponents(year: self.base)
    }

    var years: DateComponents {
        return year
    }

    var month: DateComponents {
        return DateComponents(month: self.base)
    }

    var months: DateComponents {
        return month
    }

    var week: DateComponents {
        return DateComponents(day: 7 * self.base)
    }

    var weeks: DateComponents {
        return week
    }

    var day: DateComponents {
        return DateComponents(day: self.base)
    }

    var days: DateComponents {
        return day
    }

    var hour: DateComponents {
        return DateComponents(hour: self.base)
    }

    var hours: DateComponents {
        return hour
    }

    var minute: DateComponents {
        return DateComponents(minute: self.base)
    }

    var minutes: DateComponents {
        return minute
    }

    var second: DateComponents {
        return DateComponents(second: self.base)
    }

    var seconds: DateComponents {
        return second
    }

    var nanosecond: DateComponents {
        return DateComponents(nanosecond: self.base)
    }

    var nanoseconds: DateComponents {
        return nanosecond
    }
}
