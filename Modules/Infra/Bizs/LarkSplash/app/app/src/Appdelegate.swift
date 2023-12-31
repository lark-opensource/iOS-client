//
//  AppDelegate.swift
//  Lark
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import LarkSplash
import EENavigator

// swiftlint:disable line_length

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        self.window?.rootViewController = UIViewController(nibName: nil, bundle: nil)
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()

        SplashManager.shareInstance.register(delegate: self)
        SplashManager.shareInstance.displaySplash(isHotLaunch: false, fromIdle: false)

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        SplashManager.shareInstance.displaySplash(isHotLaunch: true, fromIdle: false)
    }
}

extension AppDelegate: SplashDelegate {
    func track(withTag tag: String, label: String, extra: [AnyHashable: Any]) {
        print(label)
    }

    func splashAction(withCondition condition: [AnyHashable: Any]) { print(condition) }

    func request(withUrl urlString: String, responseBlock: @escaping (Data?, Error?, NSInteger) -> Void) {
        if urlString.hasPrefix("https://") {
            URLSession.shared.dataTask(with: .init(url: URL(string: urlString)!), completionHandler: {(data, response, error) in
                if  error != nil {
                    responseBlock(data, error, (response as? HTTPURLResponse)?.statusCode ?? 400)
                } else {
                    responseBlock(data, nil, (response as? HTTPURLResponse)?.statusCode ?? 200)
                }
            }).resume()
        } else if urlString.hasPrefix("api/ad/splash//v15/") {
            let data = """
            {"data":{"splash_interval":1,"leave_interval":1,"show_limit":0,"splash_load_interval":1,"server_time":1633689823,"splash":[{"id":7007727487346393108,"display_density":"1080x1920","type":"web","log_extra":"splash_api:lark_api","open_url":"","web_url":"","web_title":"","skip_btn":1,"click_btn":0,"image_mode":0,"banner_mode":0,"repeat":0,"display_after":0,"display_time_ms":6000,"max_display_time_ms":90000,"expire_seconds":1142176,"splash_type":2,"splash_show_type":0,"splash_load_type":3,"predownload":1,"predownload_text":"","intercept_flag":2,"action":"","video_info":{"video_id":"6907200989728604179#1633689256","video_url_list":["aHR0cHM6Ly9pbnRlcm5hbC1hcGktbGFyay1maWxlLmZlaXNodS1ib2UuY24vc3RhdGljLXJlc291cmNlL3YxL2IyN2ZlOTFmLTUxNzgtNDdjZi04MTljLTNkOWNlZWJkOWUyan4="],"video_density":"1080x1920","voice_switch":false,"secret_key":"","video_duration_ms":11890},"label_info":{"position":0,"text":"","text_color":"#FFFFFFFF","background_color":"#0000004C"},"skip_info":{"height_extra_size":20,"width_extra_size":40,"text_color":"#FFFFFF99","background_color":"#FFFFFF26","text":"跳过","show_skip_seconds":0,"countdown_enable":1,"countdown_unit":"s"},"sound_control":0}]}}
            """.data(using: String.Encoding.utf8)
            responseBlock(data, nil, 200)
        }
    }

    func splashViewWillAppear(withSplashID id: Int64) { SplashManager.shareInstance.window.isHidden = false }

    func splashDidDisapper() { SplashManager.shareInstance.window.isHidden = true }

    func splashDebugLog(_ log: String) { print(log) }
}
