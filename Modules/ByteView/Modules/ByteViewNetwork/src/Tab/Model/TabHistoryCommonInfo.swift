//
//  TabHistoryCommonInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_VCTabHistoryCommonInfo
public struct TabHistoryCommonInfo: Equatable {
    public init(meetingTopic: String, meetingType: MeetingType, meetingSource: VideoChatInfo.MeetingSource, meetingStatus: TabMeetingStatus,
                isLocked: Bool, containsMultipleTenant: Bool, sameTenantID: String, startTime: Int64, endTime: Int64,
                hostUser: ByteviewUser, isRecorded: Bool, canCopyMeetingInfo: Bool, isCrossWithKa: Bool, meetingSubType: MeetingSubType, allParticipantTenant: [Int64],
                rehearsalStatus: WebinarRehearsalStatusType) {
        self.meetingTopic = meetingTopic
        self.meetingType = meetingType
        self.meetingSource = meetingSource
        self.meetingStatus = meetingStatus
        self.isLocked = isLocked
        self.containsMultipleTenant = containsMultipleTenant
        self.sameTenantID = sameTenantID
        self.startTime = startTime
        self.endTime = endTime
        self.hostUser = hostUser
        self.isRecorded = isRecorded
        self.canCopyMeetingInfo = canCopyMeetingInfo
        self.isCrossWithKa = isCrossWithKa
        self.meetingSubType = meetingSubType
        self.allParticipantTenant = allParticipantTenant
        self.rehearsalStatus = rehearsalStatus
    }

    /// 会议标题
    public var meetingTopic: String

    /// 会议类型:(1: 1v1通话， 2: 多人会议)
    public var meetingType: MeetingType

    /// 会议来源: 用户发起、日程会议、面试会议
    public var meetingSource: VideoChatInfo.MeetingSource

    /// 会议状态
    public var meetingStatus: TabMeetingStatus

    /// 会议是否已锁定 (仅主持人邀请可加入并且关闭等候室)
    public var isLocked: Bool

    /// 用于外部标签展示，当该字段为true时，可以直接判定会中存在租户ID与自己不同的用户
    public var containsMultipleTenant: Bool

    /// 用于外部标签展示，当contains_multiple_tenant为false时，客户端需要判断自己的租户ID是否与该字段相等
    public var sameTenantID: String

    /// 会议开始时间，ms
    public var startTime: Int64

    /// 会议结束时间，ms
    public var endTime: Int64

    /// 会议主持人
    public var hostUser: ByteviewUser

    /// 会议是否开启录制
    public var isRecorded: Bool

    /// 是否允许复制会议信息 (【锁定会议】状态下不允许)
    public var canCopyMeetingInfo: Bool

    /// 是否为互通会议
    public var isCrossWithKa: Bool

    /// 会议子类型
    public var meetingSubType: MeetingSubType

    public var allParticipantTenant: [Int64] = []

    /// 彩排状态
    public var rehearsalStatus: WebinarRehearsalStatusType
}

extension TabHistoryCommonInfo: CustomStringConvertible {
    public var description: String {
        String(
            indent: "TabHistoryCommonInfo",
            "meetingType: \(meetingType)",
            "meetingSource: \(meetingSource)",
            "meetingStatus: \(meetingStatus)",
            "isLocked: \(isLocked)",
            "containsMultipleTenant: \(containsMultipleTenant)",
            "sameTenantID: \(sameTenantID)",
            "startTime: \(startTime)",
            "endTime: \(endTime)",
            "hostUser: \(hostUser)",
            "isRecorded: \(isRecorded)",
            "canCopyMeetingInfo: \(canCopyMeetingInfo)",
            "isCrossWithKa: \(isCrossWithKa)",
            "meetingSubType: \(meetingSubType)",
            "allParticipantTenant: \(allParticipantTenant)",
            "rehearsalStatus: \(rehearsalStatus)"
        )
    }
}
