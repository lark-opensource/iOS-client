//
//  SetIceStateRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// ICE means rtc connection channel
/// - SET_VC_ICE_STATE = 89390
/// - Videoconference_V1_SetVCICEStateRequest
public struct SetIceStateRequest {
    public static let command: NetworkCommand = .rust(.setVcIceState)

    public init(isIceNormal: Bool) {
        self.isIceNormal = isIceNormal
    }

    public var isIceNormal: Bool
}

extension SetIceStateRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_SetVCICEStateRequest
    func toProtobuf() throws -> Videoconference_V1_SetVCICEStateRequest {
        var request = ProtobufType()
        request.isIceNormal = isIceNormal
        return request
    }
}
