//
//  BoxFeedsDependencyImp.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/6/9.
//

import Foundation
import RustPB
import LarkSDKInterface
import RxSwift
import LarkModel
import RxCocoa
import LarkTab

final class BoxFeedsDependencyImp: BoxFeedsDependency {
    private let feedAPI: FeedAPI
    let badgeDriver: Driver<BadgeType> // NaviBar左边Badge
    let boxId: String

    init(feedAPI: FeedAPI,
         badgeDriver: Driver<BadgeType>,
         boxId: String) {
        self.feedAPI = feedAPI
        self.badgeDriver = badgeDriver
        self.boxId = boxId
    }

    // MARK: - FeedAPI

    func getFeedCards(feedCardID: String?,
                      cursor: FeedCursor?,
                      count: Int,
                      traceId: String) -> Observable<GetFeedCardsResult> {

        var boxId: Int?
        if let id = feedCardID, let v = Int(id) {
            boxId = v
        }
        return feedAPI.getFeedCardsV4(filterType: .inbox,
                               boxId: boxId,
                               cursor: cursor,
                               count: count,
                               spanID: nil,
                               feedRuleMd5: "",
                               traceId: traceId)
    }
}
