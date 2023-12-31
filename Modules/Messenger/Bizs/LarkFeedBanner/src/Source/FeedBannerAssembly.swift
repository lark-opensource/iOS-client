//
//  FeedBannerAssembly.swift
//  LarkFeedBanner
//
//  Created by 袁平 on 2020/6/16.
//

import UIKit
import Foundation
import Swinject
import LarkSDKInterface
import LarkAccountInterface
import LarkMessengerInterface
import LarkTourInterface
import BootManager
import LarkFeatureGating
import LarkAssembler
import LarkOpenFeed

public final class FeedBannerAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        container.inObjectScope(Feed.userScope).register(FeedBannerService.self) { (r) -> FeedBannerService in
            return FeedBannerServiceImpV2(resolver: r)
        }
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(NewFeedBannerTask.self)
    }

    @_silgen_name("Lark.Feed.Banner")
    static public func BottomBarFactoryRegister() {
        FeedBottomBarFactory.register(
            type: .onBoarding,
            itemBuilder: { userResolver, authKey, publishRelay -> FeedBottomBarItem in
                let item = OnboardingBannerItem(userResolver: userResolver, authKey: authKey, publishRelay: publishRelay)
                return item
            }, viewBuilder: { context, item -> UIView? in
                guard let item = item as? OnboardingBannerItem else { return nil }
                let view = OnBoardingBannerView(frame: .zero, item: item, resolver: context)
                return view
            })
    }
}

import LarkSetting
import LarkContainer
/// 用于FG控制UserResolver的迁移, 控制Resolver类型.
/// 使用UserResolver后可能抛错，需要控制对应的兼容问题
enum Feed {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.feed") // Global
        print("[Info] Get Feed.userScopeFG: \(v)")
        return v
    }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}
