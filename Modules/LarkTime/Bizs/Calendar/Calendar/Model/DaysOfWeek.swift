//
//  DaysOfWeek.swift
//  Calendar
//
//  Created by harry zou on 2019/2/21.
//

import Foundation
import CalendarFoundation
import RustPB
import JTAppleCalendar
import EventKit

typealias DaysOfWeek = JTAppleCalendar.DaysOfWeek

extension DaysOfWeek {
    static var allCases: [DaysOfWeek] {
        return [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
    }

    func next() -> DaysOfWeek {
        return DaysOfWeek(rawValue: self.rawValue % 7 + 1) ?? .sunday
    }

    func previous() -> DaysOfWeek {
        let allCases = DaysOfWeek.allCases
        return allCases[(allCases.firstIndex(of: self)! - 1 + allCases.count) % allCases.count]
    }

    func toPb() -> DayOfWeek {
        switch self {
        case .monday:
            return DayOfWeek.monday
        case .tuesday:
            return DayOfWeek.tuesday
        case .wednesday:
            return DayOfWeek.wednesday
        case .thursday:
            return DayOfWeek.thursday
        case .friday:
            return DayOfWeek.friday
        case .saturday:
            return DayOfWeek.saturday
        case .sunday:
            return DayOfWeek.sunday
        }
    }

    static func fromPB(pb: DayOfWeek) -> DaysOfWeek {
        switch pb {
        case .monday:
            return DaysOfWeek.monday
        case .tuesday:
            return DaysOfWeek.tuesday
        case .wednesday:
            return DaysOfWeek.wednesday
        case .thursday:
            return DaysOfWeek.thursday
        case .friday:
            return DaysOfWeek.friday
        case .saturday:
            return DaysOfWeek.saturday
        case .sunday:
            return DaysOfWeek.sunday
        @unknown default:
            return DaysOfWeek.monday
        }
    }

    func convertEKRruleFirstDayOfTheWeek() -> Int {
        switch self {
        case .sunday:
            return 1
        case .monday:
            return 2
        case .tuesday:
            return 3
        case .wednesday:
            return 4
        case .thursday:
            return 5
        case .friday:
            return 6
        case .saturday:
            return 7
        @unknown default:
            return 0
        }
    }
}

extension EKWeekday {

    func next() -> Self {
        return EKWeekday(rawValue: self.rawValue % 7 + 1) ?? .sunday
    }

    func previous() -> Self {
        return EKWeekday(rawValue: (self.rawValue + 5) % 7 + 1) ?? .sunday
    }

    func toPb() -> DayOfWeek {
        switch self {
        case .monday:
            return DayOfWeek.monday
        case .tuesday:
            return DayOfWeek.tuesday
        case .wednesday:
            return DayOfWeek.wednesday
        case .thursday:
            return DayOfWeek.thursday
        case .friday:
            return DayOfWeek.friday
        case .saturday:
            return DayOfWeek.saturday
        case .sunday:
            return DayOfWeek.sunday
        }
    }

    static func from(pb: DayOfWeek) -> Self {
        switch pb {
        case .monday:
            return .monday
        case .tuesday:
            return .tuesday
        case .wednesday:
            return .wednesday
        case .thursday:
            return .thursday
        case .friday:
            return .friday
        case .saturday:
            return .saturday
        case .sunday:
            return .sunday
        @unknown default:
            return .monday
        }
    }

    static func from(daysOfweek: DaysOfWeek) -> Self {
        switch daysOfweek {
        case .sunday:
            return .sunday
        case .monday:
            return .monday
        case .tuesday:
            return .tuesday
        case .wednesday:
            return .wednesday
        case .thursday:
            return .thursday
        case .friday:
            return .friday
        case .saturday:
            return .saturday
        }
    }
}
