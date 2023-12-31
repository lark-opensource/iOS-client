//
//  VCManageNotify.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Videoconference_V1_VCManageNotify
/// - PUSH_VC_MANAGE_NOTIFY = 89343
public struct VCManageNotify {
    public init(meetingID: String, notificationType: NotificationType, lobbyParticipants: [LobbyParticipant],
                needHelpUsers: [BreakoutRoomUser], helper: BreakoutRoomUser) {
        self.meetingID = meetingID
        self.notificationType = notificationType
        self.lobbyParticipants = lobbyParticipants
        self.needHelpUsers = needHelpUsers
        self.helper = helper
    }

    public var meetingID: String

    public var notificationType: NotificationType

    public var lobbyParticipants: [LobbyParticipant]

    /// 分组会议中请求帮助的用户
    public var needHelpUsers: [BreakoutRoomUser]

    /// 响应分组讨论帮助请求的主持人或联席主持人
    public var helper: BreakoutRoomUser

    public enum NotificationType: Int, Hashable {
        case unknown // = 0

        /// 会议等候室
        case meetinglobby // = 1

        /// 举手
        case putUpHands // = 2

        /// 放下手
        case putDownHands // = 3

        /// 分组讨论用户请求帮助
        case breakoutRoomUserNeedHelp // = 4

        /// 分组讨论用户获得帮助
        case breakoutRoomUserGotHelp // 5

        /// 分组讨论开始
        case breakoutRoomStarted // 6

        /// 会议人数达到一定数量，给主持人/联系主持人推送提醒
        case largeMeetingTriggered // 7
    }

    public struct BreakoutRoomUser: Equatable {
        public var breakoutRoomId: String
        public var user: ByteviewUser
        public init(breakoutRoomID: String, user: ByteviewUser) {
            self.breakoutRoomId = breakoutRoomID
            self.user = user
        }
    }
}

extension VCManageNotify.BreakoutRoomUser {
    init(pb: Videoconference_V1_VCManageNotify.BreakoutRoomUser) {
        self.breakoutRoomId = "\(pb.breakoutRoomID)"
        self.user = pb.user.vcType
    }
}

extension VCManageNotify: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_VCManageNotify
    init(pb: Videoconference_V1_VCManageNotify) {
        self.init(meetingID: pb.meetingID, notificationType: .init(rawValue: pb.notificationType.rawValue) ?? .unknown,
                  lobbyParticipants: pb.lobbyParticipants.map({ $0.vcType }),
                  needHelpUsers: pb.needHelpUsers.map { BreakoutRoomUser(pb: $0) },
                  helper: .init(pb: pb.helper))
    }
}
