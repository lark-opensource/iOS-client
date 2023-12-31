//
//  JoinMeetingTogetherRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2022/4/12.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import ServerPB

/// - JOIN_MEETING_TOGETHER = 89901
/// - Videoconference_V1_JoinMeetingTogetherRequest
public struct JoinMeetingTogetherRequest {
    public static let command: NetworkCommand = .rust(.joinMeetingTogether)

    public init(meetingId: String, target: ByteviewUser) {
        self.meetingId = meetingId
        self.target = target
    }

    public var meetingId: String
    public var target: ByteviewUser
}

extension JoinMeetingTogetherRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_JoinMeetingTogetherRequest

    func toProtobuf() throws -> ProtobufType {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.targetToJoinTogether = target.pbType
        return request
    }
}

/// - GET_LRVC_URL = 89902 lark请求lrvc的url
/// - ServerPB_Videochat_GetLrvcUrlRequest
public struct GetLrvcUrlRequest {
    public static let command: NetworkCommand = .server(.getLrvcURL)
    public typealias Response = GetLrvcUrlResponse

    public init(roomId: String, meetingId: String) {
        self.roomId = roomId
        self.meetingId = meetingId
    }

    /// 请求lrvc的room
    public var roomId: String
    /// 请求lrvc的meeting
    public var meetingId: String
}

extension GetLrvcUrlRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetLrvcUrlRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetLrvcUrlRequest {
        var request = ProtobufType()
        request.roomID = roomId
        request.meetingID = meetingId
        return request
    }
}

/// ServerPB_Videochat_GetLrvcUrlResponse
public struct GetLrvcUrlResponse {
    /// url 包括token
    public var lrvcURL: String
}

extension GetLrvcUrlResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetLrvcUrlResponse
    init(pb: ServerPB_Videochat_GetLrvcUrlResponse) throws {
        self.lrvcURL = pb.lrvcURL
    }
}
