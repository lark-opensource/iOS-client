//   
//   ByteLiveBotSendMessageRequest.swift
//   ByteViewNetwork
// 
//  Created by hubo on 2023/6/25.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//   


import Foundation
import ServerPB

/// Command_BYTE_LIVE_BOT_SEND_MESSAGE
public struct ByteLiveBotSendMessageRequest {
    public static let command: NetworkCommand = .server(.byteLiveBotSendMessage)

    public init() {}

    public enum ByteLiveBotMessageType: Int, Hashable {
        case unknow // = 0
        case applyStartLive // = 1
    }
    let messageType: ByteLiveBotMessageType = .applyStartLive
}

extension ByteLiveBotSendMessageRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_live_ByteLiveBotSendMessageRequest
    func toProtobuf() throws -> ServerPB_Videochat_live_ByteLiveBotSendMessageRequest {
        var pb = ProtobufType()
        pb.messageType = ServerPB_Videochat_live_ByteLiveBotSendMessageRequest.ByteLiveBotMessageType(rawValue: messageType.rawValue) ?? .unknown
        return pb
    }
}
