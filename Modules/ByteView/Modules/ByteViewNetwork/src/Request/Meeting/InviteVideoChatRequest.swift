//
//  InviteVideoChatRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 邀请加入会议
/// - INVITE_VIDEO_CHAT = 2208
/// - ServerPB_Videochat_InviteVideoChatRequest
public struct InviteVideoChatRequest {
    public static let command: NetworkCommand = .server(.inviteVideoChat)
    public typealias Response = InviteVideoChatResponse

    public init(meetingId: String, userIds: [String], roomIds: [String], pstnInfos: [PSTNInfo], source: InviteType) {
        self.meetingId = meetingId
        self.userIds = userIds
        self.roomIds = roomIds
        self.pstnInfos = pstnInfos
        self.source = source
    }

    /// 会议ID
    public var meetingId: String

    /// 邀请成员
    public var userIds: [String]

    /// 邀请屋子
    public var roomIds: [String]

    /// 邀请电话用户
    public var pstnInfos: [PSTNInfo]

    ///邀请发起类型，如是否从建议列表发起
    public var source: InviteType

    /// 从什么地方发起的邀请
    public enum InviteType: Int {
      case unknown // = 0

      /// 建议列表发起
      case suggestList // = 1
    }

}

/// ServerPB_Videochat_InviteVideoChatResponse
public struct InviteVideoChatResponse {

    /// 邀请失败成员
    public var busyUserIds: [String] = []

    /// 客户端邀请过程，服务端返回与客户端收到推送存在间隙，避免这时候客户端取消邀请拿不到ID
    public var pstnIds: [String] = []

    /// 失败数量
    public var failedCount: Int64

    ///已经发送的sip address到partcipant_id的映射
    public var sipRoomUids: [String: String] = [:]
}

extension InviteVideoChatRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_InviteVideoChatRequest
    func toProtobuf() throws -> ServerPB_Videochat_InviteVideoChatRequest {
        var request = ProtobufType()
        request.id = meetingId
        request.participantIds = userIds
        request.roomIds = roomIds
        request.pstnInfo = pstnInfos.map({ $0.serverPbType })
        request.source = .init(rawValue: source.rawValue) ?? .unknown
        return request
    }
}

extension InviteVideoChatResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_InviteVideoChatResponse
    init(pb: ServerPB_Videochat_InviteVideoChatResponse) throws {
        self.busyUserIds = pb.busyUserIds
        self.pstnIds = pb.pstnIds
        self.failedCount = pb.failedCount
        self.sipRoomUids = pb.sipRoomUids
    }
}
