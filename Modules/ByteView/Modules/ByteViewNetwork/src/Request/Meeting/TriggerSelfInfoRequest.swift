//
//  TriggerSelfInfoRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

public struct TriggerSelfInfoRequest {
    public static let command: NetworkCommand = .rust(.trigPushSelfInfo)
    public init() {}
}

extension TriggerSelfInfoRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_TrigPushSelfInfoRequest
    func toProtobuf() throws -> Videoconference_V1_TrigPushSelfInfoRequest {
        ProtobufType()
    }
}
