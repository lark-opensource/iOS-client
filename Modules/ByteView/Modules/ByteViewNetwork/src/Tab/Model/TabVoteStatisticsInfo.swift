//
//  TabVoteStatisticsInfo.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/11/14.
//

import Foundation

/// ServerPB_Videochat_tab_v2_VCVoteStatisticsInfo
public struct TabVoteStatisticsInfo: Equatable {
    /// 统计表格生成状态
    public var status: Status?

    /// 生成后的统计表格链接
    public var statisticsURL: String?

    /// 生成后的统计表格标题，每次进入详情页会得到最新
    public var statisticsFileTitle: String?

    /// 统计数据对应的会议ID
    public var meetingID: String?

    /// 统计数据对应的会议owner
    public var owner: ByteviewUser?

    /// 统计数据对应的会议下行版本号，用于与详情页拉取得到的版本号比对
    public var version: Int32?

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

    public init() {}

    public init(status: Status?, statisticsURL: String?, statisticsFileTitle: String?,
                meetingID: String?, owner: ByteviewUser?, version: Int32?) {
        self.status = status
        self.statisticsURL = statisticsURL
        self.statisticsFileTitle = statisticsFileTitle
        self.meetingID = meetingID
        self.owner = owner
        self.version = version
    }
}
