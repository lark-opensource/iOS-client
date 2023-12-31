//
// Created by duanxiaochen.7 on 2021/2/5.
// Affiliated with SKDoc.
//
// Description: Doc Browser 相关的 Onboarding 代理方法实现

import SKUIKit
import SKCommon
import SKBrowser
import SKFoundation
import SKResource
import RxSwift
import Lottie
import UniverseDesignIcon

//引导位置在block上方所需距离屏幕顶部的最小距离
private let blockMinTopDistance: CGFloat = 194

// - MARK: Delegates
extension DocBrowserViewController: OnboardingDelegate {

    public func onboardingManagerRejectedThisTime(_ id: OnboardingID) {
        DocsLogger.onboardingInfo("有人设置了不允许播放任何引导，所以 \(id) 播放失败")
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "failed"],
                                             completion: nil)
    }

    public func onboardingDisabledInMinaConfiguration(for id: OnboardingID) {
        DocsLogger.onboardingInfo("管理员设置了不播放 \(id)")
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "failed"],
                                             completion: nil)
    }

    public func onboardingAlreadyFinished(_ id: OnboardingID) {
        DocsLogger.onboardingInfo("\(id) 已经播放过了")
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "success"],
                                             completion: nil)
    }

    public func onboardingDependenciesUnfinished(for id: OnboardingID) {
        DocsLogger.onboardingInfo("由于依赖的引导序列 \(onboardingDependencies(for: id)) 未全部完成播放，无法播放 \(id)")
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "failed"],
                                             completion: nil)
    }

    public func onboardingMaterialNotEnough(for id: OnboardingID) {
        skAssertionFailure("未能提供完整的引导依赖物料，无法播放 \(id)！")
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "failed"],
                                             completion: nil)
    }

    public func onboardingWindowSizeWillChange(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        DocsLogger.onboardingInfo("在播放引导 \(id) 的时候 window 发生了尺寸变化，acknowledge 了")
        return .acknowledge
    }

    public func onboardingTargetViewDidDisappear(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        DocsLogger.onboardingInfo("在播放引导 \(id) 的时候目标 view 消失了，acknowledge 了")
        return .acknowledge
    }

    public func onboardingAcknowledge(_ id: OnboardingID) {
        if onboardingIsLast[id] == true {
            OnboardingManager.shared.setTemporarilyRejectsUpcomingOnboardings()
        }
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "success"],
                                             completion: nil)
    }

    public func onboardingSkip(_ id: OnboardingID) {
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "skipped"],
                                             completion: nil)
    }

    public func onboardingDidRegister(_ id: OnboardingID) {
        if id == .docInsertTable {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250, execute: {
                self.scrollToItem(by: BarButtonIdentifier.insertTable.rawValue)
            })
        }
    }

    public func onboardingWillAttach(view: UIView, for id: OnboardingID) {
        if id == .docSmartComposeIntro {
            let rect = onboardingTargetRect(for: id)
            let smartComposeTouchDownAnimation = AnimationViews.smartComposeOnboarding
            smartComposeTouchDownAnimation.loopAnimation = true
            smartComposeTouchDownAnimation.autoReverseAnimation = false
            view.addSubview(smartComposeTouchDownAnimation)
            smartComposeTouchDownAnimation.snp.makeConstraints { (make) in
                make.bottom.equalTo(view.snp.top).offset(rect.maxY + 42)
                make.width.height.equalTo(72)
                make.centerX.equalTo(rect.bottomCenter.x)
            }
            view.layoutIfNeeded()
            smartComposeTouchDownAnimation.play()
        }
    }
}

// - MARK: Data Sources

extension DocBrowserViewController: OnboardingDataSource {

    public func onboardingType(of id: OnboardingID) -> OnboardingType {
        guard let type = onboardingTypes[id] else {
            fatalError("小傻瓜，是不是忘了配引导类型了？")
        }
        return type
    }

    public func onboardingIsAsynchronous(for id: OnboardingID) -> Bool {
        return [
            .docToolbarV2AddNewBlock,    // 指向工具栏
            .docToolbarV2BlockTransform, // 指向工具栏
            .docToolbarV2Pencilkit,      // 指向工具栏
            .docTodoCenterIntro,          // 指向工具栏
            .docInsertTable               // 指向工具栏
        ].contains(id)
    }

    public func onboardingSupportedInterfaceOrientations(for id: OnboardingID) -> UIInterfaceOrientationMask {
        if SKDisplay.pad { return [.all] }
        return [.portrait]
    }

    public func onboardingDisappearStyle(of id: OnboardingID) -> OnboardingStyle.DisappearStyle {
        switch id {
        case .docBlockMenuPenetrableIntro, .docBlockMenuPenetrableComment: return .countdownAfterUserInteraction(.seconds(2))
        case .docToolbarV2Pencilkit, .docInsertTable:
            return .countdownAfterAppearance(.seconds(5))
        default: return .immediatelyAfterUserInteraction
        }
    }

    public func onboardingHostViewController(for id: OnboardingID) -> UIViewController {
        return self
    }

    public func onboardingImage(for id: OnboardingID) -> UIImage? {
        return nil
    }

    public func onboardingLottieView(for id: OnboardingID) -> LOTAnimationView? {
        return nil
    }

    public func onboardingTitle(for id: OnboardingID) -> String? {
        return onboardingTitles[id]
    }

    public func onboardingHint(for id: OnboardingID) -> String {
        return onboardingHints[id] ?? ""
    }

    public func onboardingTargetRect(for id: OnboardingID) -> CGRect {
        switch id {
        case .docTranslateIntro:
            onboardingTargetRects[id] = getNavBarRightButtonFrame(by: .more)
        case .docTodoCenterIntro:
            onboardingTargetRects[id] = getToolbarMainItemFrame(by: BarButtonIdentifier.at.rawValue)
        case .docToolbarV2AddNewBlock:
            onboardingTargetRects[id] = getToolbarMainItemFrame(by: BarButtonIdentifier.addNewBlock.rawValue)
        case .docToolbarV2BlockTransform:
            onboardingTargetRects[id] = getToolbarMainItemFrame(by: BarButtonIdentifier.blockTransform.rawValue)
        case .docIPadCatalogIntro:
            onboardingTargetRects[id] = getNavBarLeftButtonFrame(by: .catalog)
        case .docWidescreenModeIntro:
            onboardingTargetRects[id] = getNavBarRightButtonFrame(by: .more)
        case .docBlockMenuPenetrableComment:
            onboardingTargetRects[id] = getBlockRect()
        case .docInsertTable:
            onboardingTargetRects[id] = getToolbarMainItemFrame(by: BarButtonIdentifier.insertTable.rawValue)
        case .docToolbarV2Pencilkit:
            onboardingTargetRects[id] = getToolbarMainItemFrame(by: BarButtonIdentifier.pencilkit.rawValue)
        default: ()
        }
        return onboardingTargetRects[id] ?? .zero
    }

    public func onboardingArrowDirection(for id: OnboardingID) -> OnboardingStyle.ArrowDirection {
        switch id {
        case .docBlockMenuPenetrableIntro:
            onboardingArrowDirections[id] = .targetTopEdge
        case .docBlockMenuPenetrableComment:
            let targetRect = onboardingTargetRects[id] ?? .zero
            //sheet查看图片引导指向的是单元格，根据单元格位置来决定气泡指向
            //Block快捷菜单评论引导，判断Block距离屏幕顶部的距离是否足够放下引导框
            //是：正常显示在Block上方，箭头朝下
            //否：根据Block底部是否超过屏幕中线（是：引导显示在屏幕中线，箭头朝下；否：引导显示在Block底部，箭头朝上）
            if targetRect.minY < blockMinTopDistance {
                onboardingArrowDirections[id] = .targetBottomEdge
            } else {
                onboardingArrowDirections[id] = .targetTopEdge
            }
        case .bitableFieldEditIntro:
            //bitable字段编辑引导，距离顶部最小高度为引导view的高度90+状态栏的高度44
            let targetRect = onboardingTargetRects[id] ?? .zero
            if targetRect.minY < 134 {
                onboardingArrowDirections[id] = .targetBottomEdge
            } else {
                onboardingArrowDirections[id] = .targetTopEdge
            }
        default:
            break
        }
        return onboardingArrowDirections[id] ?? .targetTopEdge
    }

    public func onboardingShouldCheckDependencies(for id: OnboardingID) -> Bool {
        return onboardingShouldCheckDependenciesMap[id] ?? true
    }

    public func onboardingDependencies(for id: OnboardingID) -> [OnboardingID] {
        return onboardingDependenciesMap[id] ?? []
    }

    public func onboardingNextID(for id: OnboardingID) -> OnboardingID? {
        return onboardingNextIDs[id]
    }
}

extension DocBrowserViewController: OnboardingFlowDataSource {
    public func onboardingIndex(for id: OnboardingID) -> String? {
        return onboardingIndexes[id]
    }

    public func onboardingSkipText(for id: OnboardingID) -> String? {
        if onboardingIsLast[id] == true {
            return nil
        } else {
            return BundleI18n.SKResource.Doc_Facade_Skip
        }
    }

    public func onboardingAckText(for id: OnboardingID) -> String {
        if onboardingIsLast[id] == true {
            return BundleI18n.SKResource.Onboarding_Got_It
        } else {
            return BundleI18n.SKResource.Doc_Facade_Next
        }
    }

    public func onboardingHollowStyle(for id: OnboardingID) -> OnboardingStyle.Hollow {
        return .circle
    }

    public func onboardingBleeding(for id: OnboardingID) -> CGFloat {
        switch id {
        case .docIPadCatalogIntro, .docWidescreenModeIntro: return 0
        default: return 8
        }
    }
}

extension DocBrowserViewController: OnboardingCardDataSource {
    public func onboardingStartText(for id: OnboardingID) -> String {
        BundleI18n.SKResource.Doc_Facade_StartTour
    }
}

// MARK: Helper Functions

extension DocBrowserViewController {

    func getBlockRect() -> CGRect {
        var targetRect = onboardingTargetRects[.docBlockMenuPenetrableComment] ?? .zero
        //Block上方的位置小于引导高度，且Block的高度超过屏幕半屏，Block快捷菜单评论引导的位置固定在半屏
        if targetRect.minY < blockMinTopDistance, targetRect.minY + targetRect.height > self.view.bounds.midY {
            targetRect.origin.y = self.view.bounds.midY
        }
        onboardingTargetRects[.docBlockMenuPenetrableComment] = targetRect
        return targetRect
    }

    func scrollToItem(by id: String) {
        guard !toolbarManager.toolBar.isHidden else { return }
        toolbarManager.toolBar.scrollToItem(byID: id)
    }

    func getToolbarMainItemFrame(by id: String) -> CGRect? {
        guard !toolbarManager.toolBar.isHidden else { return nil }
        return toolbarManager.toolBar.convertMainItem(id: id, frameTo: view)
    }
}
