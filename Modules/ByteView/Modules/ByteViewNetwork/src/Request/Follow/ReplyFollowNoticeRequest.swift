//
//  ReplyFollowNoticeRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - REPLY_FOLLOW_NOTICE = 2332
/// - ServerPB_Videochat_ReplyFollowNoticeRequest
public struct ReplyFollowNoticeRequest {
    public static let command: NetworkCommand = .server(.replyFollowNotice)
    public init(meetingId: String, breakoutRoomId: String?, messageId: String, action: Action) {
        self.meetingId = meetingId
        self.breakoutRoomId = breakoutRoomId
        self.messageId = messageId
        self.action = action
    }

    public var meetingId: String

    public var messageId: String

    public var action: Action

    /// 分组会议id
    public var breakoutRoomId: String?

    public enum Action: Int, Equatable {
        case agree = 1
        case reject // = 2
    }
}

extension ReplyFollowNoticeRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_ReplyFollowNoticeRequest
    func toProtobuf() throws -> ServerPB_Videochat_ReplyFollowNoticeRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.messageID = messageId
        switch action {
        case .agree:
            request.action = .approve
        case .reject:
            request.action = .reject
        }
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutRoomId) {
            request.associateType = .breakoutMeeting
            request.breakoutMeetingID = id
        } else {
            request.associateType = .meeting
        }
        return request
    }
}
