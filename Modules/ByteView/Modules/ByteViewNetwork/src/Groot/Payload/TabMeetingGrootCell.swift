//
//  TabMeetingGrootCell.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public typealias TabMeetingGrootSession = TypedGrootSession<TabMeetingGrootCellNotifier>

public protocol TabMeetingGrootCellObserver: AnyObject {
    func didReceiveTabMeetingGrootCells(_ cells: [TabMeetingGrootCell], for channel: GrootChannel)
}

public final class TabMeetingGrootCellNotifier: GrootCellNotifier<TabMeetingGrootCell, TabMeetingGrootCellObserver> {

    override func dispatch(message: [TabMeetingGrootCell], to observer: TabMeetingGrootCellObserver) {
        observer.didReceiveTabMeetingGrootCells(message, for: channel)
    }
}

/// 独立tab详情页会议通用信息的groot服务端推送结构
/// - GrootChannel:VC_TAB_MEETING_CHANNEL
/// - Videoconference_V1_VCTabMeetingGrootCellPayload
public struct TabMeetingGrootCell: Equatable {
    public init(changes: [TabMeetingChangeInfo]) {
        self.changes = changes
    }

    public var changes: [TabMeetingChangeInfo]
}
