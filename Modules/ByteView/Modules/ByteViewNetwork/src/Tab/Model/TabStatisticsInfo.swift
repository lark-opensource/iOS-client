//
//  TabStatisticsInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_VCTabStatisticsInfo
public struct TabStatisticsInfo: Equatable {
    public init(meetingID: String, status: Status, statisticsURL: String, statisticsFileTitle: String, version: Int32, isBitable: Bool) {
        self.meetingID = meetingID
        self.status = status
        self.statisticsURL = statisticsURL
        self.statisticsFileTitle = statisticsFileTitle
        self.version = version
        self.isBitable = isBitable
    }

    /// 统计数据对应的会议ID
    public var meetingID: String

    /// 统计表格生成状态
    public var status: Status

    /// 生成后的统计表格链接
    public var statisticsURL: String

    /// 生成后的统计表格标题，每次进入详情页会得到最新
    public var statisticsFileTitle: String

    /// 统计数据对应的会议下行版本号，用于与详情页拉取得到的版本号比对
    public var version: Int32

    /// 展示为多维表格
    public var isBitable: Bool

    public enum Status: Int, Hashable {

        /// 表示用户不具备生成和查看统计数据的权限
        case unavailable // = 0

        /// 表示可以生成新统计表格
        case ready // = 1

        /// 表示统计表格正在生成中
        case waiting // = 2

        /// 表示统计表格生成成功
        case succeeded // = 3

        /// 表示统计表格生成失败，需要用户手动重新触发生成
        case failed // = 4
    }
}

extension TabStatisticsInfo {
    public init() {
        self.init(meetingID: "", status: .unavailable, statisticsURL: "", statisticsFileTitle: "", version: 0, isBitable: false)
    }
}

extension TabStatisticsInfo: CustomStringConvertible {
    public var description: String {
        String(
            indent: "TabStatisticsInfo",
            "meetingID: \(meetingID)",
            "status: \(status)",
            "statisticsURL: \(statisticsURL.hashValue)",
            "version: \(version)",
            "isBitable: \(isBitable)"
        )
    }
}
