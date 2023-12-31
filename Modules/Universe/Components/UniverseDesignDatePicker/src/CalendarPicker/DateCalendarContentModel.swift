//
//  DateCalendarContentModel.swift
//  UniverseDesignDatePicker
//
//  Created by LiangHongbin on 2021/3/17.
//

import Foundation
import EventKit

typealias DaysContent = NSArray
struct DayContent: CellState {
    var julianDay: JulianDay
    var dateBelongsTo: DateOwner
    var isSelected: Bool = false
    var text: String
    init(julianDay: JulianDay, owner: DateOwner, text: String, isSelected: Bool = false) {
        self.julianDay = julianDay
        self.dateBelongsTo = owner
        self.text = text
        self.isSelected = isSelected
    }
}

enum MonthCalendarMode {
    case singleRow
    case multipleRows
}

class DateCalendarContentModel {
    var monthCalendarMode: MonthCalendarMode = .multipleRows
    var calendar = Calendar(identifier: .gregorian)

    // 当前展示内容-数据
    var data = [JulianDay: [DayContent]]()
    let timeZone: TimeZone
    let firstWeekday: EKWeekday
    let today: JulianDay
    var selectedDay: JulianDay?
    var offset: Int {
        return firstWeekday.rawValue - 2
    }

    init(selectedDate: Date? = Date(), timeZone: TimeZone, firstWeekday: EKWeekday) {
        self.timeZone = timeZone
        self.firstWeekday = firstWeekday
        self.calendar.timeZone = timeZone
        if let selectedDate = selectedDate {
            selectedDay = JulianDayUtil.julianDay(from: selectedDate, in: timeZone)
        }
        today = JulianDayUtil.julianDay(from: Date(), in: timeZone)
    }
}
