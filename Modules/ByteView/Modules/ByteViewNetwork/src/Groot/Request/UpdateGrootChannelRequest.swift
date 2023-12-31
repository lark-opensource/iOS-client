//
//  UpdateGrootChannelRequest.swift
//  ByteViewNetwork
//
//  Created by Prontera on 2022/3/24.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 更新channel的down_version
/// UPDATE_GROOT_CHANNEL
/// - Videoconference_V1_UpdateGrootChannelRequest
struct UpdateGrootChannelRequest {
    static let command: NetworkCommand = .rust(.updateGrootChannel)
    typealias Response = UpdateGrootChannelResponse

    init(channel: GrootChannel, downVersion: Int64) {
        self.channel = channel
        self.downVersion = downVersion
    }

    let channel: GrootChannel

    let downVersion: Int64
}

/// - Videoconference_V1_UpdateGrootChannelResponse
struct UpdateGrootChannelResponse {

    var status: PushGrootChannelStatus
}

extension UpdateGrootChannelRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_UpdateGrootChannelRequest
    func toProtobuf() throws -> ProtobufType {
        var request = ProtobufType()
        request.channelMeta = channel.pbType
        request.downVersionI64 = downVersion
        return request
    }
}

extension UpdateGrootChannelResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_UpdateGrootChannelResponse
    init(pb: Videoconference_V1_UpdateGrootChannelResponse) throws {
        self.status = try PushGrootChannelStatus(pb: pb.status)
    }
}
