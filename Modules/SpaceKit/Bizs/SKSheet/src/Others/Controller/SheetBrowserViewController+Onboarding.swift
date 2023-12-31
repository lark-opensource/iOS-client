//
// Created by duanxiaochen.7 on 2021/2/5.
// Affiliated with SKSheet.
//
// Description: Sheet Browser 相关的 Onboarding 代理方法实现

import SKUIKit
import SKCommon
import SKBrowser
import SKFoundation
import SKResource
import RxSwift
import Lottie
import UniverseDesignIcon
import UniverseDesignEmpty
import LarkIllustrationResource

//引导位置在block上方所需距离屏幕顶部的最小距离
private let blockMinTopDistance: CGFloat = 194

// - MARK: Delegates
extension SheetBrowserViewController: OnboardingDelegate {

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

    public func onboardingDidRegister(_ id: OnboardingID) {
        if !OnboardingManager.shared.hasFinished(.sheetToolbarIntro), id == .sheetToolbarIntro {
            // async 到下一个 runloop 执行，用于摆脱键盘的 animation transition context
            // 不然引导的 animation transition context 会合并到键盘的动画中，导致引导 view 的布局过程被动画展示了出来
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) { [weak self] in
                guard let toolbar = self?.toolbar, let view = self?.view else { return }
                let toolbarFrameInBrowser = toolbar.convert(toolbar.bounds, to: view)
                if toolbarFrameInBrowser != .zero {
                    self?.onboardingTargetRects[.sheetToolbarIntro] = toolbarFrameInBrowser
                    toolbar.revealHiddenItemsIfNeededBeforeOnboarding {
                        OnboardingManager.shared.targetView(for: [.sheetToolbarIntro], updatedExistence: true)
                    }
                } else {
                    DocsLogger.debug("somehow sheet toolbar is not visible")
                }
            }
        } else {
            if !OnboardingManager.shared.hasFinished(.sheetCardModeToolbar), id == .sheetCardModeToolbar {
                // async 到下一个 runloop 执行，用于摆脱键盘的 animation transition context
                // 不然引导的 animation transition context 会合并到键盘的动画中，导致引导 view 的布局过程被动画展示了出来
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) { [weak self] in
                    guard let toolbar = self?.toolbar, let view = self?.view else { return }
                    guard let cardModeItemFrame = toolbar.frameOfItem(id: .editInCard) else { return }
                    let cardModeItemFrameInBrowser = toolbar.convert(cardModeItemFrame, to: view)
                    self?.onboardingTargetRects[.sheetCardModeToolbar] = cardModeItemFrameInBrowser
                    OnboardingManager.shared.targetView(for: [.sheetCardModeToolbar], updatedExistence: true)
                }
            }
        }
    }

    public func onboardingWindowSizeWillChange(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        DocsLogger.onboardingInfo("在播放引导 \(id) 的时候 window 发生了尺寸变化，acknowledge 了")
        return .acknowledge
    }

    public func onboardingTargetViewDidDisappear(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        // MARK: FAB 相关引导
        DocsLogger.onboardingInfo("onboarding targetView disappear with id:\(id) acknowledge")
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
}

// - MARK: Data Sources

extension SheetBrowserViewController: OnboardingDataSource {

    public func onboardingType(of id: OnboardingID) -> OnboardingType {
        guard let type = onboardingTypes[id] else {
            fatalError("小傻瓜，是不是忘了配引导类型了？")
        }
        return type
    }

    public func onboardingIsAsynchronous(for id: OnboardingID) -> Bool {
        return [
            .sheetToolbarIntro,          // 指向工具栏
            .sheetOperationPanelOperate, // 指向操作面板的“操作”tab
            .sheetCardModeShare,         // 等候工作表栏隐藏之后再指向 webview 中的分享按钮
            .sheetCardModeToolbar        // 指向工具栏的卡片编辑按钮
        ].contains(id)
    }

    public func onboardingSupportedInterfaceOrientations(for id: OnboardingID) -> UIInterfaceOrientationMask {
        if SKDisplay.pad { return [.all] }
        switch id {
        case .sheetLandscapeIntro: return [.portrait, .landscape]
        default: return [.portrait]
        }
    }

    public func onboardingTapBubbleOutsideBehavior(of id: OnboardingID) -> OnboardingStyle.TapBubbleOutsideBehavior {
        switch id {
        case .sheetCardModeToolbar, .sheetToolbarIntro, .sheetOperationPanelOperate: return .nothing
        default:
            switch onboardingType(of: id) {
            case .text: return .disappearAndPenetrate
            case .flow: return .disappearWithoutPenetration
            case .card: return .nothing
            }
        }
    }

    public func onboardingDisappearStyle(of id: OnboardingID) -> OnboardingStyle.DisappearStyle {
        return .immediatelyAfterUserInteraction
    }

    public func onboardingHostViewController(for id: OnboardingID) -> UIViewController {
        return self
    }

    public func onboardingImage(for id: OnboardingID) -> UIImage? {
        switch id {
        case .sheetLandscapeIntro:
            return LarkIllustrationResource.Resources.ccmOnboardingHorizontalMobile
        case .sheetNewbieIntro, .sheetRedesignCardModeEdit:
            return LarkIllustrationResource.Resources.ccmOnboardingWelcomeSheetMobile
        default:
            return nil
        }
    }

    public func onboardingTitle(for id: OnboardingID) -> String? {
        return onboardingTitles[id]
    }

    public func onboardingHint(for id: OnboardingID) -> String {
        return onboardingHints[id] ?? ""
    }

    public func onboardingTargetRect(for id: OnboardingID) -> CGRect {
        switch id {
        case .sheetRedesignListMode:
            onboardingTargetRects[id] = getNavBarRightButtonFrame(by: .more)
        case .sheetNewbieSearch:
            onboardingTargetRects[id] = getNavBarRightButtonFrame(by: .findAndReplace)
        case .sheetNewbieEdit:
            onboardingTargetRects[id] = getFABButtonFrame(by: .keyboard)
        default: ()
        }
        return onboardingTargetRects[id] ?? .zero
    }

    public func onboardingArrowDirection(for id: OnboardingID) -> OnboardingStyle.ArrowDirection {
        switch id {
        case .sheetRedesignViewImage:
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

extension SheetBrowserViewController: OnboardingFlowDataSource {
    public func onboardingIndex(for id: OnboardingID) -> String? {
        return onboardingIndexes[id]
    }

    public func onboardingSkipText(for id: OnboardingID) -> String? {
        // 默认逻辑是前端传 isLast 来决定跳过按钮是否显示
        // 对于一些 case 下，前端即便传了 isLast == false，也要当作最后一个引导来配置文案
        if [
            .sheetToolbarIntro,
            .sheetOperationPanelOperate,
            .sheetCardModeShare,
            .sheetCardModeToolbar
        ].contains(id) {
            return nil
        }
        if onboardingIsLast[id] == true {
            return nil
        } else {
            return BundleI18n.SKResource.Doc_Facade_Skip
        }
    }

    public func onboardingAckText(for id: OnboardingID) -> String {
        // 默认逻辑是前端传 isLast 来决定确定按钮的文案和显示
        // 对于一些 case 下，前端即便传了 isLast == false，也要当作最后一个引导来配置文案
        if [
            .sheetToolbarIntro,
            .sheetOperationPanelOperate,
            .sheetCardModeShare,
            .sheetCardModeToolbar
        ].contains(id) {
            return BundleI18n.SKResource.Onboarding_Got_It
        }
        if onboardingIsLast[id] == true {
            return BundleI18n.SKResource.Onboarding_Got_It
        } else {
            return BundleI18n.SKResource.Doc_Facade_Next
        }
    }

    public func onboardingHasMask(for id: OnboardingID) -> Bool {
        switch id {
        case .sheetCardModeShare:
            return false
        default:
            return true
        }
    }

    public func onboardingHollowStyle(for id: OnboardingID) -> OnboardingStyle.Hollow {
        switch id {
        case .sheetOperationPanelOperate, .sheetToolbarIntro, .sheetCardModeToolbar: return .roundedRect(0)
        default: return .circle
        }
    }

    public func onboardingBleeding(for id: OnboardingID) -> CGFloat {
        switch id {
        case .sheetNewbieSearch, .sheetOperationPanelOperate, .sheetToolbarIntro, .sheetCardModeToolbar: return 0
        default: return 8
        }
    }
}

extension SheetBrowserViewController: OnboardingCardDataSource {
    public func onboardingStartText(for id: OnboardingID) -> String {
        switch id {
        case .sheetLandscapeIntro, .sheetRedesignCardModeEdit:
            return BundleI18n.SKResource.Onboarding_Got_It
        default:
            return BundleI18n.SKResource.Doc_Facade_StartTour
        }
    }
}

// MARK: Helper Functions

extension SheetBrowserViewController {

    var sheetToolkitButtonFrame: CGRect? {
        guard let fabContainer = editor.fabContainer, fabContainer.superview != nil else { return nil }
        for button in fabContainer.subviews where button is PrimaryButtonWithText {
            guard !button.isHidden && button.bounds != .zero else { return nil }
            return button.convert(button.bounds, to: view)
        }
        return nil
    }

    func getFABButtonFrame(by id: FABIdentifier) -> CGRect? {
        guard let fabContainer = editor.fabContainer, fabContainer.superview != nil else { return nil }
        for button in fabContainer.subviews {
            if let btn = button as? FloatButton, btn.buttonIdentifier == id {
                guard !btn.isHidden && btn.bounds != .zero else { return nil }
                return btn.convert(btn.bounds, to: view)
            }
        }
        return nil
    }
}
