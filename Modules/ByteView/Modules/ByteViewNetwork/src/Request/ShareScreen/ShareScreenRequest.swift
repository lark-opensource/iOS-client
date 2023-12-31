//
//  ShareScreenRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 会中共享屏幕
/// - SHARE_SCREEN = 2311
/// - Videoconference_V1_ShareScreenRequest
public struct ShareScreenRequest {
    public static let command: NetworkCommand = .rust(.shareScreen)
    public typealias Response = ShareScreenResponse

    public init(meetingId: String, breakoutRoomId: String?, action: Action) {
        self.meetingId = meetingId
        self.breakoutRoomId = breakoutRoomId
        self.action = action
    }

    public var meetingId: String

    /// 分组会议id
    public var breakoutRoomId: String?

    public var action: Action

    public enum Action: Int, Equatable {
        case start = 1
        case stop // = 2
    }
}

/// - Videoconference_V1_ShareScreenResponse
public struct ShareScreenResponse {

    public var shareScreenId: String
}

extension ShareScreenRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_ShareScreenRequest
    func toProtobuf() throws -> Videoconference_V1_ShareScreenRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutRoomId) {
            request.breakoutMeetingID = id
            request.associateType = .breakoutMeeting
        } else {
            request.associateType = .meeting
        }
        switch action {
        case .start:
            request.action = .start
            request.accessibility = true
        case .stop:
            request.action = .stop
        }
        return request
    }
}

extension ShareScreenResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_ShareScreenResponse
    init(pb: Videoconference_V1_ShareScreenResponse) throws {
        self.shareScreenId = pb.shareScreenID
    }
}
