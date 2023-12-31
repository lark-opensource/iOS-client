//
//  TabDetailItemChangeEvent.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_VCTabDetailItemChangeEvent
public struct TabDetailItemChangeEvent {
    public init(meetingID: String, recordInfo: TabDetailRecordInfo?, historyInfo: HistoryInfo?, replaceAllHistory: [HistoryInfo],
                followInfo: [FollowAbbrInfo],
                version: Int32) {
        self.meetingID = meetingID
        self.recordInfo = recordInfo
        self.historyInfo = historyInfo
        self.replaceAllHistory = replaceAllHistory
        self.followInfo = followInfo
        self.version = version
    }

    public var meetingID: String

    /// 录制信息，可直接用于覆盖原有数据
    public var recordInfo: TabDetailRecordInfo?

    /// 呼叫历史增量信息
    public var historyInfo: HistoryInfo?

    /// 全量历史呼叫信息，替换指定会议的所有呼叫记录
    public var replaceAllHistory: [HistoryInfo]

    /// 会中共享简化信息， 可直接用于覆盖原有数据
    public var followInfo: [FollowAbbrInfo]

    /// 会议统计信息，可直接用于覆盖原有数据(已废弃)
//    public var statisticsInfo: TabStatisticsInfo

    /// 呼叫记录对应的版本号
    public var version: Int32
}
