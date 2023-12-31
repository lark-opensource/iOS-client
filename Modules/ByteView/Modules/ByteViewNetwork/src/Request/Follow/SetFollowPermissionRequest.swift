//
//  SetFollowPermissionRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - REQUEST_FOLLOW_PERM
/// - ServerPB_Videochat_RequestFollowPermRequest
public struct SetFollowPermissionRequest {
    public static let command: NetworkCommand = .server(.requestFollowPerm)
    public init(meetingId: String, breakoutRoomId: String?, externalAccess: Bool) {
        self.meetingId = meetingId
        self.breakoutRoomId = breakoutRoomId
        self.externalAccess = externalAccess
    }

    public var meetingId: String

    /// 分组会议id
    public var breakoutRoomId: String?

    /// 是否打开关闭外部共享权限
    public var externalAccess: Bool
}

extension SetFollowPermissionRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_RequestFollowPermRequest
    func toProtobuf() throws -> ServerPB_Videochat_RequestFollowPermRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.externalAccess = externalAccess
        request.url = ""
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutRoomId) {
            request.associateType = .breakoutMeeting
            request.breakoutMeetingID = id
        } else {
            request.associateType = .meeting
        }
        return request
    }
}
