//
//  StartHeartbeatRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - START_BYTEVIEW_HEARTBEAT = 2301
/// - Videoconference_V1_StartByteviewHeartbeatRequest
public struct StartHeartbeatRequest {
    public static let command: NetworkCommand = .rust(.startByteviewHeartbeat)
    public init(meetingId: String, type: MeetingHeartbeatType) {
        self.meetingId = meetingId
        self.type = type
    }

    public var meetingId: String

    public var type: MeetingHeartbeatType
}

extension StartHeartbeatRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_StartByteviewHeartbeatRequest
    func toProtobuf() throws -> Videoconference_V1_StartByteviewHeartbeatRequest {
        var request = ProtobufType()
        request.serviceType = .init(rawValue: type.rawValue) ?? .unknown
        request.token = meetingId
        request.cycle = 0 // rust不会使用端上的参数，但是参数又是require的，所以传个值就好了
        request.expiredTime = 0 //rust不会使用端上的参数，但是参数又是require的，所以传个值就好了
        return request
    }
}
