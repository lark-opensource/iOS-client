//
//  PushGrootChannelStatus.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Rust通知客户端当前channel状态
/// PUSH_GROOT_CHANNEL_STATUS = 89097
/// - Videoconference_V1_PushGrootChannelStatus
public struct PushGrootChannelStatus {
    var channel: GrootChannel
    var status: GrootChannelStatus
}

extension PushGrootChannelStatus: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_PushGrootChannelStatus
    init(pb: Videoconference_V1_PushGrootChannelStatus) throws {
        self.status = .init(rawValue: pb.status.rawValue) ?? .unknown
        self.channel = try GrootChannel(pb: pb.channelMeta)
    }
}
