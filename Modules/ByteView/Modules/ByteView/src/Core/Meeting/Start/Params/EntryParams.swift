//
//  EntryParams.swift
//  ByteView
//
//  Created by lutingting on 2023/8/7.
//

import Foundation
import ByteViewNetwork

enum EntryType {
    case preview
    case noPreview
    case call
    case rejoin
    case push
    case shareToRoom
}
protocol EntryParams {
    var id: String { get }
    var source: MeetingEntrySource { get }
    var entryType: EntryType { get }
    var isCall: Bool { get }
    var isJoinMeeting: Bool { get }
}

protocol CallEntryParams: EntryParams {
    var isVoiceCall: Bool { get }
    var isE2EeMeeting: Bool { get }
}


extension CallEntryParams {
    var entryType: EntryType { .call }
    var isCall: Bool { true }
}


/// 枚举比较相等只比较identifier，不比较关联值
protocol EnumIdentifierEquatable {}
extension EnumIdentifierEquatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.value == rhs.value
    }

    static func != (lhs: Self, rhs: Self) -> Bool {
        return lhs.value != rhs.value
    }

    var value: String? {
        return String(describing: self).components(separatedBy: "(").first
    }
}

enum EntryIdType: EnumIdentifierEquatable {
    case createMeeting
    case meetingNumber
    case meetingId(topic: String, chatId: String?, messageId: String?)
    case groupId
    /// 日历id
    case uniqueId(topic: String, instance: CalendarInstanceIdentifier)
    /// 面试UniqueID
    case interviewUid(role: ParticipantRole?, topic: String)
    /// 开放平台，预约号
    case reservationId

    func toPrecheckIdType() -> JoinMeetingPrecheckRequest.IDType {
        switch self {
        case .meetingId:
            return .meetingid
        case .uniqueId:
            return .uniqueid
        case .createMeeting, .groupId:
            return .groupid
        case .meetingNumber:
            return .meetingno
        case .interviewUid:
            return .interviewuid
        case .reservationId:
            return .reservationID
        }
    }

    func toPreviewIdType() -> PreviewIdType {
        switch self {
        case .createMeeting:
            return .createMeeting
        case .meetingNumber:
            return .meetingNumber
        case .meetingId(_, let chatId, let messageId):
            return .meetingId(chatId: chatId, messageId: messageId)
        case .groupId:
            return .groupId
        case .uniqueId(_, let instance):
            return .uniqueId(instance: instance)
        case .interviewUid(let role, _):
            return .interviewUid(role: role)
        case .reservationId:
            return .reservationId
        }
    }
}

extension EntryIdType: CustomStringConvertible {
    var description: String {
        switch self {
        case .createMeeting:
            return "createMeeting"
        case .meetingNumber:
            return "meetingNumber"
        case .meetingId(_, let chatId, let messageId):
            return "meetingId(chatId: \(chatId), messageId: \(messageId))"
        case .groupId:
            return "groupId"
        case .uniqueId(_, let instance):
            return "uniqueId(id: \(instance.uid)"
        case .interviewUid(let role, _):
            return "interviewUid(role: \(role))"
        case .reservationId:
            return "reservationId"
        }
    }
}
