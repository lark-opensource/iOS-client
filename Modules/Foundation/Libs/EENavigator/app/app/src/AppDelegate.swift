//
//  AppDelegate.swift
//  EENavigatorDemo
//
//  Created by liuwanlin on 2018/9/9.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import EENavigator

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var tabProvider = TabProviderImpl()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        registerRouter()

        Navigator.shared.tabProvider = {
            return self.tabProvider
        }

        let tabFeed: UIViewController! = Navigator.shared
            .response(for: URL(string: "//feed?count=10")!)
            .resource as? UIViewController
        tabFeed.accessibilityLabel = "//feed"

        let tabCalendar: UIViewController! = Navigator.shared
            .response(for: URL(string: "//clendar")!)
            .resource as? UIViewController
        tabCalendar.accessibilityLabel = "//clendar"

        let tabMine: UIViewController! = Navigator.shared
            .response(for: URL(string: "//mine")!)
            .resource as? UIViewController
        tabMine.accessibilityLabel = "//mine"

        let rootViewController = UITabBarController()
        rootViewController.identifier = "//root"
        rootViewController.viewControllers = [tabFeed, tabCalendar, tabMine]

        tabProvider.tabbarController = rootViewController

        let window = UIWindow()
        window.rootViewController = rootViewController
        self.window = window
        self.window?.makeKeyAndVisible()

        return true
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let window = self.window else {
            return false
        }
        Navigator.shared.open(url, from: window)
        return true
    }

}

class TabProviderImpl: TabProvider {

    var tabbarController: UITabBarController?

    public func switchTab(to tabIdentifier: String) {

        if let index = tabbarController?.viewControllers?.firstIndex(where: { (vc) -> Bool in
            return vc.accessibilityLabel == tabIdentifier
        }) {
            tabbarController?.selectedIndex = index
        }
    }
}

