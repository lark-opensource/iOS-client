//
//  AppDelegate.swift
//  Calendar
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let rootViewController = MainController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        if #available(iOS 13.0, *) {
            self.window?.overrideUserInterfaceStyle = .unspecified
        }
        self.window?.rootViewController = UINavigationController(rootViewController: rootViewController)
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()

        return true
    }

//    func applicationWillEnterForeground(_ application: UIApplication) {
//        rootViewController.tableVC.tableView.reloadData()
//    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }
}

class MainController: UIViewController {
    var btn: UIButton!
    let tableVC = TableViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        btn = UIButton(frame: CGRect(x: 100, y: 200, width: 100, height: 50))
        btn.setTitle("PUSH", for: .normal)
        btn.backgroundColor = UIColor.black
        btn.addTarget(self, action: #selector(push), for: .touchUpInside)

        view.addSubview(btn)
    }

    @objc
    func push() {
        self.navigationController?.pushViewController(tableVC, animated: true)
    }
}
