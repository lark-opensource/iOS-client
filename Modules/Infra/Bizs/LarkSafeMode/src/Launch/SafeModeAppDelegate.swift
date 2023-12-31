//
//  SafeModeAppDelegate.swift
//  AppContainer
//
//  Created by luyz on 2023/8/31.
//

import Foundation

open class SafeModeAppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    public var window: UIWindow?

    // MARK: launch
    open func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    
        let window = UIWindow()
        self.window = window
        self.window?.makeKeyAndVisible()
        let safemodeVC = PureSafeModeViewController()
        window.rootViewController = safemodeVC

        return true
    }

    public func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        return true
    }

    // MARK: lifecycle
    public func applicationDidBecomeActive(_ application: UIApplication) {

    }

    public func applicationWillResignActive(_ application: UIApplication) {

    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        // send local notification for test

    }

    public func applicationWillEnterForeground(_ application: UIApplication) {

    }

    public func applicationWillTerminate(_ application: UIApplication) {

    }

    public func applicationDidReceiveMemoryWarning(_ application: UIApplication) {

    }

}
