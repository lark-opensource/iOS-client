//
//  UpdateMinutesStatusRequest.swift
//  ByteViewNetwork
//
//  Created by wulv on 2021/12/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - UPDATE_MINUTES_STATUS = 89014
/// - ServerPB_Videochat_UpdateMinutesStatusRequest
public struct UpdateMinutesStatusRequest {
    public static let command: NetworkCommand = .server(.updateMinutesStatus)

    public var meetingID: String

    public var status: Status

    public enum Status: Int, Equatable {
        case unknown // = 0
        case `open` // = 1
        case close // = 2
    }

    public init(meetingID: String, status: Status) {
        self.meetingID = meetingID
        self.status = status
    }
}

extension UpdateMinutesStatusRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_UpdateMinutesStatusRequest

    func toProtobuf() throws -> ServerPB_Videochat_UpdateMinutesStatusRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        request.status = .init(rawValue: status.rawValue) ?? .unknown
        return request
    }
}
