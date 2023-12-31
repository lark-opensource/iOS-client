//
//  TabMeetingBaseInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_VCTabMeetingBaseInfo
public struct TabMeetingBaseInfo: Equatable {
    public init(meetingInfo: TabHistoryCommonInfo, sponsorUser: ByteviewUser, participants: [ParticipantAbbrInfo], downVersion: Int32, audienceNum: Int32) {
        self.meetingInfo = meetingInfo
        self.sponsorUser = sponsorUser
        self.participants = participants
        self.downVersion = downVersion
        self.audienceNum = audienceNum
    }

    /// 会议基本信息
    public var meetingInfo: TabHistoryCommonInfo

    /// 会议发起人
    public var sponsorUser: ByteviewUser

    /// 参会人简化信息
    public var participants: [ParticipantAbbrInfo]

    /// 对应的 meeting channel 下行版本号
    public var downVersion: Int32

    /// 网络研讨会观众人数
    public var audienceNum: Int32
}
