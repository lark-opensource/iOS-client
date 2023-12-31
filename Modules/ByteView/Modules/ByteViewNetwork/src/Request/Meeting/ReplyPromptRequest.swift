//
//  ReplyPromptRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - REPLY_VIDEO_CHAT_PROMPT = 2371
/// - ServerPB_Videochat_ReplyVideoChatPromptRequest
public struct ReplyPromptRequest {
    public static let command: NetworkCommand = .server(.replyVideoChatPrompt)
    public init(promptId: String, type: VideoChatPrompt.TypeEnum, action: Action) {
        self.promptId = promptId
        self.type = type
        self.action = action
    }

    public var promptId: String

    public var type: VideoChatPrompt.TypeEnum

    public var action: Action

    public enum Action: Int, Equatable {
        case cancel // = 0
        case confirm // = 1
    }
}

extension ReplyPromptRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_ReplyVideoChatPromptRequest
    func toProtobuf() throws -> ServerPB_Videochat_ReplyVideoChatPromptRequest {
        var request = ProtobufType()
        request.promptID = promptId
        request.type = .init(rawValue: type.rawValue) ?? .unknownType
        switch action {
        case .cancel:
            request.action = .cancel
        case .confirm:
            request.action = .confirm
        }
        return request
    }
}
