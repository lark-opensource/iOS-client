//
//  FeedCardDependency.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/8/5.
//

import Foundation
import LarkOpenFeed
import LarkFeedBase
import RustPB
import LarkModel
import LarkContainer
import LarkMessengerInterface

final class FeedCardDependency: UserResolverWrapper {

    let userResolver: UserResolver

    // 屏幕宽窄屏模式
    @ScopedInjectedLazy var feedBarStyle: FeedThreeBarService?

    // TODO: open feed, 不应该依赖
    @ScopedInjectedLazy private var teamActionService: TeamActionService?

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func bindTeamEnable(feedPreview: FeedPreview) -> Bool {
        return teamActionService?.enableJoinTeam(feedPreview: feedPreview) ?? false
    }
}
