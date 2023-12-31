//
//  JoinMeetingMessage.swift
//  ByteView
//
//  Created by kiri on 2022/8/5.
//

import Foundation
import ByteViewNetwork

struct JoinMeetingMessage {
    let info: VideoChatInfo
    let type: JoinMeetingMessageType
    let sessionId: String?
    let dependency: (() throws -> MeetingDependency)?

    init(info: VideoChatInfo, type: JoinMeetingMessageType, sessionId: String) {
        self.info = info
        self.type = type
        self.sessionId = sessionId
        self.dependency = nil
    }

    init(info: VideoChatInfo, type: JoinMeetingMessageType, dependency: @escaping () throws -> MeetingDependency) {
        self.info = info
        self.type = type
        self.sessionId = nil
        self.dependency = dependency
    }
}

enum JoinMeetingMessageType: String, CustomStringConvertible, CustomDebugStringConvertible {
    case join
    case joinInterview
    case joinCalendar
    case rejoin
    case push
    case registerClientInfo
    case shareScreenToRoom
    case dualChannelPoll

    var description: String { rawValue }
    var debugDescription: String { rawValue }
}

extension JoinMeetingMessage: EntryParams {

    var id: String { info.id }

    var source: MeetingEntrySource { .init(rawValue: type.rawValue) }

    var entryType: EntryType { .push }

    var isCall: Bool { false }

    var isJoinMeeting: Bool { true }
}
