//
//  PullInteractionMessagesRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 拉取消息接口,需要确保与后端完全一致
/// - Videoconference_V1_PullVideoChatInteractionMessagesRequest
public struct PullInteractionMessagesRequest {
    public static let command: NetworkCommand = .rust(.pullVideoChatInteractionMessages)
    public typealias Response = PullInteractionMessagesResponse

    public init(meetingId: String, position: Int32, isPrevious: Bool, count: Int32, role: Participant.MeetingRole) {
        self.meetingId = meetingId
        self.position = position
        self.isPrevious = isPrevious
        self.count = count
        self.role = role
    }

    public var meetingId: String

    /// 从position开始往前拉取N条消息，N = count。
    /// - 传入-1表示拉取最新的N条消息
    public var position: Int32

    /// is_previous = true，表示拉取position之前的数据。反之表示拉取之后的数据
    public var isPrevious: Bool

    /// count = -1时，表示拉取position之前/之后的所有数据
    public var count: Int32

    public var role: Participant.MeetingRole
}

/// Videoconference_V1_PullVideoChatInteractionMessagesResponse
public struct PullInteractionMessagesResponse {

    public var messages: [VideoChatInteractionMessage]
    public var expiredMsgPosition: Int32?
}

extension PullInteractionMessagesRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_PullVideoChatInteractionMessagesRequest
    func toProtobuf() throws -> Videoconference_V1_PullVideoChatInteractionMessagesRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.position = position
        request.isPrevious = isPrevious
        request.count = count
        request.role = role.pbType
        return request
    }
}

extension PullInteractionMessagesResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_PullVideoChatInteractionMessagesResponse
    init(pb: Videoconference_V1_PullVideoChatInteractionMessagesResponse) throws {
        self.messages = pb.messages.map({ $0.vcType })
        self.expiredMsgPosition = pb.hasExpiredMsgPosition ? pb.expiredMsgPosition : nil
    }
}
