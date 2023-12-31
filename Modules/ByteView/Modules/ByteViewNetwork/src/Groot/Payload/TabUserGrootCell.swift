//
//  TabUserGrootCell.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public typealias TabUserGrootSession = TypedGrootSession<TabUserGrootCellNotifier>

public protocol TabUserGrootCellObserver: AnyObject {
    func didReceiveTabUserGrootCells(_ cells: [TabUserGrootCell], for channel: GrootChannel)
}

public final class TabUserGrootCellNotifier: GrootCellNotifier<TabUserGrootCell, TabUserGrootCellObserver> {

    override func dispatch(message: [TabUserGrootCell], to observer: TabUserGrootCellObserver) {
        observer.didReceiveTabUserGrootCells(message, for: channel)
    }
}

/// 独立tab详情页用户相关数据的groot服务端推送结构
/// - GrootChannel:VC_TAB_USER_CHANNEL
/// - Videoconference_V1_VCTabUserGrootCellPayload
public struct TabUserGrootCell {
    public init(changeType: ChangeType, missedCallInfo: TabMissedCallInfo?, detailPageEvents: [TabDetailItemChangeEvent],
                statisticsInfo: TabStatisticsInfo?, checkinInfo: TabDetailCheckinInfo?, chatHistoryV2: TabDetailChatHistoryV2?,
                voteStatisticsInfo: TabVoteStatisticsInfo?) {
        self.changeType = changeType
        self.missedCallInfo = missedCallInfo
        self.detailPageEvents = detailPageEvents
        self.statisticsInfo = statisticsInfo
        self.checkinInfo = checkinInfo
        self.chatHistoryV2 = chatHistoryV2
        self.voteStatisticsInfo = voteStatisticsInfo
    }

    public var changeType: ChangeType

    /// 独立tab整体未接计数
    public var missedCallInfo: TabMissedCallInfo?

    /// 会议统计信息，可直接用于覆盖原有数据
    public var statisticsInfo: TabStatisticsInfo?

    /// 详情页用户特化数据，如呼叫记录、录制链接等
    public var detailPageEvents: [TabDetailItemChangeEvent]

    /// 会中聊天历史记录
    public var chatHistoryV2: TabDetailChatHistoryV2?

    /// 日程会议签到信息
    public var checkinInfo: TabDetailCheckinInfo?

    ///投票统计信息
    public var voteStatisticsInfo: TabVoteStatisticsInfo?

    public enum ChangeType: Int, Hashable {
        case missedCall // = 0
        case detailPage // = 1
        case statistics // = 2
        case chatHistory // = 3
        case checkinInfo // = 4
        case chatHistoryV2 // = 5
        case vote // = 6
    }
}
