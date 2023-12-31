//
//  AppDelegate.swift
//  Lark
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import LarkAddressBookSelector

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let testVC = TestViewController()
    var rootNavi: UINavigationController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        rootNavi = UINavigationController(rootViewController: testVC)
        self.window?.rootViewController = rootNavi
        self.window?.makeKeyAndVisible()
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }

}
