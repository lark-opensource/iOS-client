//
//  GetEnterprisePhoneConfigRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// ServerPB_Videochat_GetEnterprisePhoneConfigResponse.EnterpriseCallType
public enum EnterpriseCallType: Int, Hashable, Codable, CustomStringConvertible {
    case direct = 1 // 直呼模式
    case back2Back = 2 // 双呼模式

    public var description: String {
        switch self {
        case .direct:
            return "direct"
        case .back2Back:
            return "back2Back"
        }
    }
}

/// 描述: 获取企业办公电话配置开关
/// - GET_ENTERPRISE_PHONE_CONFIG = 89453
/// - ServerPB_Videochat_GetEnterprisePhoneConfigRequest
public struct GetEnterprisePhoneConfigRequest {
    public static let command: NetworkCommand = .server(.getEnterprisePhoneConfig)
    public typealias Response = GetEnterprisePhoneConfigResponse
    public static var defaultOptions: NetworkRequestOptions? = [.shouldPrintResponse]

    public init() {}
}

/// ServerPB_Videochat_GetEnterprisePhoneConfigResponse
public struct GetEnterprisePhoneConfigResponse: Equatable, Codable {
    public var authorized: Bool = false
    public var scopeAny: Bool = false
    public var canCallOversea: Bool = false
    public var callType: EnterpriseCallType = .back2Back

    public init() {}

    public init(authorized: Bool, scopeAny: Bool, canCallOversea: Bool, callType: EnterpriseCallType) {
        self.authorized = authorized
        self.scopeAny = scopeAny
        self.canCallOversea = canCallOversea
        self.callType = callType
    }
}

extension GetEnterprisePhoneConfigRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetEnterprisePhoneConfigRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetEnterprisePhoneConfigRequest {
        ProtobufType()
    }
}

extension GetEnterprisePhoneConfigResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetEnterprisePhoneConfigResponse
    init(pb: ServerPB_Videochat_GetEnterprisePhoneConfigResponse) throws {
        self.authorized = pb.authorized
        self.scopeAny = pb.scopeAny
        self.canCallOversea = pb.canCallOversea
        self.callType = .init(rawValue: pb.callType.rawValue) ?? .back2Back
    }
}

extension GetEnterprisePhoneConfigResponse: CustomStringConvertible {
    public var description: String {
        String(name: "GetEnterprisePhoneConfigResponse", dropNil: true, [
            "authorized": authorized, "scopeAny": scopeAny, "canCallOversea": canCallOversea, "callType": callType
        ])
    }
}
