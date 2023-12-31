//
//  FeedListViewModelDependency.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/25.
//

import Foundation
import RustPB
import LarkSDKInterface
import RxSwift
import SwiftProtobuf
import LarkMessengerInterface
import RxRelay

protocol FeedListViewModelDependency: LoadConfigDependency {
    var styleService: Feed3BarStyleService { get }
    func getFeedCards(filterType: Feed_V1_FeedFilter.TypeEnum,
                      cursor: FeedCursor?,
                      spanID: UInt64?,
                      count: Int,
                      traceId: String) -> Observable<GetFeedCardsResult>

    // 用于拉取下一条未读Feed
    func getNextUnreadFeedCardsBy(filterType: Feed_V1_FeedFilter.TypeEnum,
                                  cursor: FeedCursor?,
                                  traceId: String) -> Observable<NextUnreadFeedCardsResult>

    var currentFeedRuleMd5: String { get }

    func getUnreadCount(_ filter: Feed_V1_FeedFilter.TypeEnum) -> Int?

    func getMuteUnreadCount(_ filter: Feed_V1_FeedFilter.TypeEnum) -> Int?

    func getShowMute() -> Bool
}
