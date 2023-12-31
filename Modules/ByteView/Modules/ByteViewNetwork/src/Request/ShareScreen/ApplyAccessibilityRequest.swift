//
//  ApplyAccessibilityRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - APPLY_BYTEVIEW_ACCESSIBILITY
/// - ServerPB_Videochat_ApplyByteviewAccessibilityRequest
public struct ApplyAccessibilityRequest {
    public static let command: NetworkCommand = .server(.applyByteviewAccessibility)

    public init(meetingId: String, breakoutRoomId: String?, shareScreenId: String) {
        self.meetingId = meetingId
        self.breakoutRoomId = breakoutRoomId
        self.shareScreenId = shareScreenId
    }

    public var meetingId: String
    /// 分组会议id
    public var breakoutRoomId: String?
    public var shareScreenId: String
}

extension ApplyAccessibilityRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_ApplyByteviewAccessibilityRequest
    func toProtobuf() throws -> ServerPB_Videochat_ApplyByteviewAccessibilityRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.shareScreenID = shareScreenId
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutRoomId) {
            request.breakoutMeetingID = id
            request.associateType = .breakoutMeeting
        } else {
            request.associateType = .meeting
        }
        return request
    }
}
