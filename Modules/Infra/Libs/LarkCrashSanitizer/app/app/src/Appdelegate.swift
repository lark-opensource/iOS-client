//
//  AppDelegate.swift
//  LarkCrashSanitizer
//
import Foundation
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        self.window?.rootViewController = UIViewController(nibName: nil, bundle: nil)
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
