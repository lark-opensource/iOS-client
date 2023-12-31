//
//  LarkVersionDependencyImpl.swift
//  LarkVersionAssembly
//
//  Created by 张威 on 2022/1/19.
//

import UIKit
import Foundation
import EENavigator
import AnimatedTabBar
import LarkTab
import LarkUIKit
import LKCommonsLogging
import LarkVersion
import LarkNavigation

final class LarkVersionDependencyImpl: LarkVersionDependency {

    // 判断当前是否处于 feed 首页，仅当处于 feed 首页时才允许 upgrade 弹窗
    func enableShowUpgradeAlert() -> Bool {
        assert(Thread.isMainThread, "should occur on main thread!")
        guard let tabbar = UIApplication.shared.windows.compactMap({ (window) -> AnimatedTabBarController? in
            UIViewController
                .topMost(of: window.rootViewController, checkSupport: false)?
                .tabBarController as? AnimatedTabBarController
        }).first,
              let topMost: UIViewController = UIViewController.topMost(of: tabbar, checkSupport: false) else {
                  Self.log.error("tabbar is nil!")
                  return false
              }
        guard let feedRootVC = tabbar.viewController(for: Tab.feed)?.tabRootViewController else {
            Self.log.error("feedRoot is not found!")
            return false
        }
        // Feed Tab
        let feedNavi = topMost.larkSplitViewController?.sideNavigationController as? UINavigationController
        let topMostPad = feedNavi?.topViewController
        /// 兼容ipad
        let targetVC = Display.pad ? topMostPad : topMost
        Self.log.info("targetVC - \(targetVC); feedRootVC - \(feedRootVC)")
        return targetVC === feedRootVC
    }

    static let log = Logger.log(LarkVersionDependencyImpl.self, category: "LarkVersionAssembly")
}
