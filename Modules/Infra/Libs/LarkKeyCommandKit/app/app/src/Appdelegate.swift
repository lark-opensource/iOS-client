//
//  AppDelegate.swift
//  Lark
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import LarkKeyCommandKit
import LarkKeyboardKit
import LKLoadable

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        LKLoadableManager.run(LoadableState(rawValue: 0))
        LKLoadableManager.run(LoadableState(rawValue: 1))
        LKLoadableManager.run(LoadableState(rawValue: 2))

        self.window = UIWindow()
        self.window?.rootViewController = rootViewController()
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()
        KeyboardKit.shared.start()
        return true
    }
}
