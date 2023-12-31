//
//  GetLivePermissionRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 判断是否需要实名认证
/// - LIVE_MEETING_GET_LIVE_PERMISSION
/// - ServerPB_Videochat_GetLivePermissionRequest
public struct GetLivePermissionRequest {
    public static let command: NetworkCommand = .server(.liveMeetingGetLivePermission)
    public typealias Response = GetLivePermissionResponse
    public init() {}
}

/// - ServerPB_Videochat_GetLivePermissionResponse
public struct GetLivePermissionResponse {

    /// 是否需要认证
    public var needVerification: Bool
}

extension GetLivePermissionRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetLivePermissionRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetLivePermissionRequest {
        ProtobufType()
    }
}

extension GetLivePermissionResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetLivePermissionResponse
    init(pb: ServerPB_Videochat_GetLivePermissionResponse) throws {
        self.needVerification = pb.needVerification
    }
}
