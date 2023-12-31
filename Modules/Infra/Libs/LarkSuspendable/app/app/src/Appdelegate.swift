//
//  AppDelegate.swift
//  Lark
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import LarkSuspendable
import EENavigator
import LarkUIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        let listController = MainViewController()
        let naviVC = LkNavigationController(rootViewController: listController)
        naviVC.navigationBar.isTranslucent = false
        self.window?.rootViewController = naviVC
        self.window?.makeKeyAndVisible()
        // Register router
        Navigator.shared.registerRoute(type: DetailVCBody.self) {
            return DetailVCHandler()
        }
        Navigator.shared.registerRoute(type: WarmStartBody.self) {
            return WarmStartHandler()
        }
        Navigator.shared.registerRoute(type: ColdStartBody.self) {
            return ColdStartHandler()
        }
        Navigator.shared.registerRoute(type: UniqueVCBody.self) {
            return UniqueVCHandler()
        }
        SuspendManager.swizzleViewControllerLifeCycle()
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }

}
