//
//  TabMeetingAbbrInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 会议详情简化信息
/// - Videoconference_V1_VCTabMeetingAbbrInfo
public struct TabMeetingAbbrInfo: Equatable {
    public init(meetingID: String, meetingBaseInfo: TabMeetingBaseInfo, userSpecInfo: TabMeetingUserSpecInfo) {
        self.meetingID = meetingID
        self.meetingBaseInfo = meetingBaseInfo
        self.userSpecInfo = userSpecInfo
    }

    /// 会议ID
    public var meetingID: String

    /// 会议基本信息，所有人都看到同一份数据
    public var meetingBaseInfo: TabMeetingBaseInfo

    /// 会议用户特化信息，每个用户都会看到不一样的内容
    public var userSpecInfo: TabMeetingUserSpecInfo
}
