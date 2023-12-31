//
// MeetingParams.swift
//  ByteView
//
//  Created by lutingting on 2022/6/7.
//

import Foundation
import ByteViewNetwork
import ByteViewMeeting
import ByteViewSetting

struct JoinMeetingParams {
    let joinType: JoinMeetingRequest.JoinType
    let meetSetting: MicCameraSetting
    var requestType: RequestType = .default
    var role: ParticipantRole?
    var audioMode: ParticipantSettings.AudioMode?
    var topicInfo: JoinMeetingRequest.TopicInfo?
    var participantType: ParticipantType = .larkUser
    var nearbyRoomID: String?
    var targetToJoinTogether: ByteviewUser?
    var calendarSource: JoinCalendarMeetingRequest.EntrySource = .fromUnknown
    var calendarInstance: CalendarInstanceIdentifier?
    var webinarAttendeeBecomeParticipant: Bool?
    var isE2EeMeeting: Bool?
    var replaceJoin: Bool?

    enum RequestType: String, Hashable, CustomStringConvertible {
        case `default`
        case calendar
        case interview

        var description: String { rawValue }
    }
}

extension JoinMeetingParams: CustomStringConvertible {
    var description: String {
        var s = "MeetingParams(joinType: \(joinType), meetSetting: \(meetSetting), requestType: \(requestType)"
        s.append(", role: \(role)")
        s.append(", audioMode: \(audioMode)")
        s.append(", hasTopic: \(topicInfo != nil)")
        s.append(", nearbyRoomID: \(nearbyRoomID)")
        s.append(", targetToJoinTogether: \(targetToJoinTogether)")
        s.append(", calendarSource: \(calendarSource)")
        s.append(", isE2EeMeeting: \(isE2EeMeeting)")
        s.append(", replaceJoin: \(replaceJoin)")
        s.append(")")
        return s
    }
}

extension JoinMeetingParams {
    func toParticipantSettings() -> UpdatingParticipantSettings {
        var settings = UpdatingParticipantSettings()
        settings.isMicrophoneMuted = !meetSetting.isMicrophoneEnabled
        settings.isCameraMuted = !meetSetting.isCameraEnabled
        settings.microphoneStatus = Privacy.audioAuthorized ? .normal : .noPermission
        settings.cameraStatus = Privacy.videoAuthorized ? .normal : .noPermission
        settings.audioMode = audioMode
        return settings
    }
}
