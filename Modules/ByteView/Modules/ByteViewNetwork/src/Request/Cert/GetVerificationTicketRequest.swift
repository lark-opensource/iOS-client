//
//  GetVerificationTicketRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 获取调用活体认证的ticket
/// - LIVE_MEETING_GET_VERIFICATION_TICKET
/// - ServerPB_Videochat_GetVerificationTicketRequest
public struct GetVerificationTicketRequest {
    public static let command: NetworkCommand = .server(.liveMeetingGetVerificationTicket)
    public typealias Response = GetVerificationTicketResponse

    public init(appId: Int32, scene: String) {
        self.appId = appId
        self.scene = scene
    }

    public var appId: Int32

    public var scene: String
}

/// - ServerPB_Videochat_GetVerificationTicketResponse
public struct GetVerificationTicketResponse {

    public var ticket: String
}

extension GetVerificationTicketRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetVerificationTicketRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetVerificationTicketRequest {
        var request = ProtobufType()
        request.appID = appId
        request.scene = scene
        return request
    }
}

extension GetVerificationTicketResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetVerificationTicketResponse
    init(pb: ServerPB_Videochat_GetVerificationTicketResponse) throws {
        self.ticket = pb.ticket
    }
}
