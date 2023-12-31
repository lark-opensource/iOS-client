//
//  CalendarInstance+Ext.swift
//  Calendar
//
//  Created by Rico on 2021/8/17.
//

import Foundation
import RustPB

extension RustPB.Calendar_V1_EventInfoInstances {

    // 对于非重复性日程，应该只有一个时间
    var onlyTimeSpan: Calendar_V1_InstanceSpan? {
        guard instanceSpans.count == 1 else {
            assertionFailure("Instance have at least one time, please check business logic!")
            return nil
        }
        return instanceSpans.first
    }

    var startDay: Int32? {
        return onlyTimeSpan?.startDay
    }

    var endDay: Int32? {
        return onlyTimeSpan?.endDay
    }

    var startTime: Int64? {
        return onlyTimeSpan?.startTime
    }

    var endTime: Int64? {
        return onlyTimeSpan?.endTime
    }

}
