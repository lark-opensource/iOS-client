//
//  AppDelegate.swift
//  LarkTag
//
//  Created by Kongkaikai on 2018/11/9.
//  Copyright © 2018 Kongkaikai. All rights reserved.
//

import Foundation
import UIKit
import LarkActionSheet

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        let root = UINavigationController(rootViewController: ActionSheetViewController())
        window?.rootViewController = root
        window?.makeKeyAndVisible()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        }
        return true
    }
}
