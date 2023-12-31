//
//  AppDelegate.swift
//  Calendar
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import LarkAlertController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITextFieldDelegate {
    var window: UIWindow?
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        self.window?.rootViewController = UIViewController(nibName: nil, bundle: nil)
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()

        let alert = showAlertWithContainer()

        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }

    func showAlertWithContainer() -> LarkAlertController {
        let alert = LarkAlertController()
        alert.setTitle(text: "标题", alignment: .left)
        let view = UIView()
        view.backgroundColor = .orange
        view.snp.makeConstraints { (make) in
            make.height.equalTo(100)
            make.width.equalTo(200)
        }
        let textField = UITextField()
        view.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        textField.delegate = self
        alert.setContent(view: view)
        alert.addSecondaryButton(text: "次要操作")
        alert.addPrimaryButton(text: "引导操作")
        return alert
    }

    func showAlertWithContent() -> LarkAlertController {
        let alert = LarkAlertController()
        alert.setTitle(text: "标题", alignment: .left)
        alert.setContent(text: "测试文字测试文字测试......")
        alert.addSecondaryButton(text: "次要操作")
        alert.addPrimaryButton(text: "引导操作")
        return alert
    }

    func showAlertWithoutContent() -> LarkAlertController {
        let alert = LarkAlertController()
        alert.setTitle(text: "内容", alignment: .center)
        alert.addSecondaryButton(text: "次要操作")
        alert.addPrimaryButton(text: "引导操作")
        return alert
    }

    func showAlertWithoutTitle() -> LarkAlertController {
        let alert = LarkAlertController()
        alert.setContent(text: "标题", alignment: .center)
        alert.addSecondaryButton(text: "次要操作")
        alert.addPrimaryButton(text: "引导操作")
        return alert
    }

    func showAlertWithTextView() -> LarkAlertController {
        let alert = LarkAlertController()
        alert.setTitle(text: "标题", alignment: .center)
        let text = UITextField()
        text.delegate = self
        text.snp.makeConstraints { (make) in
            make.width.equalTo(200)
            make.height.equalTo(500)
        }
        alert.setContent(view: text)
        alert.addSecondaryButton(text: "次要操作")
        alert.addPrimaryButton(text: "引导操作")
        return alert
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if string == "\n" {
            textField.resignFirstResponder()
            return false
        }
        return true
    }
}
