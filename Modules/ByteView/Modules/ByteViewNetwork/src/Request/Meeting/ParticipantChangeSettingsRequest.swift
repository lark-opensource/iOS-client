//
//  UpdateParticipantSettingsRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/1.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 参会者修改设置
/// - PARTICIPANT_CHANGE_SETTINGS = 2310
/// - Videoconference_V1_ParticipantChangeSettingsRequest
public struct ParticipantChangeSettingsRequest {
    public static let command: NetworkCommand = .rust(.participantChangeSettings)
    public static let defaultOptions: NetworkRequestOptions? = [.keepOrder]

    public init(meetingId: String, breakoutRoomId: String?, requestedByHost: Bool = false, earlyPush: Bool? = nil, role: Participant.MeetingRole?) {
        self.meetingId = meetingId
        self.requestedByHost = requestedByHost
        self.earlyPush = earlyPush
        self.breakoutRoomId = breakoutRoomId
        self.role = role
    }

    public var meetingId: String
    public var requestedByHost: Bool
    public var breakoutRoomId: String?
    /// 是否请求成功前就push
    public var earlyPush: Bool?

    public var changeAudioReason: ChangeAudioReason?
    public var role: Participant.MeetingRole?

    public var participantSettings = UpdatingParticipantSettings()

    public enum ChangeAudioReason: Int, Hashable {
        case changeAudio // = 0  主动修改
        case cancelCallMe // = 1 取消电话音频
    }
}

extension ParticipantChangeSettingsRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_ParticipantChangeSettingsRequest
    func toProtobuf() throws -> Videoconference_V1_ParticipantChangeSettingsRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutRoomId) {
            request.breakoutRoomID = id
        }
        if let earlyPush = earlyPush { // 是否预设成功
            request.earlyPush = earlyPush
        }
        request.requestedByHost = requestedByHost
        if let value = changeAudioReason {
            request.changeAudioReason = .init(rawValue: value.rawValue) ?? .changeAudio
        }
        request.participantSettings = participantSettings.pbType
        if let role = role {
            request.role = role.pbType
        }
        return request
    }
}
