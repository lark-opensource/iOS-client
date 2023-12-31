//
//  TeamMemberViewController+Guide.swift
//  LarkTeam
//
//  Created by xiaruzhen on 2022/9/20.
//

import UIKit
import Foundation
import LarkGuideUI
import UniverseDesignShadow
import LarkGuide

extension TeamMemberViewController {
    // 彻底停止滑动
    func tryShowGuide() {
        // 刷新信号
        let guideKey = "im_t_chat_member"
        guard self.needShowGuide(key: guideKey),
              self.isViewLoaded,
              self.viewModel.displayMode == .normal,
              self.view.window != nil else { return }
        let visibleCells = tableView.visibleCells.filter {
            var frame = $0.frame
            frame.origin = $0.convert(.zero, to: self.view)
            return frame.minY >= 0 && frame.maxY < self.view.frame.maxY
        }.compactMap({ $0 as? TeamMemberCellInterface })
        let chatCells = visibleCells.filter({ !($0.item?.isChatter ?? false) })
        guard let chatCell = chatCells.first else { return } // 只需要取一条At Cell即可
        self.tableView.setContentOffset(tableView.contentOffset, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            self.showFeedGroupGuide(targetView: chatCell.infoView.avatarView, guideTipText: BundleI18n.LarkTeam.Project_T_IncludeGroupsasMembersNow_Onboarding)
        }
    }

    private func showFeedGroupGuide(targetView: UIView, guideTipText: String) {
        let guideKey = "im_t_chat_member"
        let anchor = TargetAnchor(targetSourceType: .targetView(targetView), offset: 0, targetRectType: .circle)
        let textConfig = TextInfoConfig(detail: guideTipText)
        let bubbleConfig = BubbleItemConfig(guideAnchor: anchor,
                                            textConfig: textConfig)
        let snapshotView = currentWindow()?.rootViewController?.view.snapshotView(afterScreenUpdates: false)
        let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: UIColor.clear, snapshotView: snapshotView)
        let singleBubbleConfig = SingleBubbleConfig(bubbleConfig: bubbleConfig, maskConfig: maskConfig)
        singleBubbleConfig.bubbleConfig.containerConfig = BubbleContainerConfig(bubbleShadowColor: UDShadowColorTheme.s4DownPriColor)
        showBubbleGuideIfNeeded(guideKey: guideKey,
                               bubbleType: .single(singleBubbleConfig),
                               viewTapHandler: nil,
                               dismissHandler: nil,
                               didAppearHandler: { [weak self] (_) in
            self?.didShowGuide(key: guideKey)
        }, willAppearHandler: nil)
    }

    func needShowGuide(key: String) -> Bool {
        return viewModel.guideService.checkShouldShowGuide(key: key)
    }

    public func didShowGuide(key: String) {
        viewModel.guideService.didShowedGuide(guideKey: key)
    }

    public func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 viewTapHandler: GuideViewTapHandler?,
                                 dismissHandler: TaskDismissHandler?,
                                 didAppearHandler: TaskDidAppearHandler?,
                                 willAppearHandler: TaskWillAppearHandler?) {
        viewModel.guideService.showBubbleGuideIfNeeded(guideKey: guideKey,
                                                bubbleType: bubbleType,
                                                viewTapHandler: viewTapHandler,
                                                dismissHandler: dismissHandler,
                                                didAppearHandler: didAppearHandler,
                                                willAppearHandler: willAppearHandler)
    }
}
