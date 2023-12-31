//
//  GetAppConfigRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - GET_APP_CONFIG
/// - Basic_V1_GetAppConfigRequest
public struct GetAppConfigRequest {
    public static let command: NetworkCommand = .rust(.getAppConfig)
    public typealias Response = GetAppConfigResponse

    public init() {}
}

public struct GetAppConfigResponse: Equatable {
    public init(videochatParticipantLimit: Int64) {
        self.videochatParticipantLimit = videochatParticipantLimit
    }

    public var videochatParticipantLimit: Int64
}

extension GetAppConfigRequest: RustRequestWithResponse {
    typealias ProtobufType = Basic_V1_GetAppConfigRequest
    func toProtobuf() throws -> Basic_V1_GetAppConfigRequest {
        ProtobufType()
    }
}

extension GetAppConfigResponse: RustResponse {
    typealias ProtobufType = Basic_V1_GetAppConfigResponse
    init(pb: Basic_V1_GetAppConfigResponse) throws {
        self.videochatParticipantLimit = pb.appConfig.billingPackage.videochatParticipantLimit
    }
}
