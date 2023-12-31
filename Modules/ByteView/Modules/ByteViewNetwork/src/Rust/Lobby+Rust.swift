//
//  Lobby+Rust.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import RustPB

typealias PBLobbyInfo = Videoconference_V1_JoinMeetingLobby
typealias PBLobbyParticipant = Videoconference_V1_VCLobbyParticipant
typealias PBPreLobbyParticipant = Videoconference_V1_VCPreLobbyParticipant

extension PBLobbyInfo {
    var vcType: LobbyInfo {
        .init(isJoinLobby: isJoinMeetingLobby, isJoinPreLobby: isJoinPreLobby,
              lobbyParticipant: hasLobbyParticipant ? lobbyParticipant.vcType : nil,
              preLobbyParticipant: hasPreLobbyParticipant ? preLobbyParticipant.vcType : nil, meetingSubType: .init(rawValue: meetingType.rawValue) ?? .default)
    }
}

extension PBLobbyParticipant {
    var vcType: LobbyParticipant {
        .init(meetingId: meetingID, interactiveId: interactiveID, user: user.vcType,
              isMicrophoneMuted: hasIsMicrophoneMuted ? isMicrophoneMuted : nil,
              isCameraMuted: hasIsCameraMuted ? isCameraMuted : nil,
              isStatusWait: isStatusWait, isInApproval: isInApproval, isLarkGuest: isLarkGuest == "1",
              joinLobbyTime: joinLobbyTime, nickName: nickName,
              leaveReason: .init(rawValue: leaveReason.rawValue) ?? .unknown,
              tenantId: userTenantID, tenantTag: tenantTag.vcType,
              bindId: bindID, bindType: bindType.vcType, seqID: seqID,
              targetToJoinTogether: hasTargetToJoinTogether ? targetToJoinTogether.vcType : nil,
              pstnMainAddress: hasPstnMainAddress ? pstnMainAddress : nil,
              participantMeetingRole: .init(rawValue: participantMeetingRole.rawValue) ?? .participant,
              joinResaon: .init(rawValue: joinReason.rawValue) ?? .unknownJoinReason,
              moveOperator: moveOperator.vcType,
              inMeetingName: inMeetingName,
              participantSettings: participantSettings.vcType)
    }
}

extension PBPreLobbyParticipant {
    var vcType: PreLobbyParticipant {
        .init(meetingId: meetingID, isStatusWait: isStatusWait, user: user.vcType, isLarkGuest: isLarkGuest == "1",
              joinLobbyTime: joinLobbyTime, leaveReason: .init(rawValue: leaveReason.rawValue) ?? .unknown,
              targetToJoinTogether: hasTargetToJoinTogether ? targetToJoinTogether.vcType : nil,
              participantMeetingRole: .init(rawValue: participantMeetingRole.rawValue) ?? .participant,
              participantSettings: participantSettings.vcType)
    }
}
