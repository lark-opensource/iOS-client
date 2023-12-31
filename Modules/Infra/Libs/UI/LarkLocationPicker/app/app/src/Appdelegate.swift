//
//  AppDelegate.swift
//  Calendar
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import AMapFoundationKit
import LarkActionSheet
import LarkLocationPicker
import LarkUIKit
import SnapKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow.init()
        /* iPhone */
        let detailVC = BaseUIViewController(nibName: nil, bundle: nil)
        let root = LkNavigationController(rootViewController: detailVC)
        /* iPad */
//        let masterVC = BaseUIViewController(nibName: nil, bundle: nil)
//        let masterNVC = LkNavigationController(rootViewController: masterVC)
//        masterVC.view.backgroundColor = UIColor.lk.I300
//        let detailVC = BaseUIViewController(nibName: nil, bundle: nil)
//        let detailNVC = LkNavigationController(rootViewController: detailVC)
//        let root = UISplitViewController(nibName: nil, bundle: nil)
//        root.viewControllers = [masterNVC, detailNVC]
//        root.preferredDisplayMode = .allVisible
        /* General */
        self.window?.rootViewController = root
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let picker = LocationPickerView(location: "", allowCustomLocation: false, defaultAnnotation: true, useWGS84: false)
            picker.locationServiceDisabledCallBack = {
                let alert = CustomAlertViewController(
                    title: "Unable to get your location data.",
                    body: "Please enable location service in \"Settings\" -> \"Privacy\" -> \"Location Service\" and allow Lark to get your location data",
                    leftBtnText: "OK",
                    rightBtnText: "Setting"
                )
                alert.leftBtnCallBack = {
                    detailVC.dismiss(animated: true, completion: nil)
                }
                alert.rightBtnCallBack = {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }
                detailVC.present(alert, animated: true, completion: nil)
            }
            detailVC.view.addSubview(picker)
            picker.snp.makeConstraints({ (make) in
                make.edges.equalToSuperview()
            })
        }
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }

}
