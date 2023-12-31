//
//  SubscriberFeedCardDependency.swift
//  LarkFeedPlugin
//
//  Created by 夏汝震 on 2023/8/8.
//

import Foundation
import LarkSDKInterface
import RxSwift
import LarkContainer

protocol SubscriberFeedCardDependency {
    func changeMute(feedId: String, to state: Bool) -> Single<Void>
}

final class SubscriberFeedCardDependencyImpl: SubscriberFeedCardDependency {
    let feedAPI: FeedAPI
    init(resolver: UserResolver) throws {
        feedAPI = try resolver.resolve(assert: FeedAPI.self)
    }
    func changeMute(feedId: String, to state: Bool) -> Single<Void> {
        feedAPI.updateSubscriptionRemind(subscriptionId: feedId, isRemind: state).map { _ in
        }
    }
}
