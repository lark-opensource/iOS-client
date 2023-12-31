//
//  FeedBannerUserDefault.swift
//  LarkFeedBanner
//
//  Created by 袁平 on 2020/6/17.
//

import LarkAccountInterface
import LarkStorage
import LarkContainer

final class FeedBannerUserDefault {
    private static let userStore = \FeedBannerUserDefault.userStore

    private let userStore: KVStore

    init(userResolver: UserResolver) {
        self.userStore = userResolver.udkv(domain: Domain.biz.feed.child("Banner"))
    }

    /// 活跃有奖banner手动关闭
    /// ActivityBanner已经被关闭
    @KVBinding(to: userStore, key: "activityBannerAlreadyClosedFlag", default: false)
    var activityBannerAlreadyClosedFlag: Bool

    // MARK: - 升级团队
    /// 升级团队banner手动关闭
    @KVBinding(to: userStore, key: "upgradeTeamBannerAlreadyClosedFlag", default: false)
    var upgradeTeamBannerAlreadyClosedFlag: Bool

    // MARK: - 通知
    @KVBinding(to: userStore, key: "kNotifyReminderLastCheckTime", default: 0.0)
    var notifyReminderLastCheckTime: TimeInterval
}
