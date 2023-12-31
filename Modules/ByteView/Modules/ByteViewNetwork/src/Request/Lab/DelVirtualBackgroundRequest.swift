//
//  DelVirtualBackgroundRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - Videoconference_V1_DelVcVirtualBackgroundRequest
public struct DelVirtualBackgroundRequest {
    public static let command: NetworkCommand = .rust(.delVcVirtualBackground)

    public init(key: String) {
        self.key = key
    }

    public var key: String
}

extension DelVirtualBackgroundRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_DelVcVirtualBackgroundRequest
    func toProtobuf() throws -> Videoconference_V1_DelVcVirtualBackgroundRequest {
        var request = ProtobufType()
        request.key = key
        return request
    }
}
