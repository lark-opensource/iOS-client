//
//  LobbyInfo.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 用户是否进入等候室，用于join接口response中,
/// - Videoconference_V1_JoinMeetingLobby
public struct LobbyInfo: Equatable {
    public init(isJoinLobby: Bool, isJoinPreLobby: Bool,
                lobbyParticipant: LobbyParticipant?, preLobbyParticipant: PreLobbyParticipant?, meetingSubType: MeetingSubType) {
        self.isJoinLobby = isJoinLobby
        self.isJoinPreLobby = isJoinPreLobby
        self.lobbyParticipant = lobbyParticipant
        self.preLobbyParticipant = preLobbyParticipant
        self.meetingSubType = meetingSubType
    }

    /// 是否加入了会议等候室
    public var isJoinLobby: Bool

    public var isJoinPreLobby: Bool

    public var lobbyParticipant: LobbyParticipant?

    public var preLobbyParticipant: PreLobbyParticipant?

    public var meetingSubType: MeetingSubType

    public var meetingId: String {
        if let p = lobbyParticipant {
            return p.meetingId
        } else if let p = preLobbyParticipant {
            return p.meetingId
        } else {
            return ""
        }
    }
}

public extension LobbyInfo {
    var isBeMovedIn: Bool { lobbyParticipant?.joinReason == .hostMove }
}
