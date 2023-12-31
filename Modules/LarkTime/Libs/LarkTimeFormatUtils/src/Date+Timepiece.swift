//
//  Date+Timepiece.swift
//  Timepiece
//
//  Created by Naoto Kaneko on 10/2/16.
//  Copyright © 2016 Naoto Kaneko. All rights reserved.
//

import Foundation

extension Date {
    /// The year.
    var year: Int {
        return dateComponents.year!
    }

    /// The month.
    var month: Int {
        return dateComponents.month!
    }

    /// The day.
    var day: Int {
        return dateComponents.day!
    }

    /// The hour.
    var hour: Int {
        return dateComponents.hour!
    }

    /// The minute.
    var minute: Int {
        return dateComponents.minute!
    }

    /// The second.
    var second: Int {
        return dateComponents.second!
    }

    /// The weekday.
    var weekday: Int {
        return dateComponents.weekday!
    }

    // Returns user's calendar to be used to return `DateComponents` of the receiver.
    private var calendar: Calendar {
        let current = Calendar.gregorianCalendar
        if current.identifier == .gregorian {
            guard NSTimeZone.system == current.timeZone else {
                Calendar.gregorianCalendar = Calendar(identifier: .gregorian)
                return Calendar.gregorianCalendar
            }
            return current
        }
        return Calendar(identifier: .gregorian)
    }

    private var dateComponents: DateComponents {
        return calendar.dateComponents(
            [.era, .year, .month, .day, .hour, .minute, .second, .nanosecond, .weekday, .weekOfMonth],
            from: self
        )
    }
}

extension Calendar {
    static var gregorianCalendar = Calendar(identifier: .gregorian)
}
