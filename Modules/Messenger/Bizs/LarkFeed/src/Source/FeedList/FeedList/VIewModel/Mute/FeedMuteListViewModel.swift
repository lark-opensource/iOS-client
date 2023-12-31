//
//  FeedMuteListViewModel.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/3/24.
//

import Foundation

final class FeedMuteListViewModel: FeedListViewModel {
    override func handleCustomFeedSort(items: [FeedCardCellViewModel], dataStore: SectionHolder, trace: FeedListTrace) -> [FeedCardCellViewModel] {
        return _handleCustomBoxFeedSort(items: items, dataStore: dataStore, trace: trace)
    }
}
