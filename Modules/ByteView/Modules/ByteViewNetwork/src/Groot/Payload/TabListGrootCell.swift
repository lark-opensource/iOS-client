//
//  TabListGrootCell.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public typealias TabListGrootSession = TypedGrootSession<TabListGrootCellNotifier>

public protocol TabListGrootCellObserver: AnyObject {
    func didReceiveTabListGrootCells(_ cells: [TabListGrootCell], for channel: GrootChannel)
}

public final class TabListGrootCellNotifier: GrootCellNotifier<TabListGrootCell, TabListGrootCellObserver> {

    override func dispatch(message: [TabListGrootCell], to observer: TabListGrootCellObserver) {
        observer.didReceiveTabListGrootCells(message, for: channel)
    }
}

/// 独立tab列表更新的groot服务端推送结构
/// - GrootChannel:VC_TAB_LIST_CHANNEL
/// - Videoconference_V1_VCTabListGrootCellPayload
public struct TabListGrootCell: Equatable {
    public init(insertTopItems: [TabListItem], updateItems: [TabListItem], deletedHistoryIds: [String],
                calInsertTopItems: [TabListItem], calUpdateItems: [TabListItem], calDeletedHistoryIds: [String],
                enterpriseInsertTopItems: [TabListItem], enterpriseUpdateItems: [TabListItem], enterpriseDeletedHistoryIds: [String]) {
        self.insertTopItems = insertTopItems
        self.updateItems = updateItems
        self.deletedHistoryIds = deletedHistoryIds
        self.calInsertTopItems = calInsertTopItems
        self.calUpdateItems = calUpdateItems
        self.calDeletedHistoryIds = calDeletedHistoryIds
        self.enterpriseInsertTopItems = enterpriseInsertTopItems
        self.enterpriseUpdateItems = enterpriseUpdateItems
        self.enterpriseDeletedHistoryIds = enterpriseDeletedHistoryIds
    }

    public var insertTopItems: [TabListItem]

    public var updateItems: [TabListItem]

    public var deletedHistoryIds: [String]

    /// 新版本增加的 未加入，未被呼叫，但未拒绝对应日程 而收到的推送
    public var calInsertTopItems: [TabListItem]

    /// 新版本增加的 未加入，未被呼叫，但未拒绝对应日程 而收到的推送
    public var calUpdateItems: [TabListItem]

    /// 新版本增加的 未加入，未被呼叫，但未拒绝对应日程 而收到的推送
    public var calDeletedHistoryIds: [String]

    /// 新版本增加的 拨号盘呼叫 记录
    public var enterpriseInsertTopItems: [TabListItem]

    public var enterpriseUpdateItems: [TabListItem]

    public var enterpriseDeletedHistoryIds: [String]
}
