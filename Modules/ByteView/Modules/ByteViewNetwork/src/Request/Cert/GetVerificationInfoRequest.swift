//
//  GetVerificationInfoRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 客户端根据扫码token获取认证信息
/// - LIVE_MEETING_GET_VERIFICATION_INFO
/// - ServerPB_Videochat_GetVerificationInfoRequest
public struct GetVerificationInfoRequest {
    public static let command: NetworkCommand = .server(.liveMeetingGetVerificationInfo)
    public typealias Response = GetVerificationInfoResponse

    public init(token: String) {
        self.token = token
    }

    public var token: String
}

/// ServerPB_Videochat_GetVerificationInfoResponse
public struct GetVerificationInfoResponse {

    public var appID: Int32

    public var scene: String
}

extension GetVerificationInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetVerificationInfoRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetVerificationInfoRequest {
        var request = ProtobufType()
        request.token = token
        return request
    }
}

extension GetVerificationInfoResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetVerificationInfoResponse
    init(pb: ServerPB_Videochat_GetVerificationInfoResponse) throws {
        self.appID = pb.appID
        self.scene = pb.scene
    }
}
