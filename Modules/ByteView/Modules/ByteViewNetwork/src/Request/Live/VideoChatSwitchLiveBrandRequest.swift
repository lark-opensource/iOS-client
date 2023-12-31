//   
//   VideoChatSwitchLiveBrandRequest.swift
//   ByteViewNetwork
// 
//  Created by hubo on 2023/2/10.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//   


import Foundation
import ServerPB

/// - LIVE_MEETING_SWITCH_LIVE_BRAND = 2397
/// - ServerPB_Videochat_live_VideoChatSwitchLiveBrandRequest
public struct VideoChatSwitchLiveBrandRequest {
    public typealias Response = VideoChatSwitchLiveBrandResponse
    public static let command: NetworkCommand = .server(.liveMeetingSwitchLiveBrand)

    public init(meetingId: String, switchTo: LiveBrand) {
        self.meetingId = meetingId
        self.switchTo = switchTo
        self.liveZone = Int32(TimeZone.current.secondsFromGMT() / 60)
    }

    public var meetingId: String
    public var switchTo: LiveBrand
    public var liveZone: Int32
}

/// ServerPB_Videochat_live_VideoChatSwitchLiveBrandResponse
public struct VideoChatSwitchLiveBrandResponse {
    public var byteLiveConfig: ByteLiveConfigForMeeting
    public var larkLiveInfo: LarkLiveInfo

    /// ServerPB_Videochat_live_LarkLiveInfo
    public struct LarkLiveInfo: Equatable {
        var privilege: LivePrivilege
        var layoutTypeSetting: LiveLayout
        var liveUrl: String
        var enableInteraction: Bool
        var enablePlayback: Bool

        init(_ pb: ServerPB_Videochat_live_LarkLiveInfo) {
            privilege = LivePrivilege(rawValue: pb.privilege.rawValue) ?? .unknown
            layoutTypeSetting = LiveLayout(rawValue: pb.layoutTypeSetting.rawValue) ?? .unknown
            liveUrl = pb.liveURL
            enableInteraction = pb.enableInteraction
            enablePlayback = pb.enablePlayback
        }
    }
}

extension VideoChatSwitchLiveBrandRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_live_VideoChatSwitchLiveBrandRequest
    func toProtobuf() throws -> ProtobufType {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.switchTo = ServerPB_Videochat_live_LiveBrand(rawValue: switchTo.rawValue) ?? .unknown
        request.liveZone = liveZone
        return request
    }
}

extension VideoChatSwitchLiveBrandResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_live_VideoChatSwitchLiveBrandResponse
    init(pb: ServerPB_Videochat_live_VideoChatSwitchLiveBrandResponse) throws {
        byteLiveConfig = ByteLiveConfigForMeeting(pb: pb.byteLiveConfig)
        larkLiveInfo = LarkLiveInfo(pb.larkLiveInfo)
    }
}
