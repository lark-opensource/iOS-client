//
//  main.swift
//  KATabRegistryDemo
//
//  Created by Supeng on 2021/11/8.
//

import Foundation
import UIKit
import Photos
import KALogin
import LKNativeAppContainer
import KADemoAssemble

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var appContainer: NativeAppContainer?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        appContainer = NativeAppContainer()

        window = UIWindow()
        window?.rootViewController = getKALoginDemoViewController()
        window?.makeKeyAndVisible()

        return true
    }
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
