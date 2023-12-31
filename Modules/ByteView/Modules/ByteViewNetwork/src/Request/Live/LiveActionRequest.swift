//
//  LiveActionRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 改变直播状态
/// - LIVE_MEETING_ACTION = 2380
/// - ServerPB_Videochat_VideoChatLiveActionRequest
public struct LiveActionRequest {
    public static let command: NetworkCommand = .server(.liveMeetingAction)

    public init(meetingId: String, action: UpdateLiveAction) {
        self.meetingId = meetingId
        self.action = action
    }

    public var meetingId: String

    public var action: UpdateLiveAction

    public var requester: ByteviewUser?

    /// 仅用于Action为投票场景
    public var voteId: String?

    public var privilege: LivePrivilege?

    /// 直播layout设置
    public var layoutStyle: LiveLayout?

    /// 直播中是否允许留言
    public var enableLiveComment: Bool?

    /// 是否开启直播回放
    public var enablePlayback: Bool?

    /// 指定用户
    public var members: [LivePermissionMember]?
}

public enum UpdateLiveAction: Int, Hashable {
    case unknown // = 0
    case start // = 1
    case stop // = 2

    /// 主持人接受
    case hostAccept // = 3

    /// 主持人拒绝
    case hostRefuse // = 4

    /// 参会人请求开始
    case participantRequestStart // = 5

    /// 参会人投票同意直播
    case voteAccept // = 6

    /// 参会人投票拒绝直播
    case voteRefuse // = 7

    /// 直播设置
    case liveSetting // = 8
}

extension LiveActionRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_VideoChatLiveActionRequest
    func toProtobuf() throws -> ServerPB_Videochat_VideoChatLiveActionRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.action = .init(rawValue: action.rawValue) ?? .unknown
        if let id = voteId {
            request.voteID = id
        }
        if let user = requester {
            request.requester = user.serverPbType
        }
        if let privilege = privilege {
            request.privilege = .init(rawValue: privilege.rawValue) ?? .previlegeUnknown
        }
        if let enableChat = enableLiveComment {
            request.enableLiveComment = enableChat
        }
        if let enablePlayback = enablePlayback {
            request.enablePlayback = enablePlayback
        }
        if let layout = layoutStyle {
            request.layoutStyle = .init(rawValue: layout.rawValue) ?? .styleUnknown
        }
        if let members = members {
            var mList: [ServerPB_Videochat_InMeetingData.LiveMeetingData.LivePermissionMember] = []
            for item in members {
                mList.append(item.toProtobuf())
            }
            request.members = mList
        }
        return request
    }
}
