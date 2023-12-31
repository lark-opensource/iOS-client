//
//  AppDelegate.swift
//  CameraDemo
//
//  Created by Kongkaikai on 2018/11/9.
//  Copyright © 2018 Kongkaikai. All rights reserved.
//

import Foundation
import UIKit
import LarkCamera

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = TestNavigationController(rootViewController: ViewController())
        window?.makeKeyAndVisible()
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return window?.rootViewController?.children.first?.supportedInterfaceOrientations ?? .allButUpsideDown
    }
}
