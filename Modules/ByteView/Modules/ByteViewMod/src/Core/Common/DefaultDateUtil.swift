//
//  DateUtil.swift
//  ByteViewMod
//
//  Created by kiri on 2023/2/22.
//

import Foundation

final class DefaultDateUtil {

    private static func formatDate(_ date: Date, showsTimeIfToday: Bool) -> String {
        let calendar = Calendar.gregorianCalendar
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.calendar = calendar
        formatter.timeZone = .current
        if calendar.isDateInToday(date) {
            return showsTimeIfToday ? timeFormatter.string(from: date) : "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            return shortDateFormatter.string(from: date)
        } else {
            return longDateFormatter.string(from: date)
        }
    }

    static func formatCalendarDateTimeRange(startTime: TimeInterval, endTime: TimeInterval) -> String {
        let startDate = Date(timeIntervalSince1970: startTime)
        let endDate = Date(timeIntervalSince1970: endTime)
        let startString = formatDate(startDate, showsTimeIfToday: false)
        if Calendar.gregorianCalendar.isDate(startDate, equalTo: endDate, toGranularity: .day) {
            return startString
        }
        let endString = formatDate(endDate, showsTimeIfToday: false)
        return "\(startString) - \(endString)"
    }

    private static let timeFormatter = DateFormatter(format: "HH:mm")
    private static let longDateFormatter = DateFormatter(format: "yyyy年MM月dd日")
    private static let shortDateFormatter = DateFormatter(format: "MM月dd日")
}

private extension Calendar {
    static let gregorianCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return cal
    }()
}

private extension DateFormatter {
    convenience init(format: String) {
        self.init()
        self.dateFormat = format
    }
}
