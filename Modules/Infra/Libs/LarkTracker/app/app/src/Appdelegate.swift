//
//  AppDelegate.swift
//  Calendar
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import LarkTracker

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        self.window = UIWindow()
        self.window?.rootViewController = UIViewController(nibName: nil, bundle: nil)
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()

        let cParam = TTChannelRequestParam()
        cParam.channel = "Test"
        cParam.appName = "Lark"
        cParam.aId = "1161"
        cParam.installId = "1234567890"
        cParam.deviceId = "1234567890"
        cParam.deviceLoginId = "1234567890"
        cParam.package = Bundle.main.bundleIdentifier
        cParam.osVersion = UIDevice.current.systemVersion
        cParam.notice = "1"

        TouTiaoPushSDK.sendRequest(with: cParam) { (response) in
            print("\(response?.jsonObj ?? "")")
        }

        let param = TTUploadTokenRequestParam()
        param.token = "1111111111111111111"
        param.aId = "1161"
        param.appName = "Lark"
        param.installId = "1234567890"
        param.deviceId = "1234567890"
        param.deviceLoginId = "1234567890"

        TouTiaoPushSDK.sendRequest(with: cParam) { (response) in
            print("\(response?.jsonObj ?? "")")
        }
        return true
    }
}
