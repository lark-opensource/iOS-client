//
//  DocMagicInterceptor.swift
//  SKBrowser
//
//  Created by huayufan on 2021/1/4.
//  


import Foundation
import SKUIKit
import UniverseDesignDialog
import SKFoundation
import LarkMagic

class DocsMagicInterceptor {
    
    weak var presentController: UIViewController?
    weak var currentController: UIViewController?
    weak var businessInterceptor: BusinessInterceptor?
    var keyboard: Keyboard
    var isKeyboardShowing = false
    
    init() {
        keyboard = Keyboard()
        listenToKeyboardEvent()
    }
    
    func listenToKeyboardEvent () {
        keyboard.on(event: .willShow) { [weak self] (_) in
            self?.isKeyboardShowing = true
        }
        keyboard.on(event: .willHide) { [weak self] (_) in
            self?.isKeyboardShowing = false
        }
        keyboard.start()
    }
    
    func currentIsTopMost() -> Bool {
        return true
    }

    deinit {
        keyboard.stop()
    }
}

// MARK: - ScenarioInterceptor
extension DocsMagicInterceptor: SpaceFeelGoodInterceptor {
    
    var isAlterShowing: Bool {
        // LarkAlertController 弹窗
        guard let presentedViewController = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController else {
            return false
        }
        if presentedViewController.isKind(of: UDDialog.self) {
            DocsLogger.info("展示FeelGood期间存在弹窗")
            return true
        }
        return false
    }

    var isPopoverShowing: Bool {
        let isMenuVisible = UIMenuController.shared.isMenuVisible
        if isMenuVisible {
            DocsLogger.info("展示FeelGood期间存在气泡")
        }
        return isMenuVisible
    }
    
    var isDrawerShowing: Bool {
        if isKeyboardShowing {
            DocsLogger.info("展示FeelGood期间存在键盘")
        }
        return isKeyboardShowing
    }
    
    var isModalShowing: Bool {
        guard presentController?.presentedViewController == nil else {
            DocsLogger.info("展示FeelGood期间 isModalShowing")
            return true
        }
        return false
    }
    
    var otherInterceptEvent: Bool {
        guard currentIsTopMost() else {
            return false
        }
        if let interceptor = businessInterceptor,
           interceptor.hasOtherInterceptEvent {
            return false
        }
        if OnboardingManager.shared.hasActiveOnboardingSession {
            DocsLogger.error("展示FeelGood期间 展示Onboarding")
        }
        return OnboardingManager.shared.hasActiveOnboardingSession
    }
}
