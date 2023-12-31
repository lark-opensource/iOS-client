//
//  FeedListenerItem.swift
//  LarkFeedPlugin
//
//  Created by xiaruzhen on 2022/11/30.
//

import UIKit
import Foundation
import LarkOpenFeed
import LarkAccountInterface
import Swinject
import RxSwift
import LarkFeed
import LarkNavigation
import LarkGuideUI
import UniverseDesignShadow
import AnimatedTabBar
import LarkUIKit
import LarkContainer

final class FeedGuideLifeListener: FeedListenerItem, UserResolverWrapper {
    let userResolver: UserResolver

    private let disposeBag = DisposeBag()
    private var state: FeedPageState?

    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.fetchBatchClearBadgeGuide()
    }

    var needListenLifeCycle: Bool {
        return true
    }

    func feedLifeCycleChanged(state: FeedPageState, context: FeedContextService) {
        self.state = state
    }

    private func fetchBatchClearBadgeGuide() {
        // 长按清未读功能目前只支持iphone, 不支持ipad的edgeBar长按手势
        guard Feed.Feature(userResolver).isClearBadgeGuideEnable, !Display.pad else { return }
        guard let feedContext = try? self.resolver.resolve(assert: FeedContextService.self),
              let pushFeedPreview = try? self.resolver.userPushCenter.observable(for: LarkFeed.PushFeedPreview.self),
              let tabbarLifecycle = try? self.resolver.resolve(assert: MainTabbarLifecycle.self) else { return }
        Observable.combineLatest(
            pushFeedPreview.filter({
                if let unread = $0.getUnreadBadge(.inbox), unread >= 100 {
                    return true
                }
                return false
            }),
            tabbarLifecycle.onTabDidAppear
        )
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (pushFeed, _) in
            guard let self = self, self.state == .viewDidAppear else { return }
            let config = try? self.resolver.resolve(assert: FeedGuideConfigService.self)
            guard let config = config, config.feedBatchClearBadgeEnabled() else { return }
            self.triggerGuideBubble(unread: pushFeed.getUnreadBadge(.inbox), context: feedContext)
        }).disposed(by: disposeBag)
    }

    private func triggerGuideBubble(unread: Int?, context: FeedContextService) {
        // 获取tabbar上"消息tab"的rect, mainTabWindowRect已对bottom和edge两种Case做了区分
        guard let guideRect = context.page?.animatedTabBarController?.mainTabWindowRect(for: .feed) else {
            FeedPluginTracker.log.info("feedlog/guide/batchClearBadge. no feed tab "
                                       + "\(context) \(context.page) "
                                       + "\(context.page?.animatedTabBarController)")
            return
        }

        // 调用LarkGuide组件触发引导气泡
        guard let feedGuideDependency = try? self.resolver.resolve(assert: FeedGuideDependency.self) else { return }
        let guideKey = GuideKey.feedBatchClearBadgeGuide.rawValue
        let bubbleConfig = BubbleItemConfig(
            guideAnchor: TargetAnchor(targetSourceType: .targetRect(guideRect),
                                      offset: -10,
                                      targetRectType: .circle),
            textConfig: TextInfoConfig(title: BundleI18n.LarkFeedPlugin.Lark_IM_DismissUnreadsOnboard_Title,
                                       detail: BundleI18n.LarkFeedPlugin.Lark_IM_DismissUnreadsOnboard_Desc))
        let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: UIColor.clear)
        let singleBubbleConfig = SingleBubbleConfig(bubbleConfig: bubbleConfig, maskConfig: maskConfig)
        singleBubbleConfig.bubbleConfig.containerConfig = BubbleContainerConfig(bubbleShadowColor: UDShadowColorTheme.s4DownPriColor)

        feedGuideDependency.showBubbleGuideIfNeeded(
            guideKey: guideKey,
            bubbleType: .single(singleBubbleConfig),
            viewTapHandler: nil,
            dismissHandler: nil,
            didAppearHandler: { (_) in
                feedGuideDependency.didShowGuide(key: GuideKey.feedBatchClearBadgeGuide.rawValue)
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    feedGuideDependency.closeCurrentGuideUIIfNeeded()
                }
            },
            willAppearHandler: nil
        )

        FeedPluginTracker.log.info("feedlog/guide/batchClearBadge. success, unread:\(unread)")
        if let unread = unread {
            FeedPluginTracker.Guide.cleanBadgeView(unReadCount: unread)
        }
    }
}
