//
//  SendClientInfoRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// ServerPB_Videochat_SendClientInfoRequest
public struct SendClientInfoRequest {
    public static let command: NetworkCommand = .server(.sendClientInfo)

    public init(meetingID: String, timeZoneData: String = TimeZone.current.identifier) {
        self.meetingID = meetingID
        self.timeZoneData = timeZoneData
        self.infoType = .timeZone
    }

    public var meetingID: String

    public var timeZoneData: String

    public var infoType: DataType

    public enum DataType: Int, Hashable {
        case timeZone // = 0
    }
}

extension SendClientInfoRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_SendClientInfoRequest

    func toProtobuf() throws -> ServerPB_Videochat_SendClientInfoRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        request.timeZoneData = timeZoneData
        request.infoType = .init(rawValue: infoType.rawValue) ?? .timeZone
        return request
    }
}
