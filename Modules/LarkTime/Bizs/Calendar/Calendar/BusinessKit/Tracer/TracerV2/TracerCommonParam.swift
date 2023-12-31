//
//  TracerCommonParam.swift
//  Calendar
//
//  Created by Rico on 2021/6/23.
//

import Foundation
import LKCommonsTracker
import RustPB

typealias TracerCommonParams = TracerCalendarCommonParam & TracerEventCommonParam

// MARK: - 日历公参
enum TracerViewType: String, Encodable {
    /// 列表视图
    case list
    /// 日视图
    case day
    /// 三日视图
    case threeday
    /// 周视图
    case week
    /// 月视图
    case month
    /// 会议室视图
    case meeting
    /// 其他
    case no_value
}

protocol TracerCalendarCommonParam {

    /// 视图类型
    var view_type: TracerViewType? { get set }
}

// MARK: - 日程公参
protocol TracerEventCommonParam {

    /// cal_event_id，对应server_id
    var cal_event_id: String? { get set }

    /// start_time
    var event_start_time: String? { get set }
}

struct CommonParamData : Encodable {
    /// cal_event_id，对应server_id
    var cal_event_id: String = "none"
    /// start_time
    var event_start_time: String = "none"
    ///  组织者
    var is_organizer: Bool?
    /// 是否重复性
    var is_repeated: Bool?
    /// original_time
    var original_time: String = "none"
    /// key
    var uid: String = "none"

    init(instance: RustPB.Calendar_V1_CalendarEventInstance?, event: RustPB.Calendar_V1_CalendarEvent? = nil) {
        if let instance = instance {
            self.cal_event_id = instance.eventServerID
            self.event_start_time = instance.startTime.description
            self.original_time = instance.originalTime.description
            self.uid = instance.key
        }

        if let event = event {
            self.is_organizer = (event.organizerCalendarID == event.calendarID)
            self.is_repeated = !event.rrule.isEmpty
        }
    }

    init(event: RustPB.Calendar_V1_CalendarEvent?, startTime: Int64? = nil) {

        if let event = event {
            self.cal_event_id = event.serverID.isEmpty ? "none" : event.serverID
            self.original_time = event.originalTime.description
            self.uid = event.key.isEmpty ? "none" : event.key
            self.is_organizer = (event.organizerCalendarID == event.calendarID)
            self.is_repeated = !event.rrule.isEmpty
        }

        if let startTime = startTime, startTime != 0 {
            self.event_start_time = startTime.description
        } else {
            self.event_start_time = event?.startTime.description ?? "none"
        }
    }

    init(event: InviteEventCardModel?) {
        if let event = event {
            self.cal_event_id = event.eventServerID
            self.event_start_time = event.startTime?.description ?? "none"
            self.original_time = event.originalTime?.description ?? "none"
            self.uid = event.key ?? "none"
            self.is_repeated = !event.rrule.isEmpty
        }
    }

    init(event: ShareEventCardModel?) {
        if let event = event {
            self.cal_event_id = event.eventID
            self.event_start_time = event.startTime?.description ?? "none"
            self.original_time = event.originalTime.description
            self.uid = event.key
            self.is_repeated = !event.rrule.isEmpty
            self.is_organizer = false
        }
    }
    
    init(event: RSVPCardModel?) {
        if let event = event {
            self.event_start_time = event.startTime?.description ?? "none"
            self.original_time = event.originalTime.description
            self.uid = event.key
            self.is_repeated = !event.rrule.isEmpty
            self.is_organizer = event.calendarID == "\(event.organizerCalendarId)"
        }
    }

    init(calEventId: String? = nil, eventStartTime: String? = nil, isOrganizer: Bool? = nil, isRecurrence: Bool? = nil, originalTime: String? = nil, uid: String? = nil) {
        if let calEventId = calEventId {
            self.cal_event_id = calEventId
        }

        if let eventStartTime = eventStartTime {
            self.event_start_time = eventStartTime
        }

        if let isOrganizer = isOrganizer {
            self.is_organizer = isOrganizer
        }

        if let isRecurrence = isRecurrence {
            self.is_repeated = isRecurrence
        }

        if let originalTime = originalTime {
            self.original_time = originalTime
        }

        if let uid = uid {
            self.uid = uid
        }
    }
}
