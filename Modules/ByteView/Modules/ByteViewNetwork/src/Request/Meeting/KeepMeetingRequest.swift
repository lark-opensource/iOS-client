//
//  KeepMeetingRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - ServerPB_Videochat_KeepMeetingRequest
public struct KeepMeetingRequest {
    public static let command: NetworkCommand = .server(.keepMeeting)

    public init(meetingId: String) {
        self.meetingId = meetingId
    }

    public var meetingId: String
}

extension KeepMeetingRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_KeepMeetingRequest
    func toProtobuf() throws -> ServerPB_Videochat_KeepMeetingRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        return request
    }
}
