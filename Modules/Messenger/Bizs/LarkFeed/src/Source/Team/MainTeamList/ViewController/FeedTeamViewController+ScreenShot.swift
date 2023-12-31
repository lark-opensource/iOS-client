//
//  FeedTeamViewController+ScreenShot.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/23.
//

import UIKit
import Foundation
import UniverseDesignToast
import LarkModel
import LarkEMM
import LarkSensitivityControl

extension FeedTeamViewController {
    func handleDebugEvent(team: FeedTeamItemViewModel, feed: FeedTeamChatItemViewModel) {
        let info = "teamItemId: \(team.teamItem.id), teamEntityId: \(team.teamEntity.id), feedId: \(feed.chatEntity.id)"
        let config = PasteboardConfig(token: Token("psda_token_avoid_intercept"))
        SCPasteboard.general(config).string = info
        FeedContext.log
            .info("TeamLog/debug/feed: \(team.description), feed: \(feed.chatEntity.description), feedItem: \(feed.chatItem.description)")
        UDToast.showTips(with: info, on: self.view.window ?? self.view)
    }

    func handleDebugEvent(team: FeedTeamItemViewModel) {
        let info = "teamItemId: \(team.teamItem.id), teamEntityId: \(team.teamEntity.id)"
        let config = PasteboardConfig(token: Token("psda_token_avoid_intercept"))
        SCPasteboard.general(config).string = info
        FeedContext.log
            .info("TeamLog/debug/team: team: \(team.description)")
        UDToast.showTips(with: info, on: self.view.window ?? self.view)
    }

    func screenShot() {
        _ = NotificationCenter.default.rx.notification(UIApplication.userDidTakeScreenshotNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, self.viewIfLoaded?.window != nil else { return }
                guard self.viewModel.isActive else { return }
                self.screenShotForMainDataSource()
                self.screenShotForUIDataSource()
            })
    }

    private func screenShotForMainDataSource() {
        var visibleSection: Set<Int> = []
        (self.tableView.indexPathsForVisibleRows ?? [])
            .map { (indexPath: IndexPath) -> (Int) in
                return indexPath.section
            }.forEach { section in
                visibleSection.insert(section)
            }
        visibleSection.compactMap { section in
            self.viewModel.teamUIModel.getTeam(section: section)?.description
        }
        DispatchQueue.global().async {
            let logInfo = "\(visibleSection)"
            let logs = logInfo.logFragment()
            for i in 0..<logs.count {
                let log = logs[i]
                FeedContext.log.info("teamlog/printscreen/team/<\(i)>. \(log)")
            }
        }
    }

    private func screenShotForUIDataSource() {
        let visibleInfo = self.tableView.visibleCells.compactMap { (cell) -> String? in
            guard let c = cell as? FeedTeamChatCell else {
                return nil
            }
            return c.viewModel?.description
        }
        let logs = "\(visibleInfo)".logFragment()
        for i in 0..<logs.count {
            let log = logs[i]
            FeedContext.log.info("teamlog/printscreen-teamUI/<\(i)>. \(log)")
        }
    }
}
