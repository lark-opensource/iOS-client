//
//  CancelEnterprisePhoneRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - CANCEL_ENTERPRISE_PHONE = 89451
/// - ServerPB_Videochat_CancelEnterprisePhoneRequest
public struct CancelEnterprisePhoneRequest {
    public static let command: NetworkCommand = .server(.cancelEnterprisePhone)

    public init(enterprisePhoneId: String, chatId: String?) {
        self.enterprisePhoneId = enterprisePhoneId
        self.chatId = chatId
    }

    public var enterprisePhoneId: String

    public var chatId: String?
}

extension CancelEnterprisePhoneRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_CancelEnterprisePhoneRequest
    func toProtobuf() throws -> ServerPB_Videochat_CancelEnterprisePhoneRequest {
        var request = ProtobufType()
        request.enterprisePhoneID = enterprisePhoneId
        if let id = chatId {
            request.chatID = id
        }
        return request
    }
}
