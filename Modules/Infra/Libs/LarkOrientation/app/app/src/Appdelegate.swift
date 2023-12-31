//
//  AppDelegate.swift
//  Lark
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import LarkOrientation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        self.window?.rootViewController = Navi(rootViewController: ViewController())
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()

        let patch = Orientation.Patch(
            identifier: "VC3",
            description: "VC3",
            options: [
                .supportedInterfaceOrientations(.allButUpsideDown)
            ]) { (vc: UIViewController) -> Bool in
                let className = NSStringFromClass(type(of: vc))
                return className.split(separator: ".").last == "ViewController3"
        }
        Orientation.add(patches: [patch])
        Orientation.swizzledIfNeeed()
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }

}
