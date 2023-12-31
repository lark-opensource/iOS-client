//
//  GetPhoneNumberAttributionRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - GET_PHONE_NUMBER_ATTRIBUTION = 89545
/// - ServerPB_Videochat_GetPhoneNumberAttributtonRequest
public struct GetPhoneNumberAttributionRequest {
    public static let command: NetworkCommand = .server(.getPhoneNumberAttribution)
    public typealias Response = GetPhoneNumberAttributionResponse

    public init(enterprisePhoneNumber: String) {
        self.enterprisePhoneNumber = enterprisePhoneNumber
    }

    public var enterprisePhoneNumber: String
}

/// - ServerPB_Videochat_GetPhoneNumberAttributtonResponse
public struct GetPhoneNumberAttributionResponse {

    public var province: String

    public var isp: String

    public var countryCode: String

    public var ipPhoneLarkUserName: String

    public var isIpPhone: Bool

    public var ipPhoneUserID: String

    public var ipPhoneUserAvatarKey: String

}

extension GetPhoneNumberAttributionRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetPhoneNumberAttributtonRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetPhoneNumberAttributtonRequest {
        var request = ProtobufType()
        request.enterprisePhoneNumber = enterprisePhoneNumber
        return request
    }
}

extension GetPhoneNumberAttributionResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetPhoneNumberAttributtonResponse
    init(pb: ServerPB_Videochat_GetPhoneNumberAttributtonResponse) throws {
        self.province = pb.province
        self.isp = pb.isp
        self.countryCode = pb.countryCode
        self.ipPhoneLarkUserName = pb.ipPhoneLarkUserName
        self.isIpPhone = pb.isIpPhone
        self.ipPhoneUserID = pb.ipPhoneUserID
        self.ipPhoneUserAvatarKey = pb.ipPhoneUserAvatarKey
    }
}

extension GetPhoneNumberAttributionRequest: CustomStringConvertible {
    public var description: String {
        String(indent: "GetPhoneNumberAttributionRequest",
               "enterprisePhoneNumber: \(enterprisePhoneNumber.count)"
        )
    }
}
