//
//  AllFeedListViewModel+FirstTab.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/10/2.
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

extension AllFeedListViewModel {
    static func getFirstTab(showMute: Bool) -> Feed_V1_FeedFilter.TypeEnum {
        return .message
    }

    static func getFirstTabs() -> [Feed_V1_FeedFilter.TypeEnum] {
        return [.inbox, .message]
    }

    func trySwitchFirstTab(_ newTab: Feed_V1_FeedFilter.TypeEnum) {
        guard newTab == firstTab else { return }
        let oldTabInAll = self.filterType
        let newTabInAll = newTab
        guard newTabInAll != oldTabInAll else { return }
        let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .reset)
        FeedContext.log.info("feedlog/changeTab/trySwitchFirstTab. \(trace.description), \(oldTabInAll) -> \(newTabInAll)")
        self.filterType = newTabInAll
        reset(trace: trace)
    }

    func reset(trace: FeedListTrace) {
        FeedContext.log.info("feedlog/dataStream/reset. \(self.listBaseLog), \(trace.description)")
        self.removeAllFeeds(renderType: .reload, trace: trace)
        let task = { [weak self] in
            guard let self = self else { return }
            self.dirtyFeeds.removeAll()
            self.tempRemoveIds.removeAll()
            self.updateNextCursor(nil, trace: trace)
        }
        commit(task)
        super.getFeedCards()
    }
}
