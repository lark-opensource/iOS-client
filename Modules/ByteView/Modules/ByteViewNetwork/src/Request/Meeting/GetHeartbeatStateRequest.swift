//
//  GetHeartbeatStateRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - GET_VC_HEARTBEAT_STATE = 89391
/// - Videoconference_V1_GetVCHeartbeatStateRequest
public struct GetHeartbeatStateRequest {
    public static let command: NetworkCommand = .rust(.getVcHeartbeatState)
    public typealias Response = GetHeartbeatStateResponse

    public init() {}
}

/// - Videoconference_V1_GetVCHeartbeatStateResponse
public struct GetHeartbeatStateResponse {

    public var isHeartbeatNormal: Bool
}

extension GetHeartbeatStateRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetVCHeartbeatStateRequest
    func toProtobuf() throws -> Videoconference_V1_GetVCHeartbeatStateRequest {
        ProtobufType()
    }
}

extension GetHeartbeatStateResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetVCHeartbeatStateResponse
    init(pb: Videoconference_V1_GetVCHeartbeatStateResponse) throws {
        self.isHeartbeatNormal = pb.isHeartbeatNormal
    }
}
