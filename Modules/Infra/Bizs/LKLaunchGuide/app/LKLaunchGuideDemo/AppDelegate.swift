//
//  AppDelegate.swift
//  LKLaunchGuideDemo
//
//  Created by Yuri on 2023/8/21.
//

import UIKit
import UniverseDesignTheme
import LarkLocalizations

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let style = UIUserInterfaceStyle.unspecified
        if #available(iOS 13.0, *) {
            UDThemeManager.setUserInterfaceStyle(style)
        } else {
            // Fallback on earlier versions
        }
        LanguageManager.setCurrent(language: .zh_CN, isSystem: false)
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

