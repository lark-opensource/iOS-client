//
//  EventEditInput.swift
//  Calendar
//
//  Created by 张威 on 2020/3/10.
//

import Foundation
import EventKit
import RustPB

/// 描述创建日程的初始值
public struct EventCreateContext {
    var summary: String?
    var startDate: Date?
    var endDate: Date?
    var isOpenLarkVC: Bool = true
    var isAllDay: Bool = false
    var timeZone: TimeZone = .current
    var attendeeSeeds: [EventAttendeeSeed] = []
    // 指定 `chatIdForSharing`，创建完日程后，会尝试将日程分享到对应的群组
    var chatIdForSharing: String?
    var meetingRooms: [(fromResource: Rust.MeetingRoom, buildingName: String, tenantId: String)] = []
    var calendarID: String?
    var rrule: String?
    var isFromAI: Bool = false
    var myAiUid: String?
}

enum EventEditInput {
    // 新建非本地日程
    case createWithContext(EventCreateContext)
    // 编辑非本地日程
    case editFrom(pbEvent: Rust.Event, pbInstance: Rust.Instance)
    // 编辑本地日程
    case editFromLocal(ekEvent: EKEvent)
    // 复制日程
    case copyWithEvent(pbEvent: CalendarEvent, pbInstance: Rust.Instance)
    // 新建 webinar 日程
    case createWebinar
    // 编辑 webinar 日程
    case editWebinar(pbEvent: Rust.Event, pbInstance: Rust.Instance)
}

extension EventEditInput {
    // 描述是否是新建类型的日程
    var isFromCreating: Bool {
        switch self {
        case .createWithContext, .copyWithEvent, .createWebinar:
            return true
        case .editFrom, .editFromLocal, .editWebinar:
            return false
        }
    }

    var isWebinarScene: Bool {
        switch self {
        case .createWebinar, .editWebinar:
            return true
        case .createWithContext, .editFrom, .editFromLocal, .copyWithEvent:
            return false
        }
    }

    var chatIdForSharing: String? {
        if case let .createWithContext(context) = self {
            return context.chatIdForSharing
        } else {
            return nil
        }
    }

    var isCopy: Bool {
        switch self {
        case .copyWithEvent:
            return true
        case .createWithContext, .editFrom, .editFromLocal, .createWebinar, .editWebinar:
            return false
        }
    }
    
    var isFromAI: Bool {
        if case let .createWithContext(context) = self {
            return context.isFromAI
        } else {
            return false
        }
    }
}
