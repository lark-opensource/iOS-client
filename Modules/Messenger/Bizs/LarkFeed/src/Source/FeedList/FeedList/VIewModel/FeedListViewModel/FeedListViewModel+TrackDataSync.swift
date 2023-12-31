//
//  FeedListViewModel+TrackDataSync.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/11/11.
//

import Foundation
import RxSwift
import RustPB
import LarkSDKInterface
import RxDataSources
import AnimatedTabBar
import RxCocoa
import ThreadSafeDataStructure
import LarkNavigation
import LarkModel
import LarkTab
import LarkMonitor

extension FeedListViewModel {

    func trackListBadgeWhenLoadAllFeed() {
        if filterType == .delayed {
            let delayedCount = self.allItems().count
            let filterBadge = dependency.getUnreadCount(.delayed)
            FeedDataSyncTracker.trackListBadgeWhenLoadAllFeed(
                filterType: filterType,
                listBadge: delayedCount,
                filterBadgeCount: filterBadge)
        } else if filterType == .unread {
            let filterBadge = dependency.getUnreadCount(.unread)
            var unreadCount = 0
            self.getUnreadFeeds(self.allItems()).forEach { cellVm in
                unreadCount += cellVm.feedPreview.basicMeta.unreadCount
            }
            FeedDataSyncTracker.trackListBadgeWhenLoadAllFeed(
                filterType: filterType,
                listBadge: unreadCount,
                filterBadgeCount: filterBadge)
        } else if filterType == .atMe {
            let filterBadge = dependency.getUnreadCount(.atMe)
            var atCount = 0
            self.allItems().filter { $0.feedPreview.basicMeta.isRemind }.forEach { cellVm in
                if cellVm.feedPreview.uiMeta.mention.hasAtInfo {
                    atCount += cellVm.feedPreview.uiMeta.mention.atInfosCount
                }
            }
            FeedDataSyncTracker.trackListBadgeWhenLoadAllFeed(
                filterType: filterType,
                listBadge: atCount,
                filterBadgeCount: filterBadge)
        }
    }
}
