//
//  Alias.swift
//  Calendar
//
//  Created by Rico on 2021/4/19.
//

import Foundation
import RustPB

enum EventDetail { }

extension EventDetail {

    /// 直接使用 event pb
    typealias Event = RustPB.Calendar_V1_CalendarEvent
    /// 直接使用 instance pb
    typealias Instance = RustPB.Calendar_V1_CalendarEventInstance
    /// 直接使用 attendee pb
    typealias Attendee = Calendar_V1_CalendarEventAttendee
    /// 使用包装的Calendar
    typealias Calendar = CalendarModel
}
