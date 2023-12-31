//
//  EKEvent+Extension.swift
//  Calendar
//
//  Created by Rico on 2021/4/22.
//

import Foundation
import EventKit
import CalendarFoundation

extension DetailLogicBox where Base == EKEvent {

    /// 是否有完整编辑权限
    var isEditable: Bool {
        //优先使用系统权限, 如果不行则使用Plan B
        //前提条件：日历可修改
        //如果一个日程没有organizer，那么大概率是自己创建的日程（小概率是订阅的，但是那样日历不可修改）
        //或者organizer是自身
        //这里暂时先不考虑writer编辑的情况
        if let result = source.value(forKey: "isEditable") as? Bool {
            return result
        }
        guard let calendar = source.calendar else {
            return false
        }
        return calendar.allowsContentModifications &&
        ((source.organizer == nil) || (source.organizer?.isCurrentUser ?? false ))
    }

    var canDeleteAll: Bool {
        isEditable
    }

    var rrule: String {
        if let rrule = source.recurrenceRules?.first?.iCalendarString() {
            return rrule
        }
        return ""
    }

    var isRecurrence: Bool {
        (source.recurrenceRules?.count ?? 0) > 0
    }

    var isException: Bool {
        source.isDetached
    }

    var isFree: Bool {
        source.availability == .free
    }
}
