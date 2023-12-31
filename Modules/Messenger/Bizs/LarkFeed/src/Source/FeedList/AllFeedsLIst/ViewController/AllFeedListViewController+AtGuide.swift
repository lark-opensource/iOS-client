//
//  AllFeedListViewController+AtGuide.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import Foundation
import RustPB
import LarkGuideUI
import LarkUIKit
import LarkModel

/// Feed引导(At/At All/Badge)
extension AllFeedListViewController {
    func observeFeedGuide() {
        let feedAtAndBadgeGuideEnabled = self.allFeedsViewModel.feedAtAndBadgeGuideEnabled()
        // 在viewDidLoad里监听，跳过默认值
        onViewAppeared.asDriver().skip(1).drive(onNext: { [weak self] appeared in
            guard let self = self, appeared, feedAtAndBadgeGuideEnabled else { return }
            self.showFeedGuide()
        }).disposed(by: disposeBag)

        // 如果enabled，那么还需要监听Feed刷新
        if feedAtAndBadgeGuideEnabled {
            self.allFeedsViewModel.feedsUpdated.asDriver(onErrorJustReturn: ())
                .debounce(.milliseconds(Cons.delayMilliseconds))
                .drive(onNext: { [weak self] _ in
                    self?.showFeedGuide()
                }).disposed(by: disposeBag)
        }
    }

    // 显示Feed引导
    private func showFeedGuide() {
        guard let page = self.context?.page,
              page == self.view.window?.lu.visibleViewController(),
              onViewAppeared.value else { return }
        let bottom = page.animatedTabBarController?.tabbarHeight ?? Cons.tabbarHeight
        let visibleCells = tableView.visibleCells.filter {
            var frame = $0.frame
            frame.origin = $0.convert(.zero, to: self.view)
            return frame.minY >= 0 && frame.maxY < (self.view.frame.maxY - bottom)
        }.compactMap({
            if let cell = $0 as? ChatFeedGuideDelegate, cell.isChat {
                return cell
            }
            return nil
        })

        if allFeedsViewModel.needShowGuide(key: .feedAtGuide),
           findAt(visibleCells: visibleCells, atType: .user) {
            return
        }

        if allFeedsViewModel.needShowGuide(key: .feedAtAllGuide),
            findAt(visibleCells: visibleCells, atType: .all) {
            return
        }

        if allFeedsViewModel.needShowGuide(key: .feedBadgeGuide),
            findMute(visibleCells: visibleCells) {
            return
        }
    }

    private func findAt(visibleCells: [ChatFeedGuideDelegate],
                        atType: FeedPreviewAt.AtType) -> Bool {
        let atCells = visibleCells.filter({ $0.hasAtInfo && $0.atInfo.type == atType })
        guard let atCell = atCells.first,
              let atView = atCell.atView else { return false } // 只需要取一条At Cell即可

        let guideTipText: String
        let guideKey: String
        switch atType {
        case .user:
            guideKey = GuideKey.feedAtGuide.rawValue
            guideTipText = BundleI18n.LarkFeed.Lark_Legacy_FeedAtYouGuideTip("\(atCell.atInfo.localizedUserName)")
        case .all:
            guideKey = GuideKey.feedAtAllGuide.rawValue
            guideTipText = BundleI18n.LarkFeed.Lark_Legacy_FeedAtAllGuideTip("\(atCell.atInfo.localizedUserName)")
        @unknown default:
            assert(false, "new value")
            guideTipText = ""
            guideKey = ""
        }

        if !guideKey.isEmpty {
            // 创建单个气泡的配置
            let bubbleConfig = BubbleItemConfig(
                guideAnchor: TargetAnchor(targetSourceType: .targetView(atView), targetRectType: .circle),
                textConfig: TextInfoConfig(detail: guideTipText),
                bottomConfig: BottomConfig(rightBtnInfo: ButtonInfo(title: BundleI18n.LarkFeed.Lark_Legacy_FirstDoneDelayedFeedOk,
                                                                    buttonType: .close))
            )
            let singleBubbleConfig = SingleBubbleConfig(
                bubbleConfig: bubbleConfig,
                maskConfig: MaskConfig()
            )
            feedGuideDependency.showBubbleGuideIfNeeded(
                guideKey: guideKey,
                bubbleType: .single(singleBubbleConfig),
                viewTapHandler: { [weak self, weak atCell] _ in
                    guard let self = self else { return }
                    self.feedGuideDependency.closeCurrentGuideUIIfNeeded()
                    atCell?.routerToNextPage(from: self, context: self.context)
                },
                dismissHandler: { [weak self] in
                    // 恢复队列
                    self?.allFeedsViewModel.changeQueueState(false, taskType: .atGuide)
                },
                didAppearHandler: nil,
                willAppearHandler: { [weak self] _ in
                    // 挂起队列
                    self?.allFeedsViewModel.changeQueueState(true, taskType: .atGuide)
                })
        }
        return true
    }

    private func findMute(visibleCells: [ChatFeedGuideDelegate]) -> Bool {
        let muteCells = visibleCells.filter({ !$0.isRemind && $0.unreadCount > 0 })
        guard let muteCell = muteCells.first,
              let badgeView = muteCell.badgeView else { return false }

        // 创建单个气泡的配置
        let bubbleConfig = BubbleItemConfig(
            guideAnchor: TargetAnchor(targetSourceType: .targetView(badgeView)),
            textConfig: TextInfoConfig(detail: BundleI18n.LarkFeed.Lark_Settings_Badgestyleguide)
        )
        let singleBubbleConfig = SingleBubbleConfig(
            bubbleConfig: bubbleConfig,
            maskConfig: MaskConfig()
        )
        let guideKey = GuideKey.feedBadgeGuide.rawValue
        feedGuideDependency.showBubbleGuideIfNeeded(
            guideKey: guideKey,
            bubbleType: .single(singleBubbleConfig),
            viewTapHandler: nil,
            dismissHandler: { [weak self] in
                // 恢复队列
                self?.allFeedsViewModel.changeQueueState(false, taskType: .muteGuide)
            },
            didAppearHandler: nil,
            willAppearHandler: { [weak self] _ in
                // 挂起队列
                self?.allFeedsViewModel.changeQueueState(true, taskType: .muteGuide)
            })
        return true
    }

    enum Cons {
        static let delayMilliseconds: Int = 500
        static let tabbarHeight: CGFloat = 52.0
    }
}
