//
//  GetMeetingURLInfoResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// CommandID：89301
/// - GET_MEETING_URL_INFO
/// - ServerPB_Videochat_GetMeetingURLInfoRequest
public struct GetMeetingURLInfoRequest {
    public static let command: NetworkCommand = .server(.getMeetingURLInfo)
    public typealias Response = GetMeetingURLInfoResponse

    public init(meetingId: String) {
        self.meetingId = meetingId
    }

    /// 会议meetingID
    public var meetingId: String
}

/// Videoconference_V1_GetMeetingURLInfoResponse
public struct GetMeetingURLInfoResponse {
    public var topic: String

    public var meetingNo: String

    public var meetingURL: String

    public var meetingSource: VideoChatInfo.MeetingSource
}

extension GetMeetingURLInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetMeetingURLInfoRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetMeetingURLInfoRequest {
        var request = ProtobufType()
        request.meetingIDStr = meetingId
        return request
    }
}

extension GetMeetingURLInfoResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetMeetingURLInfoResponse
    init(pb: ServerPB_Videochat_GetMeetingURLInfoResponse) throws {
        self.topic = pb.topic
        self.meetingNo = pb.meetingNo
        self.meetingURL = pb.meetingURL
        self.meetingSource = .init(rawValue: pb.meetingSource.rawValue) ?? .unknown
    }
}
