//
//  AppDelegate.swift
//  Calendar
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import QRCode
import SnapKit
import RxCocoa
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()

        let qrCodeVC = QRCodeViewController(type: .qrCode)

        let vc = UIViewController()
        let button = UIButton()
        _ = button.rx.tap.subscribe(onNext: { (_) in
            vc.navigationController?.pushViewController(qrCodeVC, animated: true)
        })

        vc.view.addSubview(button)
        button.backgroundColor = .red
        button.setTitle("跳转到扫码", for: .normal)
        button.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        let navi = UINavigationController(rootViewController: vc)

        self.window?.rootViewController = navi
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
