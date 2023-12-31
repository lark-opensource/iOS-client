//
//  BreakoutRoomJoinRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// commandID：待确认
/// - ServerPB_Videochat_BreakoutRoomJoinRequest
public struct BreakoutRoomJoinRequest {
    public static let command: NetworkCommand = .server(.joinMeetingBreakoutRoom)

    public init(meetingId: String, toBreakoutRoomId: String) {
        self.meetingId = meetingId
        self.toBreakoutRoomId = toBreakoutRoomId
    }

    public var meetingId: String

    public var toBreakoutRoomId: String
}

extension BreakoutRoomJoinRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_BreakoutRoomJoinRequest
    func toProtobuf() throws -> ServerPB_Videochat_BreakoutRoomJoinRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.toBreakoutRoomID = toBreakoutRoomId
        return request
    }
}
