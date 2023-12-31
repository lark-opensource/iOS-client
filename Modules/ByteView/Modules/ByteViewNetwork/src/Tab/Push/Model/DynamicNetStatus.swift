//
//  DynamicNetStatus.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// PUSH_DYNAMIC_NET_STATUS = 5046
/// - Basic_V1_DynamicNetStatusResponse
public struct DynamicNetStatusResponse {
    public var netStatus: DynamicNetStatus
}

public enum DynamicNetStatus: Int, Hashable {
    case unknown // = 0
    case excellent // = 1
    case evaluating // = 2
    case weak // = 3
    case netUnavailable // = 4
    case serviceUnavailable // = 5
    case offline // = 6
}

extension DynamicNetStatusResponse: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Basic_V1_DynamicNetStatusResponse

    init(pb: Basic_V1_DynamicNetStatusResponse) {
        self.netStatus = .init(rawValue: pb.netStatus.rawValue) ?? .unknown
    }
}
