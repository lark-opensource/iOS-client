//
//  TabProvider.swift
//  LarkApp
//
//  Created by Meng on 2019/10/16.
//

import UIKit
import Foundation
import EENavigator
import AnimatedTabBar
import LKCommonsLogging
import LarkUIKit
import LarkTab

extension RootNavigationController: TabProvider {
    private static let tabLogger = Logger.log(TabProvider.self, category: "TabProvider")

    public var tabbarController: UITabBarController? {
        return tabbar
    }

    public func switchTab(to tabIdentifier: String) {
        let tab = Tab.allSupportTabs.first { $0.urlString == tabIdentifier }
        if let targetTab = tab {
            tabbar?.switchTab(to: targetTab)
            return
        }

        assertionFailure("Regist Tab First")
        RootNavigationController.tabLogger.error(
            "can not find tabbar to switch vc: \(String(describing: tab?.urlString))"
        )
    }
}
