//
//  UpdateVideoChatRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/1.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 会议控制
/// - UPDATE_VIDEO_CHAT = 2207
/// - Videoconference_V1_UpdateVideoChatRequest
public struct UpdateVideoChatRequest {
    public static let command: NetworkCommand = .rust(.updateVideoChat)
    public typealias Response = UpdateVideoChatResponse

    public init(meetingId: String, action: UpdateVideoChatAction, interactiveId: String?, role: Participant.MeetingRole?, leaveWithSyncRoom: LeaveWithSyncRoomParams?) {
        self.meetingId = meetingId
        self.action = action
        self.interactiveId = interactiveId
        self.role = role
        self.leaveWithSyncRoom = leaveWithSyncRoom
    }

    /// 会议ID
    public var meetingId: String
    public var action: UpdateVideoChatAction
    /// 交互ID，该ID与后端记录的当前交互ID一致时才被视作有效操作。
    public var interactiveId: String?

    /// 操作的目标参会者，例如取消对谁的邀请
    public var larkUserIds: [String] = []
    /// 操作的目标会议室，例如取消邀请会议室
    public var roomIds: [String] = []
    /// 操作的目标电话用户， 例如取消对电话用户的邀请
    public var pstnIds: [String] = []
    /// 3.34新增通用参数，后续新增用户类型不用通过名字区
    public var users: [ByteviewUser] = []
    /// 是否带会议室一并离会
    public var leaveWithSyncRoom: LeaveWithSyncRoomParams?
    /// 请求接口时候的用户角色，webinar会中需求中新增，方便后端查询是否为观众，后续请求需携带
    public var role: Participant.MeetingRole?
}

public enum UpdateVideoChatAction: Equatable {
    /// 接受邀请(isE2EeMeeting)
    case accept(UpdatingParticipantSettings, Bool)
    /// 拒绝邀请
    case refuse
    /// 取消邀请
    case cancel
    /// 离开会议
    case leave
    /// 结束会议
    case end
    /// 通知服务端，客户端收到了会议邀请
    case receivedInvitation
    /// SDK异常
    case sdkException
    /// 终结参与人会议，目前用于应用重启时调用
    case terminate
    /// 离开等候室
    case leaveLobby
    /// 免费时长耗尽
    case trialTimeout
    /// 确认收到静音请求并成功静音
    case mutePushAck(globalSeqId: Int64)
    /// 剩一人自动结束, 客户端到会议自动结束时间去自动结束会议
    case autoEnd
    /// 离会时保持电话音频连接
    case leaveWithoutCallme
    ///因为设备或者网络不安全，离开会议
    case leaveBecauseUnsafe
}

public struct LeaveWithSyncRoomParams {
    public var roomID: String
    public var roomInteractiveID: String

    public init(roomID: String, roomInteractiveID: String) {
        self.roomID = roomID
        self.roomInteractiveID = roomInteractiveID
    }
}

/// Videoconference_V1_UpdateVideoChatResponse
public struct UpdateVideoChatResponse {
    public var videoChatInfo: VideoChatInfo?
    public var lobbyInfo: LobbyInfo?
}

extension UpdateVideoChatRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_UpdateVideoChatRequest

    func toProtobuf() throws -> ProtobufType {
        var request = ProtobufType()
        request.id = meetingId
        if let interactiveId = interactiveId {
            request.interactiveID = interactiveId
        }
        switch action {
        case let .accept(settings, isE2EeMeeting):
            request.action = .accept
            request.participantSettings = settings.pbType
            request.actionTime = .init()
            request.actionTime.accept = Int64(Date().timeIntervalSince1970 * 1000)
            request.isE2EeMeeting = isE2EeMeeting
        case let .mutePushAck(globalSeqId: globalSeqId):
            request.action = .mutePushAck
            request.globalSeqID = globalSeqId
        default:
            request.action = action.pbType
        }
        request.larkUserIds = larkUserIds
        request.roomIds = roomIds
        request.pstnIds = pstnIds
        request.users = users.map({ $0.pbType })
        if let role = role {
            request.role = role.pbType
        }
        if let leaveWithSyncRoom = leaveWithSyncRoom {
            request.leaveWithSyncRoom = leaveWithSyncRoom.pbType
        }
        return request
    }
}

extension UpdateVideoChatResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_UpdateVideoChatResponse
    init(pb: Videoconference_V1_UpdateVideoChatResponse) throws {
        self.videoChatInfo = pb.hasVideoChatInfo ? pb.videoChatInfo.vcType : nil
        self.lobbyInfo = pb.hasJoinMeetingLobby ? pb.joinMeetingLobby.vcType : nil
    }
}

private extension LeaveWithSyncRoomParams {
    var pbType: Videoconference_V1_LeaveWithSyncRoomParams {
        var params = Videoconference_V1_LeaveWithSyncRoomParams()
        params.roomID = roomID
        params.roomInteractiveID = roomInteractiveID
        return params
    }
}

private extension UpdateVideoChatAction {
    var pbType: UpdateVideoChatRequest.ProtobufType.Action {
        switch self {
        case .accept:
            return .accept
        case .refuse:
            return .refuse
        case .cancel:
            return .cancel
        case .leave:
            return .leave
        case .end:
            return .end
        case .receivedInvitation:
            return .receivedInvitation
        case .sdkException:
            return .sdkException
        case .terminate:
            return .terminate
        case .leaveLobby:
            return .leaveLobby
        case .trialTimeout:
            return .trialTimeout
        case .mutePushAck:
            return .mutePushAck
        case .autoEnd:
            return .autoEnd
        case .leaveWithoutCallme:
            return .leaveWithoutCallme
        case .leaveBecauseUnsafe:
            return .leaveBecauseUnsafe
        }
    }
}
