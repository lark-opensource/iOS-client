//
//  LocalInstance+Ext.swift
//  Calendar
//
//  Created by 张威 on 2020/9/6.
//

import CalendarFoundation

extension Local.Instance {

    var canEdit: Bool {
        (calendar?.allowsContentModifications ?? false)
            || (self.organizer?.isCurrentUser ?? false)
    }

    /// 是否有完整编辑权限
    var isEditable: Bool {
        // 如果一个日程没有organizer，那么大概率是自己创建的日程（小概率是订阅的，但是那样日历不可修改）
        // 或者organizer是自身
        // 这里暂时先不考虑writer编辑的情况
        if let result = value(forKey: "isEditable") as? Bool {
            return result
        }
        return canEdit
    }

    var displayType: CalendarEvent.DisplayType {
        // 目前我没有找到使用caldav方式订阅无权限日历的方法，如果有这里还要改~
        guard let calendar = calendar else {
            return .limited
        }
        return calendar.type == .subscription ? .limited : .full
    }

    var selfAttendeeStatus: CalendarEventAttendeeEntity.Status {
        getSelfAttendee()?.participantStatus.toCalendarEvnetAttendeeStatus() ?? .accept
    }

    var eventColor: ColorIndex {
        if let color = calendar?.cgColor {
            return LocalCalHelper.getColor(color: color)
        }
        assertionFailureLog()
        return .carmine
    }

    var calColor: ColorIndex {
        if let color = calendar?.cgColor {
            return LocalCalHelper.getColor(color: color)
        }
        assertionFailureLog()
        return .carmine
    }

}
