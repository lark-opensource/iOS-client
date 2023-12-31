//
//  LarkOpenplatformMyAIServiceIMP.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/5/29.
//

import Foundation
import RxSwift
import EENavigator
import LarkContainer
import LarkQuickLaunchBar
import LarkQuickLaunchInterface
import LarkOPInterface
import LKCommonsLogging
import LarkAIInfra

private let logger = Logger.log(LauncherMoreMenuPlugin.self, category: "LauncherMoreMenuPlugin")

final class LarkOpenplatformMyAIServiceIMP: LarkOpenPlatformMyAIService {
    private let resolver: Resolver
    
    init(resolver: Resolver) {
        self.resolver = resolver
    }
    
    func isQuickLaunchBarEnable() -> Bool {
        guard let dependency = resolver.resolve(OpenPlatformDependency.self) else {
            logger.info("OpenPlatformDependency is nil")
            return false
        }
        return dependency.isQuickLaunchBarEnable()
    }
    
    func createAIQuickLaunchBar(items: [QuickLaunchBarItem],
                                enableTitle: Bool,
                                enableAIItem: Bool,
                                quickLaunchBarEventHandler: LarkOPInterface.OPMyAIQuickLaunchBarEventHandler?) -> MyAIQuickLaunchBarInterface?{
        guard let dependency = resolver.resolve(OpenPlatformDependency.self) else {
            logger.info("OpenPlatformDependency is nil")
            return nil
        }
        return dependency.createAIQuickLaunchBar(items: items, enableTitle: enableTitle, enableAIItem: enableAIItem, quickLaunchBarEventHandler: quickLaunchBarEventHandler)
    }
    
    func isTemporaryEnabled() -> Bool {
        guard let dependency = resolver.resolve(OpenPlatformDependency.self) else {
            logger.info("OpenPlatformDependency is nil")
            return false
        }
        return dependency.isTemporaryEnabled()
    }

    func showTabVC(_ vc: UIViewController) {
        guard let dependency = resolver.resolve(OpenPlatformDependency.self) else {
            logger.info("OpenPlatformDependency is nil")
            return
        }
        dependency.showTabVC(vc)
    }
    func updateTabVC(_ vc: UIViewController) {
        guard let dependency = resolver.resolve(OpenPlatformDependency.self) else {
            logger.info("OpenPlatformDependency is nil")
            return
        }
        dependency.updateTabVC(vc)
    }
//    func getTabVCBy(id: String) -> TabContainable?
    func removeTabVC(_ vc: UIViewController) {
        guard let dependency = resolver.resolve(OpenPlatformDependency.self) else {
            logger.info("OpenPlatformDependency is nil")
            return
        }
        dependency.removeTabVC(vc)
    }
}
