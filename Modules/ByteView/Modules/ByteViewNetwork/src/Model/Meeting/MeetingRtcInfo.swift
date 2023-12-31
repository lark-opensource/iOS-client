//
//  MeetingRtcInfo.swift
//  ByteViewNetwork
//
//  Created by ZhangJi on 2023/2/21.
//

import Foundation

/// Videoconference_V1_VCRTCInfo
public struct MeetingRtcInfo: Equatable {

    public var rtcAppId: String?

    public init(rtcAppId: String?) {
        self.rtcAppId = rtcAppId
    }
}

extension MeetingRtcInfo: CustomStringConvertible {
    public var description: String {
        return "rtcAppID: \(rtcAppId.hashValue)"
    }
}
