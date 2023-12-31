//
//  AppDelegate.swift
//  LarkTag
//
//  Created by Kongkaikai on 2018/11/9.
//  Copyright © 2018 Kongkaikai. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        if #available(iOS 13.0.0, *) {
            window?.rootViewController = UIHostingController(rootView: TypeButtonPreview())
        } else {
            window?.rootViewController = TypeButtonViewController()
        }
        window?.makeKeyAndVisible()
        return true
    }
}
