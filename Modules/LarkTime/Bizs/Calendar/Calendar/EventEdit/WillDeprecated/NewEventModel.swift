//
//  NewEventModel.swift
//  Calendar
//
//  Created by zhu chao on 2018/7/30.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation

// TODO: zhangwei
// 旧编辑页遗留，该清理掉
final class NewEventModel {
    var startTime: Date = Date()
    var endTime: Date? = Date()

    static func defaultNewModel(startTime: Date) -> NewEventModel {
        var start = startTime
        start = formatNewEventTime(start)
        return defaultNewModel(startTime: start, endTime: nil)
    }

    static func defaultNewModel(startTime: Date, endTime: Date? = nil) -> NewEventModel {
        let model = NewEventModel()
        let start = startTime
        model.startTime = start
        if let end = endTime {
            model.endTime = end
        } else {
            model.endTime = nil
        }
        return model
    }

    static func formatNewEventTime(_ date: Date) -> Date {
        var time = date
        if time.minute < 30 {
            time = time.changed(minute: 30)?.truncated([.second, .nanosecond]) ?? Date()
        } else {
            time = (time + 30.minute)?.truncated([.minute, .second, .nanosecond]) ?? Date()
        }
        return time
    }
}
