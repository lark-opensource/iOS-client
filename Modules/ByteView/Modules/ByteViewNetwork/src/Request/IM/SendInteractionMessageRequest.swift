//
//  SendInteractionMessageRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 发送互动消息接口
/// - Videoconference_V1_SendVideoChatInteractionMessageRequest
public struct SendInteractionMessageRequest {
    public static let command: NetworkCommand = .rust(.sendVideoChatInteractionMessage)
    public typealias Response = SendInteractionMessageResponse

    public init(meetingId: String, content: Content, role: Participant.MeetingRole) {
        self.meetingId = meetingId
        self.content = content
        self.role = role
    }

    public var meetingId: String

    public var content: Content

    public var role: Participant.MeetingRole

    /// 使用uuid即可，确保不会碰撞, cid这个命名遵从 IM 的命名规则
    public let cid: String = UUID().uuidString

    public enum Content {
        case reaction(String)
        case text(MessageRichText?)
        case encrypted(Data?)
    }
}

/// Videoconference_V1_SendVideoChatInteractionMessageResponse
public struct SendInteractionMessageResponse {

    public var message: VideoChatInteractionMessage
}

private typealias PBReactionMessageContent = Videoconference_V1_ReactionMessageContent
private typealias PBTextMessageContent = Videoconference_V1_TextMessageContent
private typealias PBEncryptedContent = Videoconference_V1_EncryptedMessageContent
extension SendInteractionMessageRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_SendVideoChatInteractionMessageRequest
    func toProtobuf() throws -> Videoconference_V1_SendVideoChatInteractionMessageRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.cid = cid
        request.role = role.pbType
        switch content {
        case .reaction(let key):
            var reactionCotent = PBReactionMessageContent()
            reactionCotent.content = key
            reactionCotent.count = 1
            request.type = .reaction
            request.reactionContent = reactionCotent
        case .text(let text):
            var textContent = PBTextMessageContent()
            if let text = text {
                textContent.content = text
            }
            request.type = .text
            request.textContent = textContent
        case .encrypted(let data):
            var encryptedContent = PBEncryptedContent()
            if let data = data {
                encryptedContent.content = data
            }
            request.type = .encrypted
            request.encryptedContent = encryptedContent
        }
        return request
    }
}

extension SendInteractionMessageResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_SendVideoChatInteractionMessageResponse
    init(pb: Videoconference_V1_SendVideoChatInteractionMessageResponse) throws {
        self.message = pb.message.vcType
    }
}

extension SendInteractionMessageRequest: CustomStringConvertible {
    public var description: String {
        String(
            indent: "SendInteractionMessageRequest",
            "meetingId: \(meetingId)",
            "cid: \(cid)",
            "type: \(type)"
        )
    }

    private var type: VideoChatInteractionMessage.TypeEnum {
        switch content {
        case .text:
            return .text
        case .reaction:
            return .reaction
        case .encrypted:
            return .encrypted
        }
    }
}
