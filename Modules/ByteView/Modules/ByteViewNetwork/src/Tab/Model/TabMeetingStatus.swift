//
//  TabMeetingStatus.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 会议状态
/// - Videoconference_V1_MeetingStatus
public enum TabMeetingStatus: Int, Hashable {

    /// 会议状态未知
    case unknown // = 0

    /// 会议calling
    case meetingCalling // = 1

    /// 会议进行中
    case meetingOnTheCall // = 2

    /// 会议已结束
    case meetingEnd // = 3
}
