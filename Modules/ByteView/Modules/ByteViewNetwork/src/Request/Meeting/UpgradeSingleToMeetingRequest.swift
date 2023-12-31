//
//  UpgradeSingleToMeetingRequest.swift
//  ByteViewNetwork
//
//  Created by wangpeiran on 2022/7/8.
//

/// ServerPB_Videochat_UpgradeSingleToMeetingRequest
import Foundation
import ServerPB

public struct UpgradeSingleToMeetingRequest {
    public static let command: NetworkCommand = .server(.upgradeSingleToMeeting)

    public init(meetingId: String, topic: String?) {
        self.meetingId = meetingId
        self.topic = topic
    }
    public var meetingId: String
    public var topic: String?
}

extension UpgradeSingleToMeetingRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_UpgradeSingleToMeetingRequest
    func toProtobuf() throws -> ServerPB_Videochat_UpgradeSingleToMeetingRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        if let topic = topic {
            request.topic = topic
        }
        return request
    }
}
