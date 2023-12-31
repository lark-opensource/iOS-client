//
// Created by zoujie.andy on 2022/1/17.
// Affiliated with SKBitable.
//
// Description: Bitable Browser 相关的 Onboarding 代理方法实现

import SKUIKit
import SKCommon
import SKBrowser
import SKFoundation
import SKResource
import Lottie

// - MARK: Delegates
extension BitableBrowserViewController: OnboardingDelegate {

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
    }

    public func onboardingWindowSizeWillChange(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        DocsLogger.onboardingInfo("在播放引导 \(id) 的时候 window 发生了尺寸变化，acknowledge 了")
        return .acknowledge
    }

    public func onboardingTargetViewDidDisappear(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        return .acknowledge
    }
    
    public func onboardingDidAppear(_ id: OnboardingID) {
        if id == .bitableExposeCatalogIntro {
            DocsTracker.newLog(enumEvent: .bitableMobileSidebarGuideView, parameters: getCatalogEventCommonParams())
        }
        if id == .bitableFileAddToWorkbenchGuide {
            var params: [String: String] = [:]
            if let docsInfo = docsInfo {
                params = DocsParametersUtil.createCommonParams(by: docsInfo)
            }
            DocsTracker.newLog(enumEvent: .bitableAddToWorkplaceOnboardingView, parameters: params)
        } else if id == .mobileBitableGridMobileView1 || id == .mobileBitableGridMobileView2 {
            let params = BTEventParamsGenerator.createCommonParamsByGlobalInfo(docsInfo: docsInfo)
            DocsTracker.newLog(enumEvent: .bitableMobileGridEditOnboardingView, parameters: params)
        }
    }

    public func onboardingAcknowledge(_ id: OnboardingID) {
        switch id {
        case .bitableExposeCatalogIntro:
            var parameters = getCatalogEventCommonParams()
            parameters["click"] = "confirm"
            parameters["target"] = "none"
            DocsTracker.newLog(enumEvent: .bitableMobileSidebarGuideClick, parameters: parameters)
        case .mobileBitableGridMobileView1:
            var params = BTEventParamsGenerator.createCommonParamsByGlobalInfo(docsInfo: docsInfo)
            params["click"] = "next"
            DocsTracker.newLog(enumEvent: .bitableMobileGridEditOnboardingClick, parameters: params)
        case .mobileBitableGridMobileView2:
            var params = BTEventParamsGenerator.createCommonParamsByGlobalInfo(docsInfo: docsInfo)
            params["click"] = "know"
            DocsTracker.newLog(enumEvent: .bitableMobileGridEditOnboardingClick, parameters: params)
        default:
            if onboardingIsLast[id] == true {
                OnboardingManager.shared.setTemporarilyRejectsUpcomingOnboardings()
            }
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

extension BitableBrowserViewController: OnboardingDataSource {

    public func onboardingType(of id: OnboardingID) -> OnboardingType {
        guard let type = onboardingTypes[id] else {
            fatalError("小傻瓜，是不是忘了配引导类型了？")
        }
        return type
    }

    public func onboardingIsAsynchronous(for id: OnboardingID) -> Bool {
        return [].contains(id)
    }

    public func onboardingSupportedInterfaceOrientations(for id: OnboardingID) -> UIInterfaceOrientationMask {
        if SKDisplay.pad { return [.all] }
        return [.portrait]
    }

    public func onboardingTapBubbleOutsideBehavior(of id: OnboardingID) -> OnboardingStyle.TapBubbleOutsideBehavior {
        return .disappearWithoutPenetration
    }

    public func onboardingDisappearStyle(of id: OnboardingID) -> OnboardingStyle.DisappearStyle {
        return .immediatelyAfterUserInteraction
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
        case .bitableFileAddToWorkbenchGuide:
            onboardingTargetRects[id] = getNavBarRightButtonFrame(by: .more)
        default: ()
        }
        return onboardingTargetRects[id] ?? .zero
    }

    public func onboardingArrowDirection(for id: OnboardingID) -> OnboardingStyle.ArrowDirection {
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

extension BitableBrowserViewController: OnboardingFlowDataSource {
    public func onboardingIndex(for id: OnboardingID) -> String? {
        return onboardingIndexes[id]
    }

    public func onboardingSkipText(for id: OnboardingID) -> String? {
        if id == .bitableExposeCatalogIntro || id == .mobileBitableGridMobileView1 || id == .mobileBitableGridMobileView2 {
            return nil
        }
        if onboardingIsLast[id] == true {
            return nil
        } else {
            return BundleI18n.SKResource.Doc_Facade_Skip
        }
    }

    public func onboardingAckText(for id: OnboardingID) -> String {
        if id == .bitableExposeCatalogIntro || id == .mobileBitableGridMobileView2 {
            return BundleI18n.SKResource.Onboarding_Got_It
        } else if id == .mobileBitableGridMobileView1 {
            return BundleI18n.SKResource.Doc_Facade_Next
        }
        if onboardingIsLast[id] == true {
            return BundleI18n.SKResource.Onboarding_Got_It
        } else {
            return BundleI18n.SKResource.Doc_Facade_Next
        }
    }

    public func onboardingHasMask(for id: OnboardingID) -> Bool {
        if id == .bitableExposeCatalogIntro {
            return false
        } else if id == .mobileBitableGridMobileView2 {
            return false
        }
        return true
    }

    public func onboardingHollowStyle(for id: OnboardingID) -> OnboardingStyle.Hollow {
        switch id {
        case .mobileBitableGridMobileView1:
            return .roundedRect(8)
        default:
            return .circle
        }
    }

    public func onboardingBleeding(for id: OnboardingID) -> CGFloat {
        switch id {
        case .mobileBitableGridMobileView1, .mobileBitableGridMobileView2:
            return 0
        default:
            return 8
        }
    }
}

extension BitableBrowserViewController: OnboardingCardDataSource {
    public func onboardingStartText(for id: OnboardingID) -> String {
        return BundleI18n.SKResource.Doc_Facade_StartTour
    }
}

extension BitableBrowserViewController {
    private func getCatalogEventCommonParams() -> [String: String] {
        let baseData = BTBaseData(
            baseId: self.currentCatalogData?.baseId ?? "",
            tableId: self.currentCatalogData?.tableId ?? "",
            viewId: self.currentCatalogData?.viewId ?? ""
        )
        return BTEventParamsGenerator.createCommonParams(by: docsInfo, baseData: baseData)
    }
}
