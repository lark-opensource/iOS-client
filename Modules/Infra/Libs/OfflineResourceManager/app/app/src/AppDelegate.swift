//
//  AppDelegate.swift
//  Calendar
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import OfflineResourceManager

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        self.window?.rootViewController = UIViewController(nibName: nil, bundle: nil)
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()
        setupOfflineResource()
        return true
    }

    func setupOfflineResource() {
        let config = OfflineResourceConfig(appId: "1161",
                                           appVersion: "3.14.0",
                                           deviceId: "",
                                           domain: "",
                                           cacheRootDirectory: NSHomeDirectory() + "/Documents/OfflineResource")
        OfflineResourceManager.setConfig(config)

        let bizId = "larkdynamicdemo"
        OfflineResourceManager.registerBiz(configs: [
            OfflineResourceBizConfig(bizID: bizId,
                                     bizKey: "9ab2fc4c5a599d926bd7bcfb6c6c38d3",
                                     subBizKey: "larkdynamicdemo")
        ])

        OfflineResourceManager.fetchResource(byId: bizId) { (isSuccess, status) in
            print("isSuccess \(isSuccess) status: \(status) thread \(Thread.current)")

            print("status: \(OfflineResourceManager.getResourceStatus(byId: bizId))")

            print("root: \(OfflineResourceManager.rootDir(forId: bizId) ?? "")")

            print("index exist \(OfflineResourceManager.fileExists(id: bizId, path: "index.html"))")

            print("index data length \(OfflineResourceManager.data(forId: bizId, path: "index.html")?.count ?? 0)")
        }

        OfflineResourceManager.setDeviceId("123456789")
        OfflineResourceManager.setDomain("gecko.snssdk.com")
    }
}
