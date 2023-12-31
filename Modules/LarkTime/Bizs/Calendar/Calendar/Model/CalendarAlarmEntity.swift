//
//  CalendarAlarmEntity.swift
//  Calendar
//
//  Created by zhu chao on 2018/11/1.
//  Copyright © 2018 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import RustPB
import EventKit
protocol CalendarAlarmEntity {
    var eventID: Int32 { get }
    var title: String { get }
    var startTime: Int64 { get }
    var endTime: Int64 { get }
    var alarmTime: Int64 { get }
    var minutes: Int32 { get }
    var identifier: String { get }
}

private let separator = "<**>"

struct PBAlarm: CalendarAlarmEntity {
    var eventID: Int32 {
        return roiginModel.eventID
    }

    var title: String {
        return roiginModel.title
    }

    var startTime: Int64 {
        return roiginModel.startTime
    }

    var endTime: Int64 {
        return roiginModel.endTime
    }

    var alarmTime: Int64 {
        return roiginModel.alarmTime
    }

    var minutes: Int32 {
        return roiginModel.minutes
    }

    var identifier: String

    let roiginModel: CalendarAlarm

    init(pb: CalendarAlarm) {
        self.roiginModel = pb
        self.identifier = "\(pb.eventID)"
    }

    static func getCalendarAlarmEntity(from reminder: Rust.CalendarReminder) -> CalendarAlarmEntity {
        var alarm = CalendarAlarm()
        alarm.eventID = Int32(reminder.eventID) ?? 0
        alarm.title = reminder.title
        alarm.startTime = reminder.startTime
        alarm.endTime = reminder.endTime
        alarm.alarmTime = reminder.originalTime
        alarm.minutes = reminder.minutes
        let pbAlarm = PBAlarm(pb: alarm)
        return pbAlarm
    }
}
