//
//  CalendarMeetingModel.swift
//  Calendar
//
//  Created by jiayi zou on 2018/6/21.
//  Copyright © 2018年 EE. All rights reserved.
//

import RustPB

public enum ScrollType {
    /// 会议群横幅
    case none
    /// 会议群横幅
    case eventInfo
    /// 会议群转成普通群前往设置的条幅
    case meetingTransferChat
}

struct CalendarMeetingModel {
    private var pb: RustPB.Calendar_V1_Meeting
    private let shouldShowMeetingTransfer: Bool

    var id: String {
        return pb.id
    }

    var chatId: String {
        return pb.chatID
    }

    var firstEnter: Bool {
        return pb.isFirstEntrance
    }

    var scrollType: ScrollType {
        guard pb.shouldShowScroll || shouldShowMeetingTransfer  else {
            return .none
        }
        return shouldShowMeetingTransfer ? .meetingTransferChat : .eventInfo
    }

    /// 是否展示会议的横幅
    var shouldShowScroll: Bool {
        return pb.shouldShowScroll || shouldShowMeetingTransfer
    }

    var eventMeetingChatExtra: EventMeetingChatExtra {
        return pb.eventMeetingChatExtra
    }

    init(from meeting: RustPB.Calendar_V1_Meeting, shouldShowMeetingTransfer: Bool) {
        self.pb = meeting
        self.shouldShowMeetingTransfer = shouldShowMeetingTransfer
    }
}
