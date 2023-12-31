//
//  TrigPushFullMeetingInfoRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 会触发推送全量参会人、CombinedInfo、ExtraInfo
/// - Videoconference_V1_TrigPushFullMeetingInfoRequest
public struct TrigPushFullMeetingInfoRequest {
    public static let command: NetworkCommand = .rust(.trigPushFullMeetingInfo)
    public init() {}
}

extension TrigPushFullMeetingInfoRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_TrigPushFullMeetingInfoRequest
    func toProtobuf() throws -> Videoconference_V1_TrigPushFullMeetingInfoRequest {
        ProtobufType()
    }
}
