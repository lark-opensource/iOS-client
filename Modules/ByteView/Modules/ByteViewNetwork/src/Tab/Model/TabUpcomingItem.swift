//
//  TabUpcomingItem.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_VCUpcomingVcInstance
public struct TabUpcomingInstance: Equatable {
    public init(key: String, meetingNumber: String, uniqueID: String, summary: String, startTime: Int64, endTime: Int64,
                isCrossTenant: Bool, originalTime: Int64, category: Category, selfWebinarAttendeeType: WebinarAttendeeType, relationTag: RelationTagData?) {
        self.key = key
        self.meetingNumber = meetingNumber
        self.uniqueID = uniqueID
        self.summary = summary
        self.startTime = startTime
        self.endTime = endTime
        self.isCrossTenant = isCrossTenant
        self.originalTime = originalTime
        self.category = category
        self.selfWebinarAttendeeType = selfWebinarAttendeeType
        self.relationTag = relationTag
    }

    public var key: String

    /// 9位数字的入会码
    public var meetingNumber: String

    /// 日程会议对应的unique_id
    public var uniqueID: String

    /// 标题(若标题为空需要端上进行处理)
    public var summary: String

    /// 开始时间用于排序
    public var startTime: Int64

    /// 结束时间
    public var endTime: Int64

    /// 是否跨租户
    public var isCrossTenant: Bool

    /// 重复性日程,例外原来开始的时间
    public var originalTime: Int64

    /// 日程类型
    public var category: Category

    /// 自己是webinar还是audience 嘉宾 > 观众 > unknown
    public var selfWebinarAttendeeType: WebinarAttendeeType

    /// 日程分类
    public enum Category: Int {
        case defaultCategory // = 1

        /// 飞阅会类型日程
        case samePageMeeting // = 2

        /// 针对会议室限制的虚假日程
        case resourceStrategy // = 3

        /// 会议室征用虚假日程
        case resourceRequisition // = 4

        /// webinar网络研讨会
        case webinar // = 5
    }

    public enum WebinarAttendeeType: Int {
        /// 未知
        case unknown // = 0

        /// 嘉宾
        case speaker // = 1

        /// 观众
        case audience // = 2
    }

    /// tag信息
    public var relationTag: RelationTagData?
}

extension TabUpcomingInstance: CustomStringConvertible {
    public var description: String {
        String(
            indent: "TabUpcomingInstance",
            "key: \(key)",
            "meetingNumber: \(meetingNumber)",
            "uniqueID: \(uniqueID)",
            "startTime: \(startTime)",
            "endTime: \(endTime)",
            "isCrossTenant: \(isCrossTenant)",
            "originalTime: \(originalTime)",
            "category: \(category)",
            "selfAttendeeType: \(selfWebinarAttendeeType)",
            "relationTag: \(relationTag)"
        )
    }
}
