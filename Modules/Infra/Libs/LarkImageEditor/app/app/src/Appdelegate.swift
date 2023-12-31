//
//  AppDelegate.swift
//  Lark
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import LarkImageEditor

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        let path = Bundle.main.path(forResource: "image", ofType: "jpg")

        let newImage = UIImage(contentsOfFile: path!)!
        let editorVC = ImageEditorFactory.createEditor(with: newImage)
        // let config = CropperConfigure(squareScale: false, style: .custom(370/200))
        // let editorVC = CropperFactory.createCropper(with: newImage, and: config)
        self.window?.rootViewController = editorVC
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) { print("application will terminate") }

    func applicationDidEnterBackground(_ application: UIApplication) { print("enter backgroud") }
}
