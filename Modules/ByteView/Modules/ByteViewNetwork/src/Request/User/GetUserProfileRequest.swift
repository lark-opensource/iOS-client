//
//  GetUserProfileRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// GetUserProfile: async + sync
/// - Contact_V1_GetUserProfileRequest
public struct GetUserProfileRequest {
    public static let command: NetworkCommand = .rust(.getUserProfile)
    public typealias Response = GetUserProfileResponse

    public init(userId: String) {
        self.userId = userId
    }

    public var userId: String
}

/// - Contact_V1_GetUserProfileResponse
public struct GetUserProfileResponse {

    public var company: Company

    public struct Company {

        public var tenantName: String
    }
}

extension GetUserProfileRequest: RustRequestWithResponse {
    typealias ProtobufType = Contact_V1_GetUserProfileRequest
    func toProtobuf() throws -> Contact_V1_GetUserProfileRequest {
        var request = ProtobufType()
        request.userID = userId
        request.isFromServer = true
        request.isSelf = false
        return request
    }
}

extension GetUserProfileResponse: RustResponse {
    typealias ProtobufType = Contact_V1_GetUserProfileResponse
    init(pb: Contact_V1_GetUserProfileResponse) throws {
        self.company = Company(tenantName: pb.company.tenantName)
    }
}
