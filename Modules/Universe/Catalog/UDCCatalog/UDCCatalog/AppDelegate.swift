//
//  AppDelegate.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/8/11.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignTheme

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = RootNavigationViewController()
        window?.makeKeyAndVisible()

        if #available(iOS 13.0, *) {
            UDThemeManager.setUserInterfaceStyle(.unspecified)
        }

        #if DEBUG
        let result = Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load();
        print("load \(String(describing: result))")
        #endif
        return true
    }
}
