//
//  OtherAdapter.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/21.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkModel

final class OtherAdapter: AdapterInterface {
    private weak var page: LabelMainListViewController?
    private var tableView: UITableView? {
        return page?.tableView
    }
    private let vm: LabelMainListViewModel
    private let disposeBag = DisposeBag()

    init(vm: LabelMainListViewModel) {
        self.vm = vm
    }

    func setup(page: LabelMainListViewController) {
        self.page = page
        screenShot()
    }
}

extension OtherAdapter {
    func preloadDetail() {
        let feeds = self.tableView?.visibleCells.compactMap({
            ($0 as? FeedCardCellWithPreview)?.feedPreview
        }) ?? []
        page?.vm.otherModule.preloadDetail(feeds: feeds)
    }
}

extension OtherAdapter {
    private func screenShot() {
        guard let page = self.page else { return }
        _ = NotificationCenter.default.rx.notification(UIApplication.userDidTakeScreenshotNotification)
            .subscribe(onNext: { [weak self, weak page] _ in
                guard let self = self,
                      let page = page,
                      page.viewIfLoaded?.window != nil,
                      page.vm.isActive else { return }
                self.screenShotForMainDataSource()
                self.screenShotForUIDataSource()
            })
    }

    private func screenShotForMainDataSource() {
        let uiStore = vm.viewDataStateModule.uiStore
        var visibleSection: Set<Int> = []
        (self.tableView?.indexPathsForVisibleRows ?? [])
            .map { (indexPath: IndexPath) -> (Int) in
                return indexPath.section
            }.forEach { section in
                visibleSection.insert(section)
            }
        let logInfo = visibleSection.compactMap { section -> String? in
            guard let label = uiStore.getLabel(index: section) else { return nil }
            let labelId = label.item.id
            let feeds = uiStore.getFeeds(labelId: labelId)
            let feedsInfo = feeds.map({ $0.feedPreview.description })
            return "section: \(section), "
                + "labelId: \(labelId), "
                + "feedsCount: \(feeds.count), "
                + "feedsInfo: \(feedsInfo)"
        }
        DispatchQueue.global().async {
            let logInfo = "visibleSection: \(visibleSection), logInfo: \(logInfo)"
            let logs = logInfo.logFragment()
            for i in 0..<logs.count {
                let log = logs[i]
                FeedContext.log.info("feedlog/label/printscreen/data: \(i): \(log)")
            }
        }
    }

    private func screenShotForUIDataSource() {
        let visibleInfo = self.tableView?.visibleCells.compactMap { (cell) -> String? in
            guard let c = cell as? FeedCardCellWithPreview else { return nil }
            return c.feedPreview?.description
        }
        DispatchQueue.global().async {
            let logs = "\(visibleInfo)".logFragment()
            for i in 0..<logs.count {
                let log = logs[i]
                FeedContext.log.info("feedlog/label/printscreen/ui: \(i): \(log)")
            }
        }
    }
}
