//
//  AppDelegate.swift
//  Calendar
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import AnimatedTabBar
import LarkTab
import LKLoadable

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        LKLoadableManager.run(LoadableState(rawValue: 0))
        LKLoadableManager.run(LoadableState(rawValue: 1))
        LKLoadableManager.run(LoadableState(rawValue: 2))

        self.window = UIWindow()
        self.window?.backgroundColor = .white
        self.window?.makeKeyAndVisible()

        let rootVC = ViewController()
        let navi = Navi(rootViewController: rootVC)
        let item = MainTabBarItem(
            tab: Tab(url: "test", appType: .native, key: "test"),
            title: "Test",
            stateConfig: ItemStateConfig(
                defaultIcon: nil,
                selectedIcon: nil,
                quickBarIcon: nil,
                defaultTitleColor: UIColor.black,
                selectedTitleColor: UIColor.blue)
        )

        let tabBar = AnimatedTabBarController(enableQuickAction: true, tabBarConfig: TabBarConfig(minBottomTab: 1, maxBottomTab: 7))

        tabBar.mainTabBarItems = [item]
        tabBar.quickTabBarItems = []
        tabBar.setTabViewController(navi)
        tabBar.setHardwareKeyboardObserve(enable: true)

        self.window?.rootViewController = tabBar
        return true
    }
}
