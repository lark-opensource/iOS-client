//
//  FeedListViewModelDependencyImpl.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/25.
//

import Foundation
import RustPB
import LarkSDKInterface
import RxSwift
import LarkRustClient
import SwiftProtobuf
import RunloopTools
import LarkMessengerInterface
import RxRelay

typealias RustServiceProvider = () -> RustService

final class FeedListViewModelDependencyImpl: FeedListViewModelDependency {
    let filterDataStore: FilterDataStore
    let feedAPI: FeedAPI
    let rustClient: RustService
    let styleService: Feed3BarStyleService

    init(filterDataStore: FilterDataStore,
         feedAPI: FeedAPI,
         rustClient: RustService,
         styleService: Feed3BarStyleService
    ) {
        self.filterDataStore = filterDataStore
        self.feedAPI = feedAPI
        self.rustClient = rustClient
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

    // 来自FeedAPI
    func getNextUnreadFeedCardsBy(filterType: Feed_V1_FeedFilter.TypeEnum,
                                  cursor: FeedCursor?,
                                  traceId: String) -> Observable<NextUnreadFeedCardsResult> {
        return feedAPI.getNextUnreadFeedCardsV4(filterType: filterType,
                                                cursor: cursor,
                                                feedRuleMd5: currentFeedRuleMd5,
                                                traceId: traceId)
    }

    // MARK: LoadConfigDependency

    func sendAsyncRequest(_ request: Message) -> Observable<[String: String]> {
        rustClient.sendAsyncRequest(request, transform: { (response: Settings_V1_GetSettingsResponse) in
            response.fieldGroups
        })
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
}
