//
//  UIViewController+TabBarEvent.swift
//  AnimatedTabBar
//
//  Created by Meng on 2019/11/6.
//

import Foundation
import UIKit
import LarkTab

/// If tabbar (mainTab/quikTab)'s viewController implement this protocol,
/// `AnimatedTabBar` will send tab events to viewController
/// all methods will call when `selectedType` really changed.
public protocol TabBarEventViewController {
    /// send when `AnimatedTabBar` will set `selectedType` and before switch to the viewController.
    ///
    /// But note, you can't rely too much on this method,
    /// your viewController may be processed as lazy initialization in the future,
    /// then the order in which the tab is selected is **[init viewController] -> [will switch] -> [did switch]**
    @available(*, deprecated, message: "请使用新接口 tabBarController(:willSwitch:to:)")
    func willSwitchToTabBarController(_ tabType: TabType, oldType: TabType)

    /// send when `AnimatedTabBar` did set `selectedType` and did switch to the viewController successfully.
    @available(*, deprecated, message: "请使用新接口 tabBarController(:didSwitch:to:)")
    func didSwitchToTabBarController(_ tabType: TabType, oldType: TabType)

    /// send when `AnimatedTabBar` will set `selectedType` and before switch out the viewController.
    @available(*, deprecated, message: "请使用新接口 tabBarController(:willSwitchOut:to:)")
    func willSwitchOutTabBarController(_ tabType: TabType, oldType: TabType)

    /// send when `AnimatedTabBar` will set `selectedType` and did switch out the viewController successfully.
    @available(*, deprecated, message: "请使用新接口 tabBarController(:didSwitchOut:to:)")
    func didSwitchOutTabBarController(_ tabType: TabType, oldType: TabType)

    /// send when `AnimatedTabBar` will set `selectedType` and before switch to the viewController.
    ///
    /// But note, you can't rely too much on this method,
    /// your viewController may be processed as lazy initialization in the future,
    /// then the order in which the tab is selected is **[init viewController] -> [will switch] -> [did switch]**
    /// - Note: 原来的 tabType 可以通过 tabBarController.tabType(of:) 来获取
    func tabBarController(_ tabBarController: AnimatedTabBarController,
                          willSwitch tab: Tab,
                          to newTab: Tab)

    /// send when `AnimatedTabBar` did set `selectedType` and did switch to the viewController successfully.
    /// - Note: 原来的 tabType 可以通过 tabBarController.tabType(of:) 来获取
    func tabBarController(_ tabBarController: AnimatedTabBarController,
                          didSwitch tab: Tab,
                          to newTab: Tab)

    /// send when `AnimatedTabBar` will set `selectedType` and before switch out the viewController.
    /// - Note: 原来的 tabType 可以通过 tabBarController.tabType(of:) 来获取
    func tabBarController(_ tabBarController: AnimatedTabBarController,
                          willSwitchOut tab: Tab,
                          to newTab: Tab)

    /// send when `AnimatedTabBar` will set `selectedType` and did switch out the viewController successfully.
    /// - Note: 原来的 tabType 可以通过 tabBarController.tabType(of:) 来获取
    func tabBarController(_ tabBarController: AnimatedTabBarController,
                          didSwitchOut tab: Tab,
                          to newTab: Tab)
}

public extension TabBarEventViewController {
    func willSwitchToTabBarController(_ tabType: TabType, oldType: TabType) {}
    func didSwitchToTabBarController(_ tabType: TabType, oldType: TabType) {}
    func willSwitchOutTabBarController(_ tabType: TabType, oldType: TabType) {}
    func didSwitchOutTabBarController(_ tabType: TabType, oldType: TabType) {}

    // 桥接老接口，以后删

    func tabBarController(_ tabBarController: AnimatedTabBarController,
                          willSwitch tab: Tab,
                          to newTab: Tab) {
        let tabType = tabBarController.tabType(of: newTab)
        let oldType = tabBarController.tabType(of: tab)
        willSwitchToTabBarController(tabType, oldType: oldType)
    }

    func tabBarController(_ tabBarController: AnimatedTabBarController,
                          didSwitch tab: Tab,
                          to newTab: Tab) {
        let tabType = tabBarController.tabType(of: newTab)
        let oldType = tabBarController.tabType(of: tab)
        didSwitchToTabBarController(tabType, oldType: oldType)
    }

    func tabBarController(_ tabBarController: AnimatedTabBarController,
                          willSwitchOut tab: Tab,
                          to newTab: Tab) {
        let tabType = tabBarController.tabType(of: newTab)
        let oldType = tabBarController.tabType(of: tab)
        willSwitchOutTabBarController(tabType, oldType: oldType)
    }

    func tabBarController(_ tabBarController: AnimatedTabBarController,
                          didSwitchOut tab: Tab,
                          to newTab: Tab) {
        let tabType = tabBarController.tabType(of: newTab)
        let oldType = tabBarController.tabType(of: tab)
        didSwitchOutTabBarController(tabType, oldType: oldType)
    }
}
