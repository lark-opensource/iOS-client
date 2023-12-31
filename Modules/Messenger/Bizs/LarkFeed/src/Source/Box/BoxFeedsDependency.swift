//
//  BoxFeedsDependency.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/6/9.
//

import Foundation
import RxSwift
import RustPB
import LarkSDKInterface
import LarkModel
import RxCocoa
import LarkTab

protocol BoxFeedsDependency {

    // NaviBar左边Badge
    var badgeDriver: Driver<BadgeType> { get }
    var boxId: String { get }

    // MARK: - FeedAPI

    func getFeedCards(feedCardID: String?,
                      cursor: FeedCursor?,
                      count: Int,
                      traceId: String) -> Observable<GetFeedCardsResult>
}
