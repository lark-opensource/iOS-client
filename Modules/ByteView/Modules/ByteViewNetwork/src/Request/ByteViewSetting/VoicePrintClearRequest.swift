//
//  VoicePrintClearRequest.swift
//  ByteViewNetwork
//
//  Created by panzaofeng on 2022/4/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - ServerPB_Voiceprint_VoicePrintClearRequest
public struct VoicePrintClearRequest {
    public static let command: NetworkCommand = .server(.voicePrintClear)
    public typealias Response = VoicePrintClearResponse

    public init(userId: String, tenantId: String) {
        self.userId = userId
        self.tenantId = tenantId
    }

    public var userId: String

    public var tenantId: String
}


public struct VoicePrintClearResponse {
    public var voiceprintStatusInfo: VoiceprintStatusInfo
}

extension VoicePrintClearRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Voiceprint_VoicePrintClearRequest
    func toProtobuf() throws -> ServerPB_Voiceprint_VoicePrintClearRequest {
        ProtobufType()
    }
}

extension VoicePrintClearResponse: RustResponse {
    typealias ProtobufType = ServerPB_Voiceprint_VoicePrintClearResponse
    init(pb: ServerPB_Voiceprint_VoicePrintClearResponse) throws {
        self.voiceprintStatusInfo = pb.voicePrintStatusInfo.vcType
    }
}
