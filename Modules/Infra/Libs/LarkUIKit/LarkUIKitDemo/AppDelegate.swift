//
//  AppDelegate.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2017/12/7.
//  Copyright © 2017年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)

        if Display.pad {
            let tab = UITabBarController()
            tab.setViewControllers([
                defaultSplitVC(),
                defaultSplitVC()
            ], animated: false)

            window?.rootViewController = tab

        } else {
            let vc = ViewController()
            let nvc = LkNavigationController(rootViewController: vc)
            window?.rootViewController = nvc
        }

        window?.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func defaultSplitVC() -> UIViewController {
        let master = ViewController()
//        master.isNavigationBarHidden = true
//
//        let mnvc = LkNavigationController(rootViewController: master)
//
//        let detail = ViewController()
//        let dnvc = LkNavigationController(rootViewController: detail)

//        let splitVC = LKSplitViewController2(defaultVCProvider: <#() -> DefaultVCResult#>)
//        splitVC.masterViewController = mnvc
//        splitVC.detailViewController = dnvc
//        splitVC.preferredDisplayMode = .allVisible
//
//        splitVC.tabBarItem.title = "Split"

        return master
    }
}
