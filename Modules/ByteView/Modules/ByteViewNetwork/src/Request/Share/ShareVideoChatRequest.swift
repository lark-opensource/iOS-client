//
//  ShareVideoChatRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 分享卡片，SHARE_VIDEO_CHAT = 2209
/// - ServerPB_Videochat_ShareVideoChatRequest
public struct ShareVideoChatRequest {
    public static let command: NetworkCommand = .server(.shareVideoChat)
    public typealias Response = ShareVideoChatResponse

    public init(meetingId: String, userIds: [String], groupIds: [String]) {
        self.meetingId = meetingId
        self.userIds = userIds
        self.groupIds = groupIds
    }

    /// 会议ID
    public var meetingId: String

    /// 需要分享到的用户id
    public var userIds: [String]

    /// 需要分享到的群组id
    public var groupIds: [String]

    /// 请求的途径
    public var shareFrom: ShareFrom = .unknown

    /// 分享时附带的文字消息
    public var piggybackText: String?

    /// 要分享的meeting链接信息
    public var shareMessage: String = ""

    public enum ShareFrom: Int, Hashable {
        case unknown // = 0
        case fromQrCode // = 1
        case fromVc // = 2
        case fromVctab // = 3
    }
}

/// Videoconference_V1_ShareVideoChatResponse
public struct ShareVideoChatResponse {

    /// 被禁言的群组id
    public var bannedGroupIds: [String]

    public var targetUserPermissions: TargetUserPermissions

    public enum TargetUserPermissions: Int, Hashable {
        case all // = 0
        case partial // = 1
        case none // = 2
    }
}

extension ShareVideoChatRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_ShareVideoChatRequest
    func toProtobuf() throws -> ServerPB_Videochat_ShareVideoChatRequest {
        var request = ProtobufType()
        request.id = meetingId
        request.shareMessage = shareMessage
        request.userIds = userIds
        request.groupIds = groupIds
        if let s = piggybackText {
            request.piggybackText = s
        }
        if shareFrom != .unknown {
            request.shareFrom = .init(rawValue: shareFrom.rawValue) ?? .unknown
        }
        return request
    }
}

extension ShareVideoChatResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_ShareVideoChatResponse
    init(pb: ServerPB_Videochat_ShareVideoChatResponse) throws {
        self.bannedGroupIds = pb.bannedGroupIds
        self.targetUserPermissions = .init(rawValue: pb.targetUserPermissions.rawValue) ?? .all
    }
}
