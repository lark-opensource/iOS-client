//
//  ParticipantsViewModel+Listener.swift
//  ByteView
//
//  Created by wulv on 2022/4/5.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork

protocol ParticipantsViewModelListener: AnyObject {
    /// 参会人列表数据源变更(Main Thread)
    func participantDataSourceDidChange(_ dataSource: [ParticipantsSectionModel])
    /// 建议列表数据源变更(Main Thread)
    func suggestionDataSourceDidChange(_ dataSource: [SuggestionParticipantCellModel])
    /// 观众列表数据源变更(Main Thread)
    func attendeeDataSourceDidChange(_ dataSource: [ParticipantsSectionModel])
    /// 观众列表人数变更
    func attendeeNumDidChange(_ num: Int64)
    /// 已拒绝日程的参会人数据变更
    func calendarRejectParticipantsDidChange(_ participants: [Participant], initialCount: Int64)
    /// 搜索列表数据源变更
    func searchDataSourceDidChange(_ dataSource: [SearchParticipantCellModel])
    /// mute all权限变更
    func muteAllAuthorityChange()
    /// 分组信息变更
    func breakoutRoomDataDidChange(_ data: ParticipantsViewModel.BreakoutRoomData)
    /// 参会人列表状态变更
    func participantsListStateDidChange(_ state: ParticipantsListState)
    /// 设置入口变更
    func settingFeatureEnabled(_ enabled: Bool)
    /// 1v1升级至多人会议
    func didUpgradeMeeting()
}

extension ParticipantsViewModelListener {

    func participantDataSourceDidChange(_ dataSource: [ParticipantsSectionModel]) {}

    func suggestionDataSourceDidChange(_ dataSource: [SuggestionParticipantCellModel]) {}

    func attendeeDataSourceDidChange(_ dataSource: [ParticipantsSectionModel]) {}

    func attendeeNumDidChange(_ num: Int64) {}

    func calendarRejectParticipantsDidChange(_ participants: [Participant], initialCount: Int64) {}

    func searchDataSourceDidChange(_ dataSource: [SearchParticipantCellModel]) {}

    func muteAllAuthorityChange() {}

    func breakoutRoomDataDidChange(_ data: ParticipantsViewModel.BreakoutRoomData) {}

    func participantsListStateDidChange(_ state: ParticipantsListState) {}

    func settingFeatureEnabled(_ enabled: Bool) {}

    func didUpgradeMeeting() {}
}
