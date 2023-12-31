//
//  LivePreCheckRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 海外版入会前检查直播状态, 服务端返回是否需要隐私弹窗
/// - LIVE_MEETING_JOIN_PRE_CHECK = 2382
/// - ServerPB_Videochat_VideoChatLivePreCheckRequest
public struct LivePreCheckRequest {
    public static let command: NetworkCommand = .server(.liveMeetingJoinPreCheck)
    public typealias Response = LivePreCheckResponse

    public init(meetingId: String?, meetingNumber: String?) {
        self.meetingId = meetingId
        self.meetingNumber = meetingNumber
    }

    public var meetingId: String?

    public var meetingNumber: String?
}

/// - ServerPB_Videochat_VideoChatLivePreCheckResponse
public struct LivePreCheckResponse {

    /// 是否展示privacy policy弹窗
    public var showPrivacyPolicy: Bool
}

extension LivePreCheckRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_VideoChatLivePreCheckRequest
    func toProtobuf() throws -> ServerPB_Videochat_VideoChatLivePreCheckRequest {
        var request = ProtobufType()
        if let id = meetingId {
            request.meetingID = id
        }
        if let number = meetingNumber {
            request.meetingNumber = number
        }
        return request
    }
}

extension LivePreCheckResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_VideoChatLivePreCheckResponse
    init(pb: ServerPB_Videochat_VideoChatLivePreCheckResponse) throws {
        self.showPrivacyPolicy = pb.showPrivacyPolicy
    }
}
