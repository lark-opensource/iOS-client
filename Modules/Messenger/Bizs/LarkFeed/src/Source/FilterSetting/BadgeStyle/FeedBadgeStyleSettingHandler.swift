//
//  FeedBadgeStyleSettingHandler.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/1/6.
//

import Foundation
import LarkOpenFeed
import LarkNavigator
import EENavigator
import LarkSDKInterface
import LarkFeedBase

final class FeedBadgeStyleSettingHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }
    func handle(_ body: FeedBadgeStyleSettingBody, req: EENavigator.Request, res: Response) throws {
        let resolver = self.userResolver
        let badgeStyle = FeedBadgeBaseConfig.badgeStyle
        let showTabMuteBadge = FeedBadgeBaseConfig.showTabMuteBadge
        let configurationAPI = try resolver.resolve(assert: ConfigurationAPI.self)
        let vc = FeedBadgeStyleSettingViewController(badgeStyle: badgeStyle,
                                                     showTabMuteBadge: showTabMuteBadge,
                                                     configurationAPI: configurationAPI)
        res.end(resource: vc)
    }
}
