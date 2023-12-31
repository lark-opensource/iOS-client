//
//  FeedTeamViewController+PreloadDetail.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
//

import Foundation

extension FeedTeamViewController {
    func preloadDetail() {
        let cellVMs = self.tableView.visibleCells.compactMap({
            ($0 as? FeedTeamChatCell)?.viewModel
        })
        viewModel.preloadDetail(cellVMs)
    }
}
