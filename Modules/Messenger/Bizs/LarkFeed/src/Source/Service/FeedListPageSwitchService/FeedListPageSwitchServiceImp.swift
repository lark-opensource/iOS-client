//
//  FeedListPageSwitchServiceImp.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/5/6.
//

import Foundation
import LarkMessengerInterface
import LarkOpenFeed

final class FeedListPageSwitchServiceImp: FeedListPageSwitchService {
    let context: FeedContextService
    let filterListViewModel: FeedFilterListViewModel

    init(context: FeedContextService,
         filterListViewModel: FeedFilterListViewModel) {
        self.context = context
        self.filterListViewModel = filterListViewModel
    }

    func switchToFeedTeamList(teamId: String) {
        guard let mainVC = context.page as? FeedMainViewController else { return }
        filterListViewModel.setSubTabId(.team, subId: teamId)
        mainVC.changeTab(.team, .createTeamTrigger)
        mainVC.filterTabView.filterFixedView?.changeViewTab(.team)
        if let teamVC = mainVC.moduleVCContainerView.currentListVC as? FeedTeamViewController {
            teamVC.viewModel.setSubTeamId(teamId)
            teamVC.viewModel.reload()
            if let tid = Int(teamId) {
                teamVC.viewModel.updateTeamExpanded(tid, isExpanded: true, section: nil)
            }
        }
    }
}
