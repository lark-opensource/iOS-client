//
//  PreviewEntryParams.swift
//  ByteView
//
//  Created by lutingting on 2023/8/7.
//

import Foundation
import ByteViewNetwork

struct PreviewEntryParams: EntryParams {
    let id: String
    let idType: EntryIdType
    let source: MeetingEntrySource
    let entryType: EntryType = .preview
    let isCall: Bool = false
    let fromLink: Bool
    let isJoinMeeting: Bool
    let isWebinar: Bool
    let isE2EeMeeting: Bool
    let isInterview: Bool

    var topic: String {
        switch self.idType {
        case .meetingId(let topic, _, _):
            return topic
        case .uniqueId(let topic, _):
            return topic
        case .interviewUid(_, let topic):
            return topic
        default:
            return I18n.View_G_ServerNoTitle
        }
    }

    init(id: String, idType: EntryIdType, source: MeetingEntrySource, fromLink: Bool = false, isJoinMeeting: Bool = true, isWebinar: Bool = false, isE2EeMeeting: Bool = false, isInterview: Bool = false) {
        self.id = id
        self.idType = idType
        self.source = source
        self.fromLink = fromLink
        self.isJoinMeeting = isJoinMeeting
        self.isWebinar = isWebinar
        self.isE2EeMeeting = isE2EeMeeting
        self.isInterview = isInterview
    }
}

extension PreviewEntryParams: CustomDebugStringConvertible, CustomStringConvertible {
    var debugDescription: String { description }
    var description: String {
        "PreviewEntryParams(id: \(id), idType: \(idType), source: \(source), fromLink: \(fromLink), isJoinMeeting: \(isJoinMeeting), isWebinar: \(isWebinar), isE2EeMeeting: \(isE2EeMeeting)"
    }
}


extension PreviewEntryParams {

    static func createMeeting(source: MeetingEntrySource) -> PreviewEntryParams {
        PreviewEntryParams(id: "0", idType: .createMeeting, source: source, isJoinMeeting: false, isWebinar: false)
    }

    static func meetingNumber(_ number: String, source: MeetingEntrySource, isWebinar: Bool) -> PreviewEntryParams {
        PreviewEntryParams(id: number, idType: .meetingNumber, source: source, isWebinar: isWebinar)
    }

    static func meetingId(_ meetingId: String, source: MeetingEntrySource, topic: String, isE2EeMeeting: Bool, chatID: String?, messageID: String?, isWebinar: Bool, isInterview: Bool = false) -> PreviewEntryParams {
        let title = topic.isEmpty ? I18n.View_G_ServerNoTitle : topic
        var params = PreviewEntryParams(id: meetingId, idType: .meetingId(topic: title, chatId: chatID, messageId: messageID), source: source, isWebinar: isWebinar, isE2EeMeeting: isE2EeMeeting, isInterview: isInterview)
        return params
    }

    static func group(id: String, source: MeetingEntrySource, isE2EeMeeting: Bool, isJoinMeeting: Bool = true, isWebinar: Bool) -> PreviewEntryParams {
        var params = PreviewEntryParams(id: id, idType: .groupId, source: source, isJoinMeeting: isJoinMeeting, isWebinar: isWebinar, isE2EeMeeting: isE2EeMeeting)
        return params
    }

    static func calendar(uniqueId: String, source: MeetingEntrySource, topic: String?, fromLink: Bool, instance: CalendarInstanceIdentifier, isJoinMeeting: Bool = true, isWebinar: Bool) -> PreviewEntryParams {
        let title = topic.isEmpty ? I18n.View_G_ServerNoTitle : topic ?? I18n.View_G_ServerNoTitle
        var params = PreviewEntryParams(id: uniqueId, idType: .uniqueId(topic: title, instance: instance), source: source, fromLink: fromLink, isJoinMeeting: isJoinMeeting, isWebinar: isWebinar)
        return params
    }

    static func interview(uid: String, role: ParticipantRole?, isWebinar: Bool) -> PreviewEntryParams {
        var params = PreviewEntryParams(id: uid, idType: .interviewUid(role: role, topic: I18n.View_M_VideoInterview), source: .interview, fromLink: true, isWebinar: isWebinar)
        return params
    }

    static func openPlatform(uniqueId: String, isWebinar: Bool) -> PreviewEntryParams {
        var params = PreviewEntryParams(id: uniqueId, idType: .reservationId, source: .openPlatform, fromLink: true, isWebinar: isWebinar)
        return params
    }
}

extension PreviewEntryParams {
    func toPreviewViewParams(topic: String, isLTR: Bool = true, isJoinMeeting: Bool, isWebinarAttendee: Bool) -> PreviewViewParams {
        return PreviewViewParams(id: id, idType: idType.toPreviewIdType(), topic: topic, isLTR: isLTR, isJoinMeeting: isJoinMeeting, isWebinarAttendee: isWebinarAttendee, entryParams: self)
    }

    func toGroupPreviewViewParams(with meetingId: String, topic: String, isWebinar: Bool) -> PreviewViewParams {
        let title = topic.isEmpty ? I18n.View_G_ServerNoTitle : topic
        return PreviewViewParams(id: meetingId, idType: .meetingIdWithGroupId(id), topic: title, entryParams: self)
    }

    func toCalendarGroupPreviewViewParams(with uniqueId: String, topic: String, isJoinMeeting: Bool, isWebinar: Bool) -> PreviewViewParams {
        let title = topic.isEmpty ? I18n.View_G_ServerNoTitle : topic
        return PreviewViewParams(id: id, idType: .groupIdWithUniqueId(uniqueId), topic: title, isJoinMeeting: isJoinMeeting, entryParams: self)
    }
}
