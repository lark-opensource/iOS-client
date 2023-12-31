//
//  FeedListViewController+FindUnread.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import UIKit
import Foundation
import LarkUIKit
import RustPB
import RxSwift
import LarkSDKInterface
import LarkModel

// 双击跳转下一未读Feed逻辑
extension FeedListViewController: FindUnreadDelegate {
    func preLoadNextItems() {
        guard let lastItem = listViewModel.allItems().last,
              let lastFeedCursor = getCursor(lastItem.feedPreview) else { return }
        listViewModel.getNextUnreadFeeds(by: lastFeedCursor)
    }
}

extension FeedListViewController: FeedFinderProviderInterface {
    func getFilterType() -> Feed_V1_FeedFilter.TypeEnum {
        return listViewModel.filterType
    }

    func getUnreadCount(type: Feed_V1_FeedFilter.TypeEnum) -> Int? {
        return listViewModel.dependency.getUnreadCount(type)
    }

    func getAllItems() -> [[FeedFinderItem]] {
        return [listViewModel.allItems()]
    }

    func getMuteUnreadCount(type: Feed_V1_FeedFilter.TypeEnum) -> Int? {
        return listViewModel.dependency.getMuteUnreadCount(type)
    }

    var isAtBottom: Bool {
        return tableView.isAtBottom
    }

    var defaultTab: Feed_V1_FeedFilter.TypeEnum {
        return AllFeedListViewModel.getFirstTab(showMute: getShowMute)
    }

    var getShowMute: Bool {
        return listViewModel.dependency.getShowMute()
    }
}

extension FeedListViewController {
    var currentFeedCursor: FeedCursor? {
        // 取第一个不被遮挡的cell
        guard let firstFullVisibleCell = tableView.visibleCells.first(where: {
            $0.convert(CGPoint.zero, to: view).y >= 0
        }) else {
            return nil
        }

        guard let feedCell = firstFullVisibleCell as? FeedCardCellWithPreview,
            let feedPreview = feedCell.feedPreview else {
            return nil
        }
        var currentFeedCursor = FeedCursor()
        currentFeedCursor.rankTime = Int64(feedPreview.basicMeta.rankTime)
        if let id = Int64(feedPreview.id) {
            currentFeedCursor.id = id
        } else {
            let errorMsg = "transfer error：\(feedPreview.id)"
            let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
            FeedExceptionTracker.FeedList.findUnread(node: .currentFeedCursor, info: info)
        }
        return currentFeedCursor
    }

    func doubleClickTabbar() {
        findNextUnreadFeed()
    }

    private func getCursor(_ feedPreview: FeedPreview) -> FeedCursor? {
        var currentFeedCursor = FeedCursor()
        currentFeedCursor.rankTime = Int64(feedPreview.basicMeta.rankTime)
        if let id = Int64(feedPreview.id) {
            currentFeedCursor.id = id
        } else {
            let errorMsg = "transfer error：\(feedPreview.id)"
            let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
            FeedExceptionTracker.FeedList.findUnread(node: .getCursor, info: info)
        }
        return currentFeedCursor
    }

    private func findNextUnreadFeed() {
        var logInfo = [String: Any]()

        // 取第一个未读
        guard let firstFullVisibleCell = tableView.visibleCells.first(where: {
            $0.convert(CGPoint.zero, to: view).y >= 0
        }) else {
            let position = IndexPath(row: FindUnreadConfig.invalidValue, section: 0)
            scrollToNextUnread(fromPosition: position, logInfo: &logInfo)
            return
        }
        guard let feedCell = firstFullVisibleCell as? FeedCardCellWithPreview,
            let feedPreview = feedCell.feedPreview else {
            return
        }
        var currentFeedCursor = getCursor(feedPreview)
        if let fromFeedID = currentFeedCursor, let feedIndex = listViewModel.allItems().firstIndex(where: {
            $0.feedPreview.id == String(fromFeedID.id) }) {
            let position = IndexPath(row: feedIndex, section: 0)
            scrollToNextUnread(fromPosition: position, logInfo: &logInfo)
        }
    }

    // todo：把旧逻辑删除时记得改命成scrollToNextUnreadFeed
    private func scrollToNextUnread(fromPosition: IndexPath, logInfo: inout [String: Any]) {
        guard let result = feedFindUnreadPlugin.getNextUnreadFeedPosition(provider: self, fromPosition: fromPosition, logInfo: &logInfo) else { return }
        switch result {
        case .tab(let type):
            self.delegate?.changeTabWithFilterSelectItem(type)
            logInfo["jumpToFilter"] = type
        case .position(let position):
            scrollTo(row: position.row)
            logInfo["jumpToRow"] = position.row
        }
        FeedContext.log.info("feedlog/findUnread/jumpTo \(logInfo)")
    }

    // needMoveTop为true，则将整个scroll滑动到顶部；为false，则保持offset不变
    private func scrollTo(row: Int, needMoveTop: Bool = true) {
        if needMoveTop {
            delegate?.pullupMainScrollView()
        }
        // https://www.jianshu.com/p/cf610119d21a
        // 当filter切换时会reload，此时scrollToRow可能会crash
        scrollToRow(row)
    }
}
