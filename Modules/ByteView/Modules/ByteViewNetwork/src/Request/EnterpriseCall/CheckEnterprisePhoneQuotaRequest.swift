//
//  CheckEnterprisePhoneQuotaRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - CHECK_ENTERPRISE_PHONE_QUOTA = 89454
/// - ServerPB_Videochat_CheckEnterprisePhoneQuotaRequest
public struct CheckEnterprisePhoneQuotaRequest {
    public static let command: NetworkCommand = .server(.checkEnterprisePhoneQuota)
    public typealias Response = CheckEnterprisePhoneQuotaResponse
    public init() {}
}

/// ServerPB_Videochat_CheckEnterprisePhoneQuotaResponse
public struct CheckEnterprisePhoneQuotaResponse {

    public var date: String

    public var availableEnterprisePhoneAmount: Int32

    public var departmentName: String
}

extension CheckEnterprisePhoneQuotaRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_CheckEnterprisePhoneQuotaRequest
    func toProtobuf() throws -> ServerPB_Videochat_CheckEnterprisePhoneQuotaRequest {
        ProtobufType()
    }
}

extension CheckEnterprisePhoneQuotaResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_CheckEnterprisePhoneQuotaResponse
    init(pb: ServerPB_Videochat_CheckEnterprisePhoneQuotaResponse) throws {
        self.date = pb.date
        self.availableEnterprisePhoneAmount = pb.availableEnterprisePhoneAmount
        self.departmentName = pb.departmentName
    }
}
