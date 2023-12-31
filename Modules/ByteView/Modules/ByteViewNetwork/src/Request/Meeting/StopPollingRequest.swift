//
//  StopPollingRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - STOP_BYTEVIEW_POLLING = 2305
/// - Videoconference_V1_StopByteviewPollingRequest
public struct StopPollingRequest {
    public static let command: NetworkCommand = .rust(.stopByteviewPolling)
    public init(meetingId: String, type: MeetingPollingType) {
        self.meetingId = meetingId
        self.type = type
    }

    /// 结束双通道的会议id
    public var meetingId: String

    public var type: MeetingPollingType
}

extension StopPollingRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_StopByteviewPollingRequest
    func toProtobuf() throws -> Videoconference_V1_StopByteviewPollingRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.serviceType = .init(rawValue: type.rawValue) ?? .unknown
        return request
    }
}
