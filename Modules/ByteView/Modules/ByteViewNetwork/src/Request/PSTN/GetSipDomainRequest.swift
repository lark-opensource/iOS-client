//
//  GetSipDomainRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - ServerPB_Videochat_GetSIPDomainByUniqueIDRequest
public struct GetSipDomainRequest {
    public static let command: NetworkCommand = .server(.getSipDomainByUniqueID)
    public typealias Response = GetSipDomainResponse

    public init(uniqueId: Int64, calendarInstance: CalendarInstanceIdentifier) {
        self.uniqueId = uniqueId
        self.calendarInstanceIdentifier = calendarInstance
    }

    public var uniqueId: Int64

    public var calendarInstanceIdentifier: CalendarInstanceIdentifier
}

/// - ServerPB_Videochat_GetSIPDomainByUniqueIDResponse
public struct GetSipDomainResponse {

    public var domain: String

    public var ercDomainList: [String]

    public var isShowCrc: Bool
}

extension GetSipDomainRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetSIPDomainByUniqueIDRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetSIPDomainByUniqueIDRequest {
        var request = ProtobufType()
        request.uniqueID = uniqueId
        request.calendarInstanceIdentifier = calendarInstanceIdentifier.serverPBType
        return request
    }
}

extension GetSipDomainResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetSIPDomainByUniqueIDResponse
    init(pb: ServerPB_Videochat_GetSIPDomainByUniqueIDResponse) throws {
        self.domain = pb.domain
        self.ercDomainList = pb.ercDomainList
        self.isShowCrc = pb.isShowCrc
    }
}
