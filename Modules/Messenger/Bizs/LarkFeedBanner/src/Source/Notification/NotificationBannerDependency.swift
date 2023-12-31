//
//  NotificationBannerDependency.swift
//  LarkFeedBanner
//
//  Created by 袁平 on 2020/6/18.
//

import Foundation
import LarkSDKInterface
import LarkContainer

protocol NotificationBannerDependency {
    var notificationRefreshTime: Int32 { get }
}

final class NotificationBannerDependencyImp: NotificationBannerDependency {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    private var _userAppConfig: UserAppConfig?
    private var userAppConfig: UserAppConfig? {
        if _userAppConfig == nil {
            _userAppConfig = try? userResolver.resolve(assert: UserAppConfig.self)
        }
        return _userAppConfig
    }

    private let defaultNotificationRefreshTime: Int32 = 24 * 60

    var notificationRefreshTime: Int32 {
        return self.userAppConfig?.appConfig?.bannerConfig.notificationRefreshTime ?? defaultNotificationRefreshTime
    }
}
