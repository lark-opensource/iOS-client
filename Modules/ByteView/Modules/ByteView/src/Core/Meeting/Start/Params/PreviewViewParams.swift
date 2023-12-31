//
//  PreviewViewParams.swift
//  ByteView
//
//  Created by kiri on 2022/8/5.
//

import Foundation
import ByteViewNetwork

struct PreviewViewParams {
    let id: String
    let idType: PreviewIdType
    let topic: String?
    let isLTR: Bool
    let isWebinarAttendee: Bool
    let entryParams: PreviewEntryParams

    var source: MeetingEntrySource { entryParams.source }
    var fromLink: Bool { entryParams.fromLink }
    var isWebinar: Bool { entryParams.isWebinar }
    let isJoinMeeting: Bool

    init(id: String, idType: PreviewIdType, topic: String?, isLTR: Bool = true, isJoinMeeting: Bool = true, isWebinarAttendee: Bool = false, entryParams: PreviewEntryParams) {
        self.id = id
        self.idType = idType
        self.topic = topic
        self.isJoinMeeting = isJoinMeeting
        self.isLTR = isLTR
        self.isWebinarAttendee = isWebinarAttendee
        self.entryParams = entryParams
    }
}

enum PreviewIdType: EnumIdentifierEquatable {
    case createMeeting
    case meetingNumber
    case meetingId(chatId: String?, messageId: String?)
    case meetingIdWithGroupId(String)
    case groupId
    case groupIdWithUniqueId(String)
    /// 日历id
    case uniqueId(instance: CalendarInstanceIdentifier)
    /// 面试UniqueID
    case interviewUid(role: ParticipantRole?)
    /// 开放平台，预约号
    case reservationId
}


extension PreviewViewParams: CustomStringConvertible {
    var description: String {
        "PreviewViewParams(id: \(id), idType: \(idType), source: \(source), isJoinMeeting: \(isJoinMeeting), isWebinar: \(isWebinar), isWebinarAttendee: \(isWebinarAttendee), isE2EeMeeting:\(entryParams.isE2EeMeeting), fromLink: \(fromLink), hasTopic: \(topic != nil))"
    }
}
