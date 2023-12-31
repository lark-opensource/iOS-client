//
//  DocsSpaceHomeInterceptor.swift
//  SKCommon
//
//  Created by huayufan on 2021/1/11.
//  


import Foundation
import SKFoundation

class DocsSpaceHomeInterceptor: DocsMagicInterceptor {

    override func currentIsTopMost() -> Bool {
        if let nav = presentController as? UINavigationController,
           nav.viewControllers.count > 2 { // FeelGood控制器会预先加载
            DocsLogger.error("展示FeelGood期间 导航栏子控制器数: \(nav.viewControllers.count)")
            return false
        }
        
        if let current = currentController,
           let presentedVC = current.presentedViewController {
            DocsLogger.error("展示FeelGood期间 SpaceHome present: \(presentedVC)")
            return false
        }
        
        return OnboardingManager.shared.hasActiveOnboardingSession
    }
}
