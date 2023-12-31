//
//  SetVirtualBackgroundRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - Videoconference_V1_SetVcVirtualBackgroundRequest
public struct SetVirtualBackgroundRequest {
    public static let command: NetworkCommand = .rust(.setVcVirtualBackground)
    public typealias Response = SetVirtualBackgroundResponse

    public init(name: String, path: String) {
        self.name = name
        self.path = path
    }

    public var name: String

    public var path: String
}

/// - Videoconference_V1_SetVcVirtualBackgroundResponse
public struct SetVirtualBackgroundResponse {

    public var info: VirtualBackgroundInfo?
}

extension SetVirtualBackgroundRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_SetVcVirtualBackgroundRequest
    func toProtobuf() throws -> Videoconference_V1_SetVcVirtualBackgroundRequest {
        var customBg = ProtobufType.CustomVirtualBackground()
        customBg.name = name
        customBg.path = path
        customBg.source = UIDevice.current.userInterfaceIdiom == .pad ? .appIpad : .appIos
        var request = ProtobufType()
        request.sets = [customBg]
        return request
    }
}

extension SetVirtualBackgroundResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_SetVcVirtualBackgroundResponse
    init(pb: Videoconference_V1_SetVcVirtualBackgroundResponse) throws {
        self.info = pb.infos.first?.vcType
    }
}
