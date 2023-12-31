//
//  MomentsNickNameProfileContainerViewModel.swift
//  Moment
//
//  Created by ByteDance on 2022/7/21.
//

import Foundation
import UIKit
import RxSwift
import LarkContainer

final class MomentsNickNameProfileContainerViewModel: NSObject, UserResolverWrapper {
    let userResolver: UserResolver
    /// 用户信息
    var userInfo: (name: String, avatarKey: String)
    let userId: String
    let userPushCenter: PushNotificationCenter
    let selectPostTab: Bool
    @ScopedInjectedLazy var configService: MomentsConfigAndSettingService?

    init(userResolver: UserResolver,
         userId: String,
         userInfo: (name: String, avatarKey: String),
         selectPostTab: Bool,
         userPushCenter: PushNotificationCenter) {
        self.userResolver = userResolver
        self.userId = userId
        self.userInfo = userInfo
        self.selectPostTab = selectPostTab
        self.userPushCenter = userPushCenter
    }
}
