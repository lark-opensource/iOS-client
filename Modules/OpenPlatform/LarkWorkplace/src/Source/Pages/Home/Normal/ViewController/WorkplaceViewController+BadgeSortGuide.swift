//
//  WorkplaceViewController+BadgeSortGuide.swift
//  LarkWorkplace
//
//  Created by ByteDance on 2023/10/27.
//

import Foundation
import LarkGuide
import LarkGuideUI
import RxSwift

extension WorkPlaceViewController {
    func subscribeForSortGuide() {
        Self.logger.info("start subscribe for sort guide")
        Observable.combineLatest(firstDataRequestFinishRelay, needShowOperationRelay)
            .subscribe { [weak self] (firstRequestFinish, needShowOperation) in
                guard let showOperationResult = needShowOperation else {
                    Self.logger.info("get sort guide observable, but no show operation result", additionalData: [
                        "firstRequestFinish": "\(firstRequestFinish)"
                    ])
                    return
                }
                
                Self.logger.info("get sort guide observable", additionalData: [
                    "firstRequestFinish": "\(firstRequestFinish)",
                    "showOperationResult": "\(showOperationResult)"
                ])
                /// 首屏网络数据获取完成+不需要展示运营弹窗
                if !showOperationResult && firstRequestFinish {
                    DispatchQueue.main.async { [weak self] in
                        self?.showBadgeSortGuideIfNeeded()
                    }
                }
            }
            .disposed(by: disposeBag)
    }
    
    func showBadgeSortGuideIfNeeded() {
        let isWorkflowOptimize = self.context.configService.fgValue(for: .workflowOptimize)
        guard isWorkflowOptimize else {
            Self.logger.info("[LarkWorkplace][UG] lark.workplace.workflow_optimize is false.")
            return
        }

        let key = WPGuideKey.sortBadgeGuide
        guard needShowGuide(for: key) else {
            Self.logger.info("sort badge guide already displayed")
            return
        }
        
        guard let targetCell = self.findFirstIcon() else {
            Self.logger.info("cannot show guide, target cell not found")
            return
        }
        
        guard targetCell.frame.height != 0,
              targetCell.frame.width != 0,
              let window = self.view.window else {
            Self.logger.info("cannot show guide, target cell not show", additionalData: [
                "targetCellHeight": "\(targetCell.frame.height)",
                "targetCellWidth": "\(targetCell.frame.width)",
                "windowExist": "\(self.view.window != nil)"
            ])
            return
        }
        let convertRect = window.convert(
            targetCell.titleLabel.frame,
            from: targetCell
        )
        
        let targetAnchor = TargetAnchor(
            targetSourceType: .targetRect(convertRect),
            arrowDirection: .up
        )
        let bannerConfig = BannerInfoConfig(
            imageType: .image(Resources.workplace_badge_guide)
        )
        let rightButtonInfo = ButtonInfo(
            title: "",
            skipTitle: BundleI18n.LarkWorkplace.OpenPlatform_WorkplaceMgt_OkBttn,
            buttonType: .close
        )
        let textConfig = TextInfoConfig(
            title: nil,
            detail: BundleI18n.LarkWorkplace.OpenPlatform_WorkplaceMgt_UpdateDialogMsg4
        )
        let bottomConfig = BottomConfig(
            leftBtnInfo: nil,
            rightBtnInfo: rightButtonInfo,
            leftText: nil
        )
        let itemConfig = BubbleItemConfig(
            guideAnchor: targetAnchor,
            textConfig: textConfig,
            bannerConfig: bannerConfig,
            bottomConfig: bottomConfig
        )
        
        let maskConfig = MaskConfig(
            shadowAlpha: 0,
            windowBackgroundColor: .clear,
            maskInteractionForceOpen: true
        )
        let bubbleConfig = SingleBubbleConfig(
            bubbleConfig: itemConfig,
            maskConfig: maskConfig
        )
        
        Self.logger.info("start show badge sort guide")
        DispatchQueue.main.async { [weak self] in
            self?.newGuideService.showBubbleGuideIfNeeded(
                guideKey: key.rawValue,
                bubbleType: .single(bubbleConfig),
                dismissHandler: { [weak self] in
                    Self.logger.info("sort badge guide dismiss")
                    self?.context.tracker
                        .start(.openplatform_workspace_manage_onboarding_click)
                        .setClickValue(.close)
                        .post()
                },
                didAppearHandler: { [weak self] guideKey in
                    Self.logger.info("sort badge guide did appear")
                    self?.newGuideService.didShowedGuide(guideKey: guideKey)
                    self?.context.tracker
                        .start(.openplatform_workspace_manage_onboarding_view)
                        .post()
                },
                willAppearHandler: nil
            )
        }
    }
    
    func closeBadgeSortGuideIfNeeded() {
        Self.logger.info("close sort badge guide if needed")
        newGuideService.removeGuideTasksIfNeeded(keys: [WPGuideKey.sortBadgeGuide.rawValue])
    }
    
    private func findFirstIcon() -> WorkPlaceIconCell? {
        guard let model = workPlaceUIModel,
              let indexPath = model.getFirstFavoriteIconIndexPath(),
              let cell = workPlaceCollectionView.cellForItem(at: indexPath) as? WorkPlaceIconCell else {
            return nil
        }
        return cell
    }
    
    private func needShowGuide(for key: WPGuideKey) -> Bool {
        return newGuideService.checkShouldShowGuide(key: key.rawValue)
    }
}
