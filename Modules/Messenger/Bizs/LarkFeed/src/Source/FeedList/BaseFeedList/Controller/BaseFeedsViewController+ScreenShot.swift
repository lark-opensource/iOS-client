//
//  BaseFeedsViewController+ScreenShot.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/12.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkEMM
import LarkSensitivityControl

//监听截屏事件，打log
extension BaseFeedsViewController {
    func screenShot() {
        _ = NotificationCenter.default.rx.notification(UIApplication.userDidTakeScreenshotNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, self.viewIfLoaded?.window != nil else { return }
                guard self.feedsViewModel.getActiveState() else { return }
                self.screenShotForRustSDK()
                self.screenShotForUIDataSource()
                self.tryRecoverFeedList()
            })

        NotificationCenter.default.rx.notification(FeedNotification.didChangeDebugMode)
            .subscribe(onNext: { _ in
            }).disposed(by: disposeBag)
    }

    private func screenShotForRustSDK() {
        let selectedIndex = self.tableView.indexPathForSelectedRow ?? IndexPath(row: -1, section: -1)
        let visibleFeeds: [(FeedCardCellViewModel, Bool)] = (self.tableView.indexPathsForVisibleRows ?? [])
            .compactMap { (indexPath: IndexPath) -> (FeedCardCellViewModel, Bool)? in
                self.feedsViewModel.cellViewModel(indexPath).flatMap { ($0, indexPath == selectedIndex) }
            }
        let messages: [[String: String]] = visibleFeeds
            .map { (feed: FeedCardCellViewModel, isSelectedRow: Bool) -> [String: String] in
                let feedPreview = feed.feedPreview
                return ["id": "\(feedPreview.id)",
                 "titleLength": "\(feedPreview.uiMeta.name.count)",
                        "time": "\(feedPreview.uiMeta.displayTime)",
                 "unreadCount": "\(feedPreview.basicMeta.unreadCount)",
                 "isActive": "\(isSelectedRow)"]
            }
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .sortedKeys
        let data = (try? jsonEncoder.encode(messages)) ?? Data()
        let jsonStr = String(data: data, encoding: .utf8) ?? ""
        FeedContext.log.info("user screenshot accompanying infos:\(jsonStr)")

        let logInfo = "\(feedsViewModel.listContextLog), visibleFeeds: \(visibleFeeds.count),  \(visibleFeeds.map({ "address: \(ObjectIdentifier($0.0)), \($0.0.feedPreview.description)" }))"
        let logs = logInfo.logFragment()
        for i in 0..<logs.count {
            let log = logs[i]
            FeedContext.log.info("feedlog/dataStream/printscreen/datasource/<\(i)>. \(trace.description), \(log)")
        }
    }

    private func screenShotForUIDataSource() {
        let visibleFeedsInfo = self.tableView.visibleCells.compactMap { (cell) -> String? in
            if let c = cell as? FeedUniversalListCellProtocol,
               let viewModel = c.viewModel {
                let cellInfo = "cellAddress: \(ObjectIdentifier(cell)), cellVMAddress: \(ObjectIdentifier(viewModel)), "
                return cellInfo + viewModel.feedPreview.description
            }
            return nil
        }
        let logInfo = "\(feedsViewModel.listContextLog), visibleFeedsInfo: \(visibleFeedsInfo)"
        let logs = logInfo.logFragment()
        for i in 0..<logs.count {
            let log = logs[i]
            FeedContext.log.info("feedlog/dataStream/printscreen/ui/<\(i)>. \(trace.description), \(log)")
        }
    }

    private func tryRecoverFeedList() {
        guard !self.feedsViewModel.isQueueSuspended() else {
            return
        }
        let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .screenshot)
        self.feedsViewModel.updateFeeds([], renderType: .reload, trace: trace)
    }

    func handleDebugEvent(feed: FeedPreview) {
        let info = "feedId: \(feed.id)"
        let config = PasteboardConfig(token: Token("psda_token_avoid_intercept"))
        SCPasteboard.general(config).string = info
        FeedContext.log.info("feedlog/dataStream/debug. \(self.feedsViewModel.listContextLog), \(trace.description), \(feed.description)")
        UDToast.showTips(with: info, on: self.view.window ?? self.view)
    }

    func tracklogVisibleFeeds() {
        guard feedsViewModel.isTracklog else { return }
        let visibleFeeds1 = self.tableView.visibleCells.compactMap({
            ($0 as? FeedCardCellWithPreview)?.feedPreview
        })
        feedsViewModel.tracklogVisibleFeeds(visibleFeeds1, isUIDataSource: true, trace: trace)

        let visibleFeeds2: [FeedPreview] = (self.tableView.indexPathsForVisibleRows ?? [])
            .compactMap { (indexPath: IndexPath) -> FeedPreview? in
                self.feedsViewModel.cellViewModel(indexPath)?.feedPreview
            }
        feedsViewModel.tracklogVisibleFeeds(visibleFeeds2, isUIDataSource: false, trace: trace)
    }
}
