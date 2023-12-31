//
//  RTCNetStatusNotify.swift
//  ByteViewNetwork
//
//  Created by ZhangJi on 2022/1/14.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// https://bytedance.feishu.cn/docx/doxcnDY9U849ytzef1E4LwM13Ie
/// RTC远端断网提示
/// - PUSH_VC_REMOTE_RTC_NET_STATUS = 89392
/// - Videoconference_V1_PushVCRemoteRtcNetStatus
public struct RTCNetStatusNotify {
    public var pushType: RTCNetStatusPushType = .full
    public var userRTCNetStatuses: [UserRTCNetStatus]
}

extension RTCNetStatusNotify: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_PushVCRemoteRtcNetStatus
    init(pb: Videoconference_V1_PushVCRemoteRtcNetStatus) throws {
        self.pushType = .init(rawValue: pb.type.rawValue) ?? .unknown
        self.userRTCNetStatuses = pb.netStatuses.map({$0.vcType})
    }
}

public enum RTCNetStatusPushType: Int, Hashable {
    case unknown = 0
    case full // = 1
    case modify // = 2
    case remove // = 3
}

/// Videoconference_V1_UserRtcNetStatus
public struct UserRTCNetStatus: Equatable {
    public var rtcJoinId: String
    public var isIceDisconnected: Bool

    public init(rtcJoinId: String, isIceDisconnected: Bool) {
        self.rtcJoinId = rtcJoinId
        self.isIceDisconnected = isIceDisconnected
    }
}

typealias PBUserRTCNetStatus = Videoconference_V1_UserRtcNetStatus

extension PBUserRTCNetStatus {
    var vcType: UserRTCNetStatus {
        .init(rtcJoinId: rtcJoinID, isIceDisconnected: isIceDisconnected)
    }
}

extension UserRTCNetStatus: CustomStringConvertible {
    public var description: String {
        String(indent: "UserRTCNetStatus", "rtcJoinId: \(rtcJoinId)", "isIceDisconnected: \(isIceDisconnected)")
    }
}

extension RTCNetStatusNotify: CustomStringConvertible {
    public var description: String {
        String(indent: "RTCNetStatusNotify", "PushType: \(pushType)", "Users: \(userRTCNetStatuses)")
    }
}
