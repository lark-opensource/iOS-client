//
//  EventEditAttendeeTimeZoneViewModel.swift
//  Calendar
//
//  Created by chaishenghua on 2023/11/28.
//

import Foundation
import LarkTimeFormatUtils

class EventEditAttendeeTimeZoneViewModel {
    typealias DateRange = (start: Date, end: Date)

    let attendees: [UserAttendeeBaseDisplayInfo]
    let timeRangeDescription: String

    init(dateRange: DateRange,
         attendees: [UserAttendeeBaseDisplayInfo],
         timeZone: TimeZone?,
         is12HourStyle: Bool) {
        self.attendees = attendees
        timeRangeDescription = Self.getDate(dateRange: dateRange, timeZone: timeZone, is12HourStyle: is12HourStyle)
    }

    private static func getDate(dateRange: DateRange, timeZone: TimeZone?, is12HourStyle: Bool) -> String {
        if let timeZone = timeZone {
            let customOptions = Options(
                timeZone: timeZone,
                is12HourStyle: is12HourStyle,
                timeFormatType: .short,
                timePrecisionType: .minute,
                datePrecisionType: .day,
                dateStatusType: .absolute
            )

            return TimeFormatUtils.formatDateTimeRange(
                startFrom: dateRange.start,
                endAt: dateRange.end,
                with: customOptions
            )
        } else {
            return I18n.Calendar_G_HideTimeZone
        }
    }
}
