//
//  GetH323AccessInfoRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - ServerPB_Videochat_GetH323AccessInfoByUniqueIDRequest
public struct GetH323AccessInfoRequest {
    public static let command: NetworkCommand = .server(.getH323AccessByUniqueID)
    public typealias Response = GetH323AccessInfoResponse

    public init(uniqueId: Int64, meetingNumber: String, calendarInstance: CalendarInstanceIdentifier) {
        self.uniqueId = uniqueId
        self.meetingNumber = meetingNumber
        self.calendarInstanceIdentifier = calendarInstance
    }

    public var uniqueId: Int64

    public var meetingNumber: String

    public var calendarInstanceIdentifier: CalendarInstanceIdentifier
}

/// - ServerPB_Videochat_GetH323AccessInfoByUniqueIDResponse
public struct GetH323AccessInfoResponse {

    public var h323Access: H323Setting
}


extension GetH323AccessInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetH323AccessInfoByUniqueIDRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetH323AccessInfoByUniqueIDRequest {
        var request = ProtobufType()
        request.uniqueID = uniqueId
        request.meetingNumber = meetingNumber
        request.calendarInstanceIdentifier = calendarInstanceIdentifier.serverPBType
        return request
    }
}

extension GetH323AccessInfoResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetH323AccessInfoByUniqueIDResponse
    init(pb: ServerPB_Videochat_GetH323AccessInfoByUniqueIDResponse) throws {
        self.h323Access = pb.h323Access.vcType
    }
}
