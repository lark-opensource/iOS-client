//
//  TabMeetingUserSpecInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_VCTabMeetingUserSpecInfo
public struct TabMeetingUserSpecInfo: Equatable {
    public init(historyInfo: [HistoryInfo], recordInfo: TabDetailRecordInfo?, followInfo: [FollowAbbrInfo],
                statisticsInfo: TabStatisticsInfo?, sourceApplink: MeetingSourceAppLinkInfo?, manageURLParam: String,
                version: Int32, collection: [CollectionInfo], checkinInfo: TabDetailCheckinInfo?, chatHistoryV2: TabDetailChatHistoryV2?,
                bitable: BitableInfo?, isWebinarAudience: Bool,
                voteStatisticsInfo: TabVoteStatisticsInfo?, notesInfo: TabNotesInfo?) {
        self.historyInfo = historyInfo
        self.recordInfo = recordInfo
        self.followInfo = followInfo
        self.statisticsInfo = statisticsInfo
        self.sourceApplink = sourceApplink
        self.version = version
        self.collection = collection
        self.checkinInfo = checkinInfo
        self.chatHistoryV2 = chatHistoryV2
        self.bitable = bitable
        self.isWebinarAudience = isWebinarAudience
        self.voteStatisticsInfo = voteStatisticsInfo
        self.notesInfo = notesInfo
    }

    /// 该会议相关的历史信息，如果是1v1通话，只会有一条，如果是多人会议，则可能有多条呼叫记录
    public var historyInfo: [HistoryInfo]

    /// 录制/Lark Minutes 的链接，当前用户如果没有加入过会议，或者会议未结束时为空
    public var recordInfo: TabDetailRecordInfo?

    /// 会中共享简化信息
    public var followInfo: [FollowAbbrInfo]

    /// 签到信息
    public var checkinInfo: TabDetailCheckinInfo?

    /// 会议统计信息
    public var statisticsInfo: TabStatisticsInfo?

    /// 会议来源applink参数信息
    public var sourceApplink: MeetingSourceAppLinkInfo?

    /// 会中聊天历史记录
    public var chatHistoryV2: TabDetailChatHistoryV2?

    /// 呼叫记录对应的版本号
    public var version: Int32

    /// 所属合集
    public var collection: [CollectionInfo]

    /// 多维表格
    public var bitable: BitableInfo?

    /// 是否为webinar观众
    public var isWebinarAudience: Bool

    ///投票数据下载链接
    public var voteStatisticsInfo: TabVoteStatisticsInfo?

    /// 纪要数据
    public var notesInfo: TabNotesInfo?
}
