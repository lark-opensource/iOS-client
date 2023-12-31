//   
//   VideoChatLiveActionByteLiveRequest.swift
//   ByteViewNetwork
// 
//  Created by hubo on 2023/2/9.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 改变直播状态(企业直播)
/// - LIVE_MEETING_ACTION_BYTE_LIVE = 2396
/// - ServerPB_Videochat_live_VideoChatLiveActionByteLiveRequest
public struct VideoChatLiveActionByteLiveRequest {
    public static let command: NetworkCommand = .server(.liveMeetingActionByteLive)
    public init(meetingId: String, action: UpdateLiveActionByteLive) {
        self.meetingId = meetingId
        self.action = action
    }

    public var meetingId: String

    public var action: UpdateLiveActionByteLive

    public var requester: ByteviewUser?

    public var livePermission: LivePermissionByteLive?

    /// 直播layout设置
    public var layoutStyle: LiveLayout?

    /// 直播中是否允许留言
    public var enableLiveComment: Bool?

    /// 指定用户
    public var members: [LivePermissionMemberByteLive]?

}

public enum UpdateLiveActionByteLive: Int, Hashable {
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

    public init(action: UpdateLiveAction) {
        switch action {
        case .unknown:
            self = .unknown
            return
        case .start:
            self = .start
            return
        case .stop:
            self = .stop
            return
        case .hostAccept:
            self = .hostAccept
            return
        case .hostRefuse:
            self = .hostRefuse
            return
        case .participantRequestStart:
            self = .participantRequestStart
            return
        case .voteAccept:
            self = .voteAccept
            return
        case .voteRefuse:
            self = .voteRefuse
            return
        case .liveSetting:
            self = .liveSetting
            return
        }
    }
}

extension VideoChatLiveActionByteLiveRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_live_VideoChatLiveActionByteLiveRequest
    func toProtobuf() throws -> ProtobufType {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.action = .init(rawValue: action.rawValue) ?? .unknown
        if let user = requester {
            request.requester = user.serverPbType
        }
        if let livePermission = livePermission {
            request.livePermission = .init(rawValue: livePermission.rawValue) ?? .byteLivePermissionUnknown
        }
        if let enableLiveComment = enableLiveComment {
            request.enableLiveComment = enableLiveComment
        }
        if let layout = layoutStyle {
            request.layoutStyle = .init(rawValue: layout.rawValue) ?? .styleUnknown
        }
        if let members = members {
            var mList: [ServerPB_Videochat_live_LivePermissionMemberByteLive] = []
            for item in members {
                mList.append(item.toProtobuf())
            }
            request.members = mList
        }
        return request
    }
}
