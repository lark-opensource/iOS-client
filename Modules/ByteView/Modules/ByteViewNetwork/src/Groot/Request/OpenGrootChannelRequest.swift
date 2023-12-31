//
//  OpenGrootChannelRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 开启channel
/// - OPEN_GROOT_CHANNEL
/// - Videoconference_V1_OpenGrootChannelRequest
struct OpenGrootChannelRequest {
    static let command: NetworkCommand = .rust(.openGrootChannel)
    typealias Response = OpenGrootChannelResponse

    init(channel: GrootChannel, initDownVersion: Int64?, useUpVersionFromSource: Bool = false) {
        self.channel = channel
        self.initDownVersion = initDownVersion
        self.useUpVersionFromSource = useUpVersionFromSource
    }

    var channel: GrootChannel

    var initDownVersion: Int64?

    var useUpVersionFromSource: Bool
}

/// - Videoconference_V1_OpenGrootChannelResponse
struct OpenGrootChannelResponse {

    var status: PushGrootChannelStatus
}

extension OpenGrootChannelRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_OpenGrootChannelRequest
    func toProtobuf() throws -> ProtobufType {
        var request = ProtobufType()
        request.channelMeta = channel.pbType
        request.useUpVersionFromSource = useUpVersionFromSource
        if let ver = initDownVersion {
            request.initDownVersionI64 = ver
        }
        return request
    }
}

extension OpenGrootChannelResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_OpenGrootChannelResponse
    init(pb: Videoconference_V1_OpenGrootChannelResponse) throws {
        self.status = try PushGrootChannelStatus(pb: pb.status)
    }
}
