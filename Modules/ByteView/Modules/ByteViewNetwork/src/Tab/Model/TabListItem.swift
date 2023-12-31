//
//  TabListItem.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 会议列表简化信息
/// - Videoconference_V1_VCTabListItem
public struct TabListItem: Equatable {
    public init(historyID: String, meetingID: String, meetingType: MeetingType, meetingTopic: String, meetingSource: VideoChatInfo.MeetingSource,
                meetingStatus: TabMeetingStatus, meetingNumber: String, meetingStartTime: String,
                isLocked: Bool, historyAbbrInfo: HistoryAbbrInfo, sortTime: Int64, containsMultipleTenant: Bool,
                sameTenantID: String, subscribeDetailChange: Bool, contentLogos: [LogoType], uniqueID: String,
                phoneNumber: String, phoneType: PhoneType, recordInfo: TabDetailRecordInfo,
                followInfo: [FollowAbbrInfo], collectionInfo: [CollectionInfo], ipPhoneNumber: String, isCrossWithKa: Bool, showVersion: String, enterpriseType: EnterpriseType,
                meetingSubType: MeetingSubType, allParticipantTenant: [Int64],
                rehearsalStatus: WebinarRehearsalStatusType) {
        self.historyID = historyID
        self.meetingID = meetingID
        self.meetingType = meetingType
        self.meetingTopic = meetingTopic
        self.meetingSource = meetingSource
        self.meetingStatus = meetingStatus
        self.meetingNumber = meetingNumber
        self.meetingStartTime = meetingStartTime
        self.isLocked = isLocked
        self.historyAbbrInfo = historyAbbrInfo
        self.sortTime = sortTime
        self.containsMultipleTenant = containsMultipleTenant
        self.sameTenantID = sameTenantID
        self.subscribeDetailChange = subscribeDetailChange
        self.contentLogos = contentLogos
        self.uniqueID = uniqueID
        self.phoneNumber = phoneNumber
        self.phoneType = phoneType
        self.recordInfo = recordInfo
        self.followInfo = followInfo
        self.collectionInfo = collectionInfo
        self.ipPhoneNumber = ipPhoneNumber
        self.isCrossWithKa = isCrossWithKa
        self.showVersion = showVersion
        self.enterpriseType = enterpriseType
        self.meetingSubType = meetingSubType
        self.allParticipantTenant = allParticipantTenant
        self.rehearsalStatus = rehearsalStatus
    }

    /// 列表记录唯一标识
    public var historyID: String

    /// 列表聚合所包含的会议ID，如果未聚合，使用meetingID，已聚合则为空
    public var meetingID: String

    /// 会议类型:(1: 1v1通话， 2: 多人会议)
    public var meetingType: MeetingType

    /// 会议标题
    public var meetingTopic: String

    /// 会议来源: 用户发起、日程会议、面试会议
    public var meetingSource: VideoChatInfo.MeetingSource

    /// 会议状态
    public var meetingStatus: TabMeetingStatus

    /// 9位会议号, 若没有则不展示
    public var meetingNumber: String

    /// 会议开始时间，秒表示
    public var meetingStartTime: String

    /// 会议是否已锁定 (仅主持人邀请可加入并且关闭等候室)
    public var isLocked: Bool

    /// 列表聚合展示所需数据
    public var historyAbbrInfo: HistoryAbbrInfo

    /// 单独提供独立tab列表排序字段，避免排序需求变更
    public var sortTime: Int64

    /// 用于外部标签展示，当该字段为true时，可以直接判定会中存在租户ID与自己不同的用户
    public var containsMultipleTenant: Bool

    /// 用于外部标签展示，当contains_multiple_tenant为false时，客户端需要判断自己的租户ID是否与该字段相等
    public var sameTenantID: String

    /// 表示是否需要订阅详情页的数据变更
    public var subscribeDetailChange: Bool

    /// 表示当前会议具有的内容标识
    public var contentLogos: [LogoType]

    /// 日程/面试会议对应的uniqueID，如果是普通会议，则为空
    public var uniqueID: String

    public var phoneType: PhoneType

    /// 电话号码
    public var phoneNumber: String

    /// GetRecordInfoRequest 赋值后为 true
    public var hasRecordInfo: Bool = false

    /// 录制信息，通过 GetRecordInfoRequest 赋值
    public var recordInfo: TabDetailRecordInfo

    /// 妙享（文档）信息
    public var followInfo: [FollowAbbrInfo]

    /// 会议所属合集
    public var collectionInfo: [CollectionInfo]

    public var ipPhoneNumber: String

    /// 互通会议
    public var isCrossWithKa: Bool

    public var showVersion: String

    public var enterpriseType: EnterpriseType

    public var allParticipantTenant: [Int64] = []

    /// 网络研讨会类型
    public var meetingSubType: MeetingSubType

    /// 彩排状态
    public var rehearsalStatus: WebinarRehearsalStatusType

    public enum LogoType: Int, Hashable {
        case unknown // = 0

        /// 表示会议详情页中包含会议录制链接
        case record // = 1

        /// 表示会议详情页中包含magic share共享CCM文档
        case msCcm // = 2

        /// 表示会议详情页中包含magic share的共享的链接
        case msURL // = 3

        /// 表示会议详情页中包含妙记
        case larkMinutes // = 4

        /// 会议纪要
        case notes // = 5

    }

    public enum PhoneType: Int, Hashable {
        case vc // = 0

        /// 拨号盘外呼
        case outsideEnterprisePhone // = 1

        case ipPhone // = 2

        case insideEnterprisePhone // = 3
    }

    public enum EnterpriseType: Int, Hashable {
        case enterprise // = 0
        case recruit // = 1
    }
}

extension TabListItem: CustomStringConvertible {
    public var description: String {
        String(
            indent: "TabListItem",
            "historyID: \(historyID)",
            "meetingID: \(meetingID)",
            "meetingType: \(meetingType)",
            "meetingSource: \(meetingSource)",
            "meetingStatus: \(meetingStatus)",
            "meetingNumber: \(meetingNumber)",
            "meetingStartTime: \(meetingStartTime)",
            "isLocked: \(isLocked)",
            "historyAbbrInfo: \(historyAbbrInfo)",
            "sortTime: \(sortTime)",
            "containsMultipleTenant: \(containsMultipleTenant)",
            "sameTenantID: \(sameTenantID)",
            "subscribeDetailChange: \(subscribeDetailChange)",
            "contentLogos: \(contentLogos)",
            "uniqueID: \(uniqueID)",
            "phoneNumber: \(phoneNumber.hash)",
            "phoneType: \(phoneType)",
            "recordInfo: \(recordInfo)",
            "followInfo: \(followInfo)",
            "collectionInfo: \(collectionInfo)",
            "ipPhoneNumber: \(ipPhoneNumber)",
            "isCrossWithKa: \(isCrossWithKa)",
            "showVersion: \(showVersion)",
            "enterpriseType: \(enterpriseType)",
            "meetingSubType: \(meetingSubType)",
            "allParticipantTenant: \(allParticipantTenant)",
            "rehearsalStatus: \(rehearsalStatus)"
        )
    }
}
