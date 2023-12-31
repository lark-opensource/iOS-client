//
//  FeedTeamViewModel+ViewState.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2022/9/7.
//

import Foundation

extension FeedTeamViewModel {

    var dataSource: [FeedTeamItemViewModel] {
        if let teamId = subTeamId, !teamId.isEmpty {
            return teamUIModel.teamModels.filter({ String($0.teamItem.id) == teamId })
        }
        return teamUIModel.teamModels
    }

    var displayFooter: Bool {
        var display = !dataSource.isEmpty
        if let teamId = subTeamId, !teamId.isEmpty {
            display = false
        }
        return display
    }
}
