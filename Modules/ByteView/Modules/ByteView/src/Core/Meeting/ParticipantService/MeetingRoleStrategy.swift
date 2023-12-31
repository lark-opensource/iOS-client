//
//  MeetingRoleStrategy.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/7/31.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

protocol MeetingRoleStrategy {
    func displayNameFor(role: ParticipantRole, name: String) -> String
    func displayRoomSecondaryNameFor(role: ParticipantRole, name: String) -> String
    func displayAvatarFor(role: ParticipantRole, avatar: AvatarInfo) -> AvatarInfo
    func displayNameByFG(role: ParticipantRole, user: User, enableAnotherName: Bool) -> String

    var showRoomInfo: Bool { get }

    func participantCanBecomeHost(role: ParticipantRole) -> Bool

    func displayTopic(topic: String) -> String

    var meetingNumberVisible: Bool { get }
}

extension MeetingRoleStrategy {
    func displayNameFor(role: ParticipantRole, name: String) -> String {
        displayNameFor(role: role, name: name)
    }
    func displayRoomSecondaryNameFor(role: ParticipantRole, name: String) -> String {
        displayRoomSecondaryNameFor(role: role, name: name)
    }
    func displayAvatarFor(role: ParticipantRole, avatar: AvatarInfo) -> AvatarInfo {
        displayAvatarFor(role: role, avatar: avatar)
    }
    func participantCanBecomeHost(role: ParticipantRole) -> Bool {
        participantCanBecomeHost(role: role)
    }
}

struct DefaultMeetingRoleStrategy: MeetingRoleStrategy {
    func displayNameFor(role: ParticipantRole, name: String) -> String {
        return name
    }

    func displayRoomSecondaryNameFor(role: ParticipantRole, name: String) -> String {
        return name
    }

    func displayAvatarFor(role: ParticipantRole, avatar: AvatarInfo) -> AvatarInfo {
        return avatar
    }

    func displayNameByFG(role: ParticipantRole, user: User, enableAnotherName: Bool) -> String {
        if let inMeetingName = user.inMeetingName, !inMeetingName.isEmpty {
            return inMeetingName
        } else if let nickName = user.nickName, !nickName.isEmpty {
            return nickName
        } else if !user.alias.isEmpty {
            return user.alias
        } else if !user.anotherName.isEmpty && enableAnotherName {
            return user.anotherName
        } else {
            return user.name
        }
    }

    func participantCanBecomeHost(role: ParticipantRole) -> Bool {
        return true
    }

    func displayTopic(topic: String) -> String {
        return topic
    }

    var showRoomInfo: Bool {
        return true
    }

    var meetingNumberVisible: Bool {
        return true
    }
}

struct InterviewerMeetingRoleStrategy: MeetingRoleStrategy {
    func displayNameFor(role: ParticipantRole, name: String) -> String {
        return name
    }

    func displayNameByFG(role: ParticipantRole, user: User, enableAnotherName: Bool) -> String {
        if let inMeetingName = user.inMeetingName, !inMeetingName.isEmpty {
            return inMeetingName
        } else if let nickName = user.nickName, !nickName.isEmpty {
            return nickName
        } else if !user.alias.isEmpty {
            return user.alias
        } else if !user.anotherName.isEmpty && enableAnotherName {
            return user.anotherName
        } else {
            return user.name
        }
    }

    func displayRoomSecondaryNameFor(role: ParticipantRole, name: String) -> String {
        return name
    }

    func displayAvatarFor(role: ParticipantRole, avatar: AvatarInfo) -> AvatarInfo {
        return avatar
    }

    func participantCanBecomeHost(role: ParticipantRole) -> Bool {
        return role != .interviewee
    }

    func displayTopic(topic: String) -> String {
        return I18n.View_M_VideoInterviewNameBraces(topic)
    }

    var showRoomInfo: Bool {
        return true
    }

    var meetingNumberVisible: Bool {
        return true
    }
}

struct CandidateMeetingRoleStrategy: MeetingRoleStrategy {
    func displayNameFor(role: ParticipantRole, name: String) -> String {
        switch role {
        case .interviewee:
            return name
        default:
            return I18n.View_M_Interviewer
        }
    }

    func displayNameByFG(role: ParticipantRole, user: User, enableAnotherName: Bool) -> String {
        switch role {
        case .interviewee:
            return user.name
        default:
            return I18n.View_M_Interviewer
        }
    }

    func displayRoomSecondaryNameFor(role: ParticipantRole, name: String) -> String {
        switch role {
        case .interviewee:
            return name
        default:
            return ""
        }
    }

    func displayAvatarFor(role: ParticipantRole, avatar: AvatarInfo) -> AvatarInfo {
        switch role {
        case .interviewee:
            return avatar
        default:
            return .asset(AvatarResources.interviewer)
        }
    }

    func participantCanBecomeHost(role: ParticipantRole) -> Bool {
        return role != .interviewee
    }

    func displayTopic(topic: String) -> String {
        return I18n.View_M_VideoInterviewNameBraces(topic)
    }

    var showRoomInfo: Bool {
        return false
    }

    var meetingNumberVisible: Bool {
        return false
    }
}
