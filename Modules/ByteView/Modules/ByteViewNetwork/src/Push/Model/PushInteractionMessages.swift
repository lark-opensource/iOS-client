//
//  PushVideoChatInteractionMessages.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 消息推送，包含RichText，暂时放在ByteViewNetwork里
/// - PUSH_VIDEO_CHAT_INTERACTION_MESSAGES = 2360
/// - Videoconference_V1_PushVideoChatInteractionMessages
public struct PushVideoChatInteractionMessages {

    public var messages: [VideoChatInteractionMessage]
    public var expiredMsgPosition: Int32?
}

extension PushVideoChatInteractionMessages: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_PushVideoChatInteractionMessages
    init(pb: Videoconference_V1_PushVideoChatInteractionMessages) {
        self.messages = pb.messages.map({ $0.vcType })
        self.expiredMsgPosition = pb.hasExpiredMsgPosition ? pb.expiredMsgPosition : nil
    }
}
