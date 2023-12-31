//
//  GetAdminPermissionInfoRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 描述：获取权限
/// - GET_ADMIN_PERMISSION_INFO = 1011791
/// - ServerPB_Role_GetAdminPermissionInfoRequest
public struct GetAdminPermissionInfoRequest {
    public static let command: NetworkCommand = .server(.getAdminPermissionInfo)
    public typealias Response = GetAdminPermissionInfoResponse
    public init() {}
}

/// ServerPB_Role_GetAdminPermissionInfoResponse
public struct GetAdminPermissionInfoResponse: Equatable {

    public init(isSuperAdministrator: Bool) {
        self.isSuperAdministrator = isSuperAdministrator
    }

    public var isSuperAdministrator: Bool
}

extension GetAdminPermissionInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Role_GetAdminPermissionInfoRequest

    func toProtobuf() throws -> ServerPB_Role_GetAdminPermissionInfoRequest {
        ProtobufType()
    }
}

extension GetAdminPermissionInfoResponse: RustResponse {
    typealias ProtobufType = ServerPB_Role_GetAdminPermissionInfoResponse
    init(pb: ServerPB_Role_GetAdminPermissionInfoResponse) throws {
        self.isSuperAdministrator = pb.isSuperAdministrator
    }
}
