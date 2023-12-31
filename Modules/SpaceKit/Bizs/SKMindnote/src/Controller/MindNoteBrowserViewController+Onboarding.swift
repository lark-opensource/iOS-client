//
//  MindNoteBrowserViewController+Onboarding.swift
//  SKMindnote
//
//  Created by guoqp on 2022/9/20.
//swiftlint:disable trailing_newline

import SKUIKit
import SKCommon
import SKBrowser
import SKFoundation
import SKResource
import Lottie

// - MARK: Delegates
extension MindNoteBrowserViewController: OnboardingDelegate {

    public func onboardingManagerRejectedThisTime(_ id: OnboardingID) {
        DocsLogger.onboardingInfo("onboardingManagerRejectedThisTime\(id)")
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "failed"],
                                             completion: nil)
    }

    public func onboardingDisabledInMinaConfiguration(for id: OnboardingID) {
        DocsLogger.onboardingInfo("onboardingDisabledInMinaConfiguration \(id)")
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "failed"],
                                             completion: nil)
    }

    public func onboardingAlreadyFinished(_ id: OnboardingID) {
        DocsLogger.onboardingInfo("\(id) onboardingAlreadyFinished")
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "success"],
                                             completion: nil)
    }

    public func onboardingDependenciesUnfinished(for id: OnboardingID) {
        DocsLogger.onboardingInfo("onboardingDependenciesUnfinished \(onboardingDependencies(for: id)) onboardingDependenciesUnfinished \(id)")
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "failed"],
                                             completion: nil)
    }

    public func onboardingMaterialNotEnough(for id: OnboardingID) {
        skAssertionFailure("onboardingMaterialNotEnough \(id)！")
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "failed"],
                                             completion: nil)
    }

    public func onboardingDidRegister(_ id: OnboardingID) {
    }

    public func onboardingWindowSizeWillChange(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        DocsLogger.onboardingInfo("\(id) onboardingWindowSizeWillChange")
        return .acknowledge
    }

    public func onboardingTargetViewDidDisappear(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
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

extension MindNoteBrowserViewController: OnboardingDataSource {

    public func onboardingType(of id: OnboardingID) -> OnboardingType {
        guard let type = onboardingTypes[id] else {
            fatalError("no type")
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

extension MindNoteBrowserViewController: OnboardingFlowDataSource {
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

    public func onboardingHasMask(for id: OnboardingID) -> Bool {
        return true
    }

    public func onboardingHollowStyle(for id: OnboardingID) -> OnboardingStyle.Hollow {
        return .circle
    }

    public func onboardingBleeding(for id: OnboardingID) -> CGFloat {
        return 8
    }
}

extension MindNoteBrowserViewController: OnboardingCardDataSource {
    public func onboardingStartText(for id: OnboardingID) -> String {
        return BundleI18n.SKResource.Doc_Facade_StartTour
    }
}

