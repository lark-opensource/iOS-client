//
//  Int+Timepiece.swift
//  MailSDK
//
//  Created by majx on 2020/12/5.
//

import Foundation

extension Int {
    var year: DateComponents {
        return DateComponents(year: self)
    }

    var month: DateComponents {
        return DateComponents(month: self)
    }

    var week: DateComponents {
        return DateComponents(day: 7 * self)
    }

    var day: DateComponents {
        return DateComponents(day: self)
    }

    var hour: DateComponents {
        return DateComponents(hour: self)
    }

    var minute: DateComponents {
        return DateComponents(minute: self)
    }

    var second: DateComponents {
        return DateComponents(second: self)
    }

    var nanosecond: DateComponents {
        return DateComponents(nanosecond: self)
    }
}
