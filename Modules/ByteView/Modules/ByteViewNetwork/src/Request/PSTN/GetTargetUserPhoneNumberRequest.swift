//
//  GetTargetUserPhoneNumberResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB
import RustPB

/// - ServerPB_Videochat_GetTargetUserPhoneNumberRequest
public struct GetTargetUserPhoneNumberRequest {
    public static let command: NetworkCommand = .server(.getTargetUserPhoneNumber)
    public typealias Response = GetTargetUserPhoneNumberResponse

    public init(userId: String) {
        self.userId = userId
    }

    public var userId: String
}

/// ServerPB_Videochat_GetTargetUserPhoneNumberResponse
public struct GetTargetUserPhoneNumberResponse {
    public init(phoneNumber: String, displayPhoneNumber: String) {
        self.phoneNumber = phoneNumber
        self.displayPhoneNumber = displayPhoneNumber
    }

    public var phoneNumber: String

    public var displayPhoneNumber: String
}

extension GetTargetUserPhoneNumberRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetTargetUserPhoneNumberRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetTargetUserPhoneNumberRequest {
        var request = ProtobufType()
        request.userID = userId
        return request
    }
}

extension GetTargetUserPhoneNumberResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetTargetUserPhoneNumberResponse
    init(pb: ServerPB_Videochat_GetTargetUserPhoneNumberResponse) throws {
        self.phoneNumber = pb.phoneNumber
        self.displayPhoneNumber = pb.displayPhoneNumber
    }
}

/// - Command_GET_MY_PHONE_NUMBER = 89462
public struct GetCallmePhoneRequest {
    public static let command: NetworkCommand = .server(.getMyPhoneNumber)
    public typealias Response = GetCallmePhoneResponse

    public init() {}
}

public struct GetCallmePhoneResponse: Equatable{
    public init(phoneNumber: String, displayPhoneNumber: String) {
        self.phoneNumber = phoneNumber
        self.displayPhoneNumber = displayPhoneNumber
    }

    public var phoneNumber: String
    public var displayPhoneNumber: String

}

extension GetCallmePhoneRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetMyPhoneNumberRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetMyPhoneNumberRequest {
        ProtobufType()
    }
}

extension GetCallmePhoneResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetMyPhoneNumberResponse
    init(pb: ServerPB_Videochat_GetMyPhoneNumberResponse) throws {
        self.phoneNumber = pb.phoneNumber
        self.displayPhoneNumber = pb.displayPhoneNumber
    }
}

/// - ServerPB_Videochat_GetAdminOrgSettingsRequest
public struct GetAdminOrgSettingsRequest {
    public static let command: NetworkCommand = .server(.getAdminOrgSettings)
    public typealias Response = GetAdminOrgSettingsResponse

    public init(userId: String, tenantID: String, settingKeys: [String]) {
        self.userId = userId
        self.tenantID = tenantID
        self.settingKeys = settingKeys
    }
    public var tenantID: String
    public var userId: String
    public var settingKeys: [String]
}

public struct GetAdminOrgSettingsResponse: Codable, Equatable {
    public init(allowUserChangePstnAudioType: Bool) {
        self.allowUserChangePstnAudioType = allowUserChangePstnAudioType
    }

    /// 是否开启音频切换开关
    public var allowUserChangePstnAudioType: Bool
}

extension GetAdminOrgSettingsRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetAdminOrgSettingsRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetAdminOrgSettingsRequest {
        var request = ProtobufType()
        request.userID = userId
        request.tenantID = tenantID
        request.settingKeys = settingKeys
        return request
    }
}

extension GetAdminOrgSettingsResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetAdminOrgSettingsResponse
    init(pb: ServerPB_Videochat_GetAdminOrgSettingsResponse) throws {
        self.allowUserChangePstnAudioType = pb.allowUserChangePstnAudioType
    }
}
