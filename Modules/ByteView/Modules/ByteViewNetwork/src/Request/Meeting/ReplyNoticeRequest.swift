//
//  ReplyNoticeRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 处理popup类型的notice
/// - REPLY_VIDEO_CHAT_NOTICE = 2216
/// - Videoconference_V1_ReplyVideoChatNoticeRequest
public struct ReplyNoticeRequest {
    public static let command: NetworkCommand = .rust(.replyVideoChatNotice)

    public init(noticeId: String, action: Action) {
        self.noticeId = noticeId
        self.action = action
    }

    public var noticeId: String

    public var action: Action

    public enum Action: Int, Equatable {
        case cancel // = 0
        case confirm // = 1
    }
}

extension ReplyNoticeRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_ReplyVideoChatNoticeRequest
    func toProtobuf() throws -> Videoconference_V1_ReplyVideoChatNoticeRequest {
        var request = ProtobufType()
        request.noticeID = noticeId
        switch action {
        case .cancel:
            request.action = .cancel
        case .confirm:
            request.action = .confirm
        }
        return request
    }
}
