//
//  StartPollingRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - START_BYTEVIEW_POLLING = 2304
/// - Videoconference_V1_StartByteviewPollingRequest
public struct StartPollingRequest {
    public static let command: NetworkCommand = .rust(.startByteviewPolling)
    public init(meetingId: String, type: MeetingPollingType) {
        self.meetingId = meetingId
        self.type = type
    }

    /// 开启双通道的会议id
    public var meetingId: String

    /// 开始轮询的类型
    public var type: MeetingPollingType
}

extension StartPollingRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_StartByteviewPollingRequest
    func toProtobuf() throws -> Videoconference_V1_StartByteviewPollingRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.serviceType = .init(rawValue: type.rawValue) ?? .unknown
        return request
    }
}
