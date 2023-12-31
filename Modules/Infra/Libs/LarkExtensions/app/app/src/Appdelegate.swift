//
//  AppDelegate.swift
//  LarkCrashSanitizer
//
import Foundation
import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)

        if #available(iOS 14.0, *) {
            self.window?.rootViewController = UIHostingController(rootView: ContentView())
        } else {
            // Fallback on earlier versions
            self.window?.rootViewController = UIViewController()
        }
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()
        return true
    }
    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }
    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }
}
