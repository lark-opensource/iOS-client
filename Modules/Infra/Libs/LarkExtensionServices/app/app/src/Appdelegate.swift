//
//  AppDelegate.swift
//  Lark
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import LarkExtensionServices

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        self.window?.rootViewController = UIViewController(nibName: nil, bundle: nil)
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()
        let logger = LogFactory.createLogger(label: "test")
        logger.info("test session: XN0YXJ0-38881111-85d0-4fb1-2222-9557e2e91f7g-WVuZA")
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }

}
