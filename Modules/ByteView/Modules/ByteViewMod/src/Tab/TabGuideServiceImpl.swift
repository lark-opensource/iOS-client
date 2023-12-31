//
//  TabGuideServiceImpl.swift
//  ByteViewMod
//
//  Created by kiri on 2023/2/6.
//

import Foundation
import ByteViewCommon
import ByteViewTab

#if LarkMod
import LarkGuide
import LarkGuideUI
import RxSwift
import LarkContainer
import LarkUIKit
import LarkNavigation
import LarkTab

final class ByteViewTabGuideServiceImpl: TabGuideService {
    private static let logger = Logger.getLogger("GuideService", prefix: "ByteViewTab.")
    private let guideKey: String = "ios_vc_new_onboarding"
    private let disposeBag = DisposeBag()
    private var isDisplayingGuide: Bool = false
    let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    var newGuideService: NewGuideService? { try? resolver.resolve(assert: NewGuideService.self) }

    func notifyTabEnabled() {
        showVCTabGuideIfNeeded()
        bindShowGuideOnTabAppear()
    }

    private func bindShowGuideOnTabAppear() {
        try? resolver.resolve(assert: MainTabbarLifecycle.self).onTabDidAppear.subscribe(onNext: { [weak self] _ in
            Self.logger.debug("mainTabbarLifeCycle.onTabDidAppear.onNext, will show VC Tab guide.")
            self?.showVCTabGuideIfNeeded()
        }).disposed(by: disposeBag)
    }

    private func showVCTabGuideIfNeeded() {
        guard !isDisplayingGuide else {
            Self.logger.debug("VC Tab Guide is already displaying")
            return
        }
        self.isDisplayingGuide = true
        guard shouldShowGuide,
              let newGuideService = newGuideService,
              newGuideService.checkShouldShowGuide(key: self.guideKey),
              let animatedTabBarVC = RootNavigationController.shared.animatedTabBarController else {
            Self.logger.debug("animatedTabBarVC is nil")
            self.isDisplayingGuide = false
            return
        }

        let tab = Tab.byteview
        /// 此时animatedTabBarVC.quickTabItems中由于懒加载可能未获取到数据，因此使用navigationService来判断
        guard let navigationService = try? resolver.resolve(assert: NavigationService.self),
              navigationService.mainTabs.contains(tab) || navigationService.quickTabs.contains(tab) else {
            Self.logger.debug("[tabs] contains no Tab.byteview")
            self.isDisplayingGuide = false
            return
        }

        var rect: CGRect? // 负责作为OnBoarding展示初始位置的rect
        if animatedTabBarVC.mainTabBarItems.map({ $0.tab }).contains(tab) {
            Self.logger.debug("new VC tab guide will show on main tabbar")
            rect = animatedTabBarVC.mainTabWindowRect(for: tab)
        } else {
            Self.logger.debug("new VC tab guide will show on more tab")
            rect = animatedTabBarVC.moreTabWindowRect()
        }

        guard let unwrappedRect = rect, unwrappedRect.minX != 0, unwrappedRect.minY != 0 else {
            Self.logger.debug("cannot find valid rect to base VC Tab Onboarding")
            self.isDisplayingGuide = false
            return
        }

        /// 从LarkNavigation无法获取到Tab的View，只能拿到rect，但在BubbleItemConfig中如果传入.targetRect(rect)会跳过offset修正逻辑
        /// 导致offset失效，位置显示有偏差。因此在这里用一个view包装rect传入BubbleItemConfig中，确保offset生效，位置正确
        let abstractView = UIView(frame: unwrappedRect)

        let anchor = TargetAnchor(targetSourceType: .targetView(abstractView), offset: -14, targetRectType: .circle)
        let config = self.guideContent
        let buttons = BottomConfig(leftBtnInfo: ButtonInfo(title: config.leftButton),
                                   rightBtnInfo: ButtonInfo(title: config.rightButton))
        let item = BubbleItemConfig(guideAnchor: anchor, textConfig: TextInfoConfig(detail: config.text),
                                    bottomConfig: buttons)
        // 创建单个气泡的配置, 如果不需要代理，就不需要delegate参数
        let singleBubbleConfig = SingleBubbleConfig(delegate: self, bubbleConfig: item)
        // 构建气泡类型
        let bubbleType = BubbleType.single(singleBubbleConfig)
        newGuideService.showBubbleGuideIfNeeded(guideKey: guideKey, bubbleType: bubbleType,
                                                dismissHandler: { [weak self] in
            self?.isDisplayingGuide = false
        })
    }
}

extension ByteViewTabGuideServiceImpl: GuideSingleBubbleDelegate {
    func didClickLeftButton(bubbleView: GuideBubbleView) {
        Self.logger.debug("new VC tab guide didClickLeftButton(OkButton)")
        self.newGuideService?.closeCurrentGuideUIIfNeeded()
    }

    func didClickRightButton(bubbleView: GuideBubbleView) {
        Self.logger.debug("new VC tab guide didClickRightButton(ViewNow)")
        RootNavigationController.shared.switchTab(to: Tab.byteview.urlString)
        self.newGuideService?.closeCurrentGuideUIIfNeeded()
    }
}

#else
final class DefaultTabGuideServiceImpl: TabGuideService {
    private static let logger = Logger.getLogger("GuideService", prefix: "ByteViewTab.")

    func notifyTabEnabled() {
        Self.logger.info("notifyTabEnabled")
    }
}
#endif
