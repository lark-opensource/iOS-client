//
//  FeedMainViewController+ThreeColumnsGuide.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/4/25.
//

import Foundation
import RustPB
import LarkGuideUI
import LarkUIKit
import LarkModel
import UIKit
import RxSwift
import UniverseDesignShadow

extension FeedMainViewController {
    func observeFeedThreeColumnsGuide() {
        Observable.combineLatest(
            self.filterTabView.onFilterFixedViewAppeared.asObservable(),
            self.onViewAppeared.asObservable()
        ).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (filterAppeared, viewAppeared) in
                guard let self = self else { return }
                self.filterTabViewModel.filterFixedViewModel.mainViewAppeared = viewAppeared
                FeedContext.log.info("feedlog/threeColumns/guide. filterAppeared \(filterAppeared), viewAppeared \(viewAppeared)")
                guard filterAppeared, viewAppeared else { return }

                let localTrigger = self.filterTabViewModel.filterFixedViewModel.localTrigger
                guard let guideView = self.filterTabView.menuGuideView,
                      let defaultShowFilter = self.filterTabViewModel.filterFixedViewModel.defaultShowFilter,
                      (defaultShowFilter || (!defaultShowFilter && localTrigger)),
                      let isNewUser = self.filterTabViewModel.filterFixedViewModel.filterSetting?.isNewUser else {
                    FeedContext.log.info("feedlog/threeColumns/guide. three columns guide fail, "
                                         + "hasGuideView: \(self.filterTabView.menuGuideView != nil), "
                                         + "defaultShowFilter: \(String(describing: self.filterTabViewModel.filterFixedViewModel.defaultShowFilter)), "
                                         + "localTrigger: \(self.filterTabViewModel.filterFixedViewModel.localTrigger), "
                                         + "isNewUser: \(String(describing: self.filterTabViewModel.filterFixedViewModel.filterSetting?.isNewUser))")
                    return
                }

                let netStatus = self.filterTabViewModel.filterFixedViewModel.netStatus
                if netStatus == .netUnavailable ||
                   netStatus == .serviceUnavailable ||
                   netStatus == .offline {
                    FeedContext.log.info("feedlog/threeColumns/guide. bad net status \(netStatus)")
                    return
                }

                let firstTriggerGuide = self.filterTabViewModel.filterFixedViewModel.firstTriggerGuide
                let delay = defaultShowFilter && firstTriggerGuide ? FeedGuideCons.longDelay : FeedGuideCons.shortDelay
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    guard self.filterTabViewModel.filterFixedViewModel.mainViewAppeared else {
                        FeedContext.log.info("feedlog/threeColumns/guide. mainvc is not appeared")
                        return
                    }
                    if firstTriggerGuide {
                        self.filterTabViewModel.filterFixedViewModel.firstTriggerGuide = false
                        if let vc = self.navigationController?.presentedViewController {
                            FeedContext.log.info("feedlog/threeColumns/guide. has presentedVC \(vc) for the first trigger guide")
                            return
                        }
                    }

                    let guideTipText = isNewUser ? BundleI18n.LarkFeed.Lark_ViewFeedFilterHereManageChats_OnboardingMessageNewUser :
                    BundleI18n.LarkFeed.Lark_ViewFeedFilterHereManageChats_OnboardingMessageExistingUser
                    self.showFeedThreeColumnsGuide(guideView: guideView, guideTipText: guideTipText)
                }
            }).disposed(by: self.disposeBag)
    }

    private func showFeedThreeColumnsGuide(guideView: UIView, guideTipText: String) {
        guard self.mainViewModel.feedThreeColumnsGuideEnabled() else { return }
        FeedContext.log.info("feedlog/threeColumns/guide. show three columns guide success")
        // 创建单个气泡的配置
        let guideKey = GuideKey.mobileMessengerThreeColumn.rawValue
        let bubbleConfig = BubbleItemConfig(guideAnchor: TargetAnchor(targetSourceType: .targetView(guideView),
                                                                      targetRectType: .circle),
                                            textConfig: TextInfoConfig(detail: guideTipText))
        /// afterScreenUpdates: 需要传入false，否则退到后台再回来会导致异常
        /// https://bytedance.feishu.cn/docx/doxcnFzPpqiMfWTTVPsvaA8uiTg
        let snapshotView = currentWindow()?.rootViewController?.view.snapshotView(afterScreenUpdates: false)
        let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: UIColor.clear, snapshotView: snapshotView)
        let singleBubbleConfig = SingleBubbleConfig(bubbleConfig: bubbleConfig, maskConfig: maskConfig)

        singleBubbleConfig.bubbleConfig.containerConfig = BubbleContainerConfig(bubbleShadowColor: UDShadowColorTheme.s4DownPriColor)
        feedGuideDependency.showBubbleGuideIfNeeded(guideKey: guideKey,
                                                    bubbleType: .single(singleBubbleConfig),
                                                    viewTapHandler: nil,
                                                    dismissHandler: nil,
                                                    didAppearHandler: { [weak self] (_) in
                                                        self?.mainViewModel.didShowGuide(key: .mobileMessengerThreeColumn)
                                                    }, willAppearHandler: nil)
        FeedTracker.ThreeColumns.View.onboardView()
    }

    enum FeedGuideCons {
        static let longDelay: CGFloat = 3.0
        static let shortDelay: CGFloat = 0.5
    }
}
