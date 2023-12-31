//
//  MockFeedListViewModelDependency.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/8/24.
//

import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface
import SwiftProtobuf
@testable import LarkFeed

final class MockFeedListViewModelDependency: FeedListViewModelDependency {

    let filterDataStore: FilterDataStore
    let feedAPI: FeedAPI
    let styleService: Feed3BarStyleService

    init(filterDataStore: FilterDataStore,
         feedAPI: FeedAPI,
         styleService: Feed3BarStyleService) {
        self.filterDataStore = filterDataStore
        self.feedAPI = feedAPI
        self.styleService = styleService
    }

    func getFeedCards(filterType: Feed_V1_FeedFilter.TypeEnum,
                      cursor: FeedCursor?,
                      spanID: UInt64?,
                      count: Int,
                      traceId: String) -> Observable<GetFeedCardsResult> {
        return feedAPI.getFeedCardsV4(filterType: filterType,
                                      boxId: nil,
                                      cursor: cursor,
                                      count: count,
                                      spanID: spanID,
                                      feedRuleMd5: currentFeedRuleMd5,
                                      traceId: traceId)
    }

    // 用于拉取下一条未读Feed
    func getNextUnreadFeedCardsBy(filterType: Feed_V1_FeedFilter.TypeEnum,
                                  cursor: FeedCursor?,
                                  traceId: String) -> Observable<NextUnreadFeedCardsResult> {
        return feedAPI.getNextUnreadFeedCardsV4(filterType: filterType,
                                                cursor: cursor,
                                                feedRuleMd5: currentFeedRuleMd5,
                                                traceId: traceId)
    }

    var currentFeedRuleMd5: String {
        return filterDataStore.feedRuleMd5
    }

    func getUnreadCount(_ filter: Feed_V1_FeedFilter.TypeEnum) -> Int? {
        return filterDataStore.getUnreadCount(filter)
    }

    func getMuteUnreadCount(_ filter: Feed_V1_FeedFilter.TypeEnum) -> Int? {
        return filterDataStore.getMuteUnreadCount(filter)
    }

    func getShowMute() -> Bool {
        return filterDataStore.getShowMute()
    }

    func sendAsyncRequest(_ request: SwiftProtobuf.Message) -> Observable<[String: String]> {
        return .just([:])
    }
}
