//
//  VoicePrintPullStatusRequest.swift
//  ByteViewNetwork
//
//  Created by panzaofeng on 2022/4/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - ServerPB_Voiceprint_VoicePrintPullStatusRequest
public struct VoicePrintPullStatusRequest {
    public static let command: NetworkCommand = .server(.voicePrintPullStatus)
    public typealias Response = VoicePrintPullStatusResponse

    public init(userId: String, tenantId: String) {
        self.userId = userId
        self.tenantId = tenantId
    }

    public var userId: String

    public var tenantId: String
}


public struct VoicePrintPullStatusResponse {
    public var voiceprintStatusInfo: VoiceprintStatusInfo
}

/// ServerPB_Voiceprint_VoicePrintStatusInfo
public struct VoiceprintStatusInfo {
    public var voiceprintStatus: VoiceprintStatus
}

/// ServerPB_Voiceprint_VoicePrintStatus
public enum VoiceprintStatus: Int {
    /// 未注册
    case none
    /// 已注册
    case enrolled
}


extension VoicePrintPullStatusRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Voiceprint_VoicePrintPullStatusRequest
    func toProtobuf() throws -> ServerPB_Voiceprint_VoicePrintPullStatusRequest {
        ProtobufType()
    }
}

extension VoicePrintPullStatusResponse: RustResponse {
    typealias ProtobufType = ServerPB_Voiceprint_VoicePrintPullStatusResponse
    init(pb: ServerPB_Voiceprint_VoicePrintPullStatusResponse) throws {
        self.voiceprintStatusInfo = pb.voicePrintStatusInfo.vcType
    }
}

extension ServerPB_Voiceprint_VoicePrintStatusInfo {
    var vcType: VoiceprintStatusInfo {
        VoiceprintStatusInfo(voiceprintStatus: self.voicePrintStatus.vcType)
    }
}

private extension ServerPB_Voiceprint_VoicePrintStatus {
    var vcType: VoiceprintStatus {
        switch self {
        case .enrolled:
            return .enrolled
        @unknown default:
            return .none
        }
    }
}
