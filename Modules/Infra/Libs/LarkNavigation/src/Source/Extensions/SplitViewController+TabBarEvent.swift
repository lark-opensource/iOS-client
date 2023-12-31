//
//  SplitViewController+TabBarEvent.swift
//  LarkNavigation
//
//  Created by Meng on 2019/11/7.
//

import UIKit
import Foundation
import AnimatedTabBar
import LarkUIKit
import LarkTab
import LarkSplitViewController

// for UISplitVC & LKSplitVC
extension UISplitViewController: TabBarEventViewController {
    public func tabBarController(_ tabBarController: AnimatedTabBarController, willSwitch tab: Tab, to newTab: Tab) {
        tabEventVC?.tabBarController(tabBarController, willSwitch: tab, to: newTab)
    }

    public func tabBarController(_ tabBarController: AnimatedTabBarController, didSwitch tab: Tab, to newTab: Tab) {
        tabEventVC?.tabBarController(tabBarController, didSwitch: tab, to: newTab)
    }

    public func tabBarController(_ tabBarController: AnimatedTabBarController, willSwitchOut tab: Tab, to newTab: Tab) {
        tabEventVC?.tabBarController(tabBarController, willSwitchOut: tab, to: newTab)
    }

    public func tabBarController(_ tabBarController: AnimatedTabBarController, didSwitchOut tab: Tab, to newTab: Tab) {
        tabEventVC?.tabBarController(tabBarController, didSwitchOut: tab, to: newTab)
    }
}

extension SplitViewController: TabBarEventViewController {
    public func tabBarController(_ tabBarController: AnimatedTabBarController, willSwitch tab: Tab, to newTab: Tab) {
        tabEventVC?.tabBarController(tabBarController, willSwitch: tab, to: newTab)
    }

    public func tabBarController(_ tabBarController: AnimatedTabBarController, didSwitch tab: Tab, to newTab: Tab) {
        tabEventVC?.tabBarController(tabBarController, didSwitch: tab, to: newTab)
    }

    public func tabBarController(_ tabBarController: AnimatedTabBarController, willSwitchOut tab: Tab, to newTab: Tab) {
        tabEventVC?.tabBarController(tabBarController, willSwitchOut: tab, to: newTab)
    }

    public func tabBarController(_ tabBarController: AnimatedTabBarController, didSwitchOut tab: Tab, to newTab: Tab) {
        tabEventVC?.tabBarController(tabBarController, didSwitchOut: tab, to: newTab)
    }
}
