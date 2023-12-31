//
//  AppLifeCycle.swift
//  Docs
//
//  Created by fuweidong on 11/03/2017.
//  Copyright (c) 2017 fuweidong. All rights reserved.
//

import UIKit
import SpaceKit
import TTVideoEngine
import EENavigator
import CoreSpotlight
import MobileCoreServices
import LarkLocalizations
import SKCommon
import SKFoundation


open class AppLifeCycle: UIResponder, UIApplicationDelegate {
    public var window: UIWindow?
    public let lifeCycleManager = LifeCycleManager()
    open func getLifeCycles() -> [LifeCycle] {
        assertionFailure("SubClass must override")
        return []
    }

    open func lifeCycleWillBegin() {
        //Subclass will be noticed when LifeCycle will begin by override
    }

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if let supportLanguage = Bundle.main.infoDictionary?["SUPPORTED_LANGUAGES"] as? [String] {
            LanguageManager.supportLanguages = supportLanguage.map {
                Lang(rawValue: $0)
            }
        }

        if DocsSDK.isBeingTest { return true }
        LKTracing.setupTrace()
        lifeCycleWillBegin()
        self.lifeCycleManager.add(lifeCycles: getLifeCycles())
        return self.lifeCycleManager.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    public func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message)
        //or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        TTVideoEngine.stopOpenGLESActivity()
        self.lifeCycleManager.applicationWillResignActive(application)
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        self.lifeCycleManager.applicationDidEnterBackground(application)
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

        self.lifeCycleManager.applicationWillEnterForeground(application)
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        TTVideoEngine.startOpenGLESActivity()

        self.lifeCycleManager.applicationDidBecomeActive(application)
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

        self.lifeCycleManager.applicationWillTerminate(application)
    }

    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return self.lifeCycleManager.application(app, open: url, options: options)
    }

    public func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return [.portrait, .landscapeLeft, .landscapeRight]
    }

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let prefixDocsId = "lark://doc." //和Lark RD讨论后，属于Docs的前缀标识
        if let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            identifier.hasPrefix(prefixDocsId),
            let url = URL(string: AESUtil.decrypt_AES_ECB(base64String: identifier.replacingOccurrences(of: prefixDocsId, with: ""))) {
            Navigator.shared.push(url, from: UIViewController.docs.rootViewController)
        }
        return true
    }
}

extension UINavigationController {
    open override var shouldAutorotate: Bool {
        if let lastVc = self.viewControllers.last {
            return lastVc.shouldAutorotate
        }
        return super.shouldAutorotate
    }

    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if let lastVc = self.viewControllers.last {
            return lastVc.preferredInterfaceOrientationForPresentation
        }
        return super.preferredInterfaceOrientationForPresentation
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let lastVc = self.viewControllers.last {
            return lastVc.supportedInterfaceOrientations
        }
        return super.supportedInterfaceOrientations
    }
}

extension UITabBarController {
    open override var shouldAutorotate: Bool {
        if let currentVc = self.selectedViewController {
            return currentVc.shouldAutorotate
        }
        return super.shouldAutorotate
    }

    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if let currentVc = self.selectedViewController {
            return currentVc.preferredInterfaceOrientationForPresentation
        }
        return super.preferredInterfaceOrientationForPresentation
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let currentVc = self.selectedViewController {
            return currentVc.supportedInterfaceOrientations
        }
        return super.supportedInterfaceOrientations
    }
}
