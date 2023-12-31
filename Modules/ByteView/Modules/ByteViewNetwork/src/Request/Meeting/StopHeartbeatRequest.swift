//
//  StopHeartbeatRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - STOP_BYTEVIEW_HEARTBEAT = 2302
/// - Videoconference_V1_StopByteviewHeartbeatRequest
public struct StopHeartbeatRequest {
    public static let command: NetworkCommand = .rust(.stopByteviewHeartbeat)
    public init(meetingId: String, type: MeetingHeartbeatType) {
        self.meetingId = meetingId
        self.type = type
    }

    public var meetingId: String

    public var type: MeetingHeartbeatType
}

extension StopHeartbeatRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_StopByteviewHeartbeatRequest
    func toProtobuf() throws -> Videoconference_V1_StopByteviewHeartbeatRequest {
        var request = ProtobufType()
        request.serviceType = .init(rawValue: type.rawValue) ?? .unknown
        request.token = meetingId
        return request
    }
}
