//
//  Array+MultiCalendarSearchModel.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/22.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation

extension Array where Element == MultiCalendarSearchModel {

    /// 更新owner日历
    func updateOwnerCalendar(_ calendars: [CalendarModel]) -> [MultiCalendarSearchModel] {
        var ownerCalendarIds = [String]()
        for calendar in calendars where calendar.selfAccessRole == .owner {
            ownerCalendarIds.append(calendar.getCalendarPB().serverID)
        }

        return self.map({ (content) -> MultiCalendarSearchModel in
            var newContent = content
            newContent.isOwner = ownerCalendarIds.contains(content.calendarID)
            return newContent
        })
    }

    /// 更新订阅状态数据
    func updateSubscribeStatus(_ calendars: [CalendarModel]) -> [MultiCalendarSearchModel] {
        let userCalendars = calendars.map({ (calendarModel) -> String in
            return calendarModel.serverId
        })
        return self.map({ (content) -> MultiCalendarSearchModel in
            var newContent = content
            if newContent.subscribeStatus != .privated {
                newContent.subscribeStatus = userCalendars.contains(content.calendarID) ? .subscribed : .noSubscribe
            }
            return newContent
        })
    }
}
