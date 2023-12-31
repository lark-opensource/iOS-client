//
//  GetSIPInviteInfoRequest.swift
//  ByteViewNetwork
//
//  Created by admin on 2022/6/2.
//

import Foundation
import ServerPB

// GET_SIP_INVITE_INFO = 89456
// ServerPB_Videochat_GetSIPInviteInfoRequest
public struct GetSIPInviteInfoRequest {
    public static let command: NetworkCommand = .server(.getSipInviteInfo)
    public typealias Response = GetSIPInviteInfoResponse

    public init(tenantID: String) {
        self.tenantID = tenantID
    }

    public var tenantID: String
}

/// - ServerPB_Videochat_GetSIPInviteInfoResponse
public struct GetSIPInviteInfoResponse {
    public struct H323Access: Equatable {
        public init(ip: String, country: String) {
            self.ip = ip
            self.country = country
        }

        public var ip: String
        public var country: String
    }

    public var sipDomain: String
    public var h323AccessList: [H323Access]
}

extension GetSIPInviteInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetSIPInviteInfoRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetSIPInviteInfoRequest {
        var request = ProtobufType()
        request.tenantID = self.tenantID
        return request
    }
}

extension GetSIPInviteInfoResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetSIPInviteInfoResponse
    init(pb: ServerPB_Videochat_GetSIPInviteInfoResponse) throws {
        self.sipDomain = pb.sipDomain
        self.h323AccessList = pb.h323AccessList.map{ $0.vcType}
    }
}
