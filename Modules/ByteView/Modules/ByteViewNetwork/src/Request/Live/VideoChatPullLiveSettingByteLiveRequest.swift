//
//  VideoChatPullLiveSettingByteLiveRequest.swift
//  ByteViewNetwork
//
//  Created by hubo on 2023/2/10.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - LIVE_MEETING_PULL_SETTING_BYTE_LIVE = 2394
/// - ServerPB_Videochat_live_VideoChatPullLiveSettingByteLiveRequest
public struct VideoChatPullLiveSettingByteLiveRequest {
    public typealias Response = VideoChatPullLiveSettingByteLiveResponse
    public static var command: NetworkCommand = .server(.liveMeetingPullSettingByteLive)
    public init(meetingId: String) {
        self.meetingId = meetingId
        self.liveZone = Int32(TimeZone.current.secondsFromGMT() / 60)
    }

    public var meetingId: String
    public var liveZone: Int32
}

/// ServerPB_Videochat_live_VideoChatPullLiveSettingByteLiveResponse
public struct VideoChatPullLiveSettingByteLiveResponse: Equatable {
    public var byteLiveConfig: ByteLiveConfigForMeeting
}

extension VideoChatPullLiveSettingByteLiveRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_live_VideoChatPullLiveSettingByteLiveRequest
    func toProtobuf() throws -> ProtobufType {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.liveZone = liveZone
        return request
    }
}

extension VideoChatPullLiveSettingByteLiveResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_live_VideoChatPullLiveSettingByteLiveResponse
    init(pb: ProtobufType) throws {
        byteLiveConfig = ByteLiveConfigForMeeting(pb: pb.byteLiveConfig)
    }
}
