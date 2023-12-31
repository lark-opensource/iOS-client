//
//  AppDelegate.swift
//  Calendar
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import LarkBadge

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BadgeManager.setDependancy(with: BadgeImpl.default)
        self.window = UIWindow()
        self.window?.rootViewController = MainVC()
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()
        return true
    }

    struct BadgeImpl: BadgeDependancy {
        var whiteLists: [NodeName]
        var prefixWhiteLists: [NodeName]

        static var `default` = BadgeImpl(whiteLists: white,
                                         prefixWhiteLists: preffix)

        static let preffix = ["chat_id"]
        static let white = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "l",
                            "p", "q", "m", "n",
                            "tab_calendar", "chat_pin", "chat_setting", "root"]
    }
}
