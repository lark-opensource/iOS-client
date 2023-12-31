//
//  AppDelegate.swift
//  Lark
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import LarkFileSystem

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        self.window?.rootViewController = UIViewController(nibName: nil, bundle: nil)
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()
        LarkDiskMonitor(monitorConfigs: MonitorConfig.defaultConfig).run()
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }

}

extension MonitorConfig {
    static let defaultConfig: [MonitorConfig] = [
        MonitorConfig(configName: "log_file", maxLevel: 5, conditions: [
            Condition(classification: "true", regex: "([^/]*/?){0,3}", type: .all)
        ], operations: ["true":"log_file"]),
        MonitorConfig(configName: "integrated_monitor", maxLevel: 5, conditions: [
            Condition(classification: "true", regex: "Documents/sdk_storage", type: .all),
            Condition(classification: "true", regex: "Library/Caches/(com.bytedance.feishu|io.fabric.sdk.ios.data|com.crashlytics.data)", type: .all),
            Condition(classification: "true", regex: "Library/(WebKit|Preferences|Heimdallr|OfflineResource|Cookies|SuiteLogin|SplashBoard|WebCache)", type: .all),
            Condition(classification: "true", regex: "Documents/LarkUser_\\d*(?!/)", type: .all),
            Condition(classification: "false", regex: "Documents/[^/]*", type: .all),
            Condition(classification: "false", regex: "Library/[^/]*", type: .all),
            Condition(classification: "false", regex: "Library/Caches/[^/]*", type: .all),
        ], operations: ["true":"event", "false,subtract,true":"exception"]),
        MonitorConfig(configName: "detailed_monitor", maxLevel: 5, conditions: [
            Condition(classification: "true", regex: "Documents/sdk_storage/[^/]*", type: .all)
        ], operations: ["true":"log_file"])
    ]

}
