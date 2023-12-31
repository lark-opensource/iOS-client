//
//  CloseGrootChannelRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 关闭channel
/// - CLOSE_GROOT_CHANNEL
/// - Videoconference_V1_CloseGrootChannelRequest
struct CloseGrootChannelRequest {
    static let command: NetworkCommand = .rust(.closeGrootChannel)

    init(channel: GrootChannel) {
        self.channel = channel
    }

    var channel: GrootChannel
}

extension CloseGrootChannelRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_CloseGrootChannelRequest
    func toProtobuf() throws -> Videoconference_V1_CloseGrootChannelRequest {
        var request = ProtobufType()
        request.channelMeta = channel.pbType
        return request
    }
}
