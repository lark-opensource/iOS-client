//
//  VideoChatIdType.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_IDType
public enum VideoChatIdType: Int, Hashable {
    case unknown // = 0

    /// 群ID
    case groupID // = 1

    /// 会议ID
    case meetingID // = 2

    /// 日程视频会议ID
    case uniqueID // = 3

    /// 面试会议UID
    case interviewUid // = 4

    /// 预约ID
    case reservationID // = 5
}

extension VideoChatIdType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .groupID:
            return "groupID"
        case .meetingID:
            return "meetingID"
        case .uniqueID:
            return "uniqueID"
        case .interviewUid:
            return "interviewUid"
        case .reservationID:
            return "reservationID"
        }
    }
}
