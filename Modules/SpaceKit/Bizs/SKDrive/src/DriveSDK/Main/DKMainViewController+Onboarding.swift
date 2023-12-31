//
//  DKMainViewController+Wiki.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/5.
//swiftlint:disable orphaned_doc_comment

import Foundation
import SKCommon
import SKUIKit
import SKFoundation
import RxSwift
import SKResource
import Lottie

extension DKMainViewController {
    public func getNavBarRightButtonFrame(by id: SKNavigationBar.ButtonIdentifier) -> CGRect? {
        guard !navigationBar.isHidden else { return nil }
        for button in navigationBar.trailingButtons where button.item?.id == id {
            guard !button.isHidden && button.bounds != .zero else { return nil }
            return button.convert(button.bounds, to: view)
        }
        return nil
    }
}

// - MARK: Delegates
extension DKMainViewController: OnboardingDelegate {
    
    public func onboardingManagerRejectedThisTime(_ id: OnboardingID) {
        DocsLogger.onboardingInfo("onboardingManagerRejectedThisTime \(id) ")
    }
    
    public func onboardingDisabledInMinaConfiguration(for id: OnboardingID) {
        DocsLogger.onboardingInfo("onboardingDisabledInMinaConfiguration \(id)")
    }
    
    public func onboardingAlreadyFinished(_ id: OnboardingID) {
        DocsLogger.onboardingInfo("\(id) onboardingAlreadyFinished")
    }
    
    public func onboardingDependenciesUnfinished(for id: OnboardingID) {
        DocsLogger.onboardingInfo("onboardingDependenciesUnfinished \(id)")
    }
    
    public func onboardingMaterialNotEnough(for id: OnboardingID) {
        skAssertionFailure("onboardingMaterialNotEnough \(id)！")
    }
    
    public func onboardingDidRegister(_ id: OnboardingID) {
    }
    
    public func onboardingWindowSizeWillChange(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        DocsLogger.onboardingInfo(" \(id) onboardingWindowSizeWillChange")
        return .acknowledge
    }
    
    public func onboardingTargetViewDidDisappear(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        return .acknowledge
    }
    
    public func onboardingAcknowledge(_ id: OnboardingID) {
        
    }
    
    public func onboardingSkip(_ id: OnboardingID) {
       
    }
}

// - MARK: Data Sources
extension DKMainViewController: OnboardingDataSource {
    public func onboardingType(of id: OnboardingID) -> OnboardingType {
        return .text
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
        return ""
    }
    
    public func onboardingHint(for id: OnboardingID) -> String {
        return ""
    }
    
    public func onboardingTargetRect(for id: OnboardingID) -> CGRect {
        return .zero
    }
    
    public func onboardingArrowDirection(for id: OnboardingID) -> OnboardingStyle.ArrowDirection {
        return .targetTopEdge
    }
}

extension DKMainViewController: OnboardingFlowDataSource {
    public func onboardingIndex(for id: OnboardingID) -> String? {
        return nil
    }
    public func onboardingSkipText(for id: OnboardingID) -> String? {
        return BundleI18n.SKResource.Doc_Facade_Skip
    }
    
    public func onboardingAckText(for id: OnboardingID) -> String {
        return BundleI18n.SKResource.Onboarding_Got_It
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

extension DKMainViewController: OnboardingCardDataSource {
    public func onboardingStartText(for id: OnboardingID) -> String {
        return BundleI18n.SKResource.Doc_Facade_StartTour
    }
}
