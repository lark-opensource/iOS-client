//
//  ThreadFeedCardDependency.swift
//  LarkFeedPlugin
//
//  Created by 夏汝震 on 2023/8/8.
//

import Foundation
import LarkSDKInterface
import LarkMessengerInterface
import LarkOpenFeed
import RxSwift
import LarkContainer

protocol ThreadFeedCardDependency: UserResolverWrapper {
    func changeMute(feedId: String, to state: Bool) -> Single<Void>
    var iPadStatus: String? { get }
}

final class ThreadFeedCardDependencyImpl: ThreadFeedCardDependency {
    let userResolver: UserResolver
    let threadAPI: ThreadAPI
    let feedThreeBarService: FeedThreeBarService

    init(resolver: UserResolver) throws {
        self.userResolver = resolver
        self.threadAPI = try resolver.resolve(assert: ThreadAPI.self)
        self.feedThreeBarService = try resolver.resolve(assert: FeedThreeBarService.self)
    }

    func changeMute(feedId: String, to state: Bool) -> Single<Void> {
        threadAPI.update(threadId: feedId, isRemind: state).asSingle()
    }

    var iPadStatus: String? {
        if let unfold = feedThreeBarService.padUnfoldStatus {
            return unfold ? "unfold" : "fold"
        }
        return nil
    }
}
