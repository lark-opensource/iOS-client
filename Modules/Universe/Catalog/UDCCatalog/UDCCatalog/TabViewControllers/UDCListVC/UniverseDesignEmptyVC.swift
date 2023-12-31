//
//  UniverseDesignEmptyVC.swift
//  UDCCatalog
//
//  Created by 王元洵 on 2020/9/24.
//  Copyright © 2020 王元洵. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignEmpty
import UniverseDesignButton
import UniverseDesignIcon

class UniverseDesignEmptyVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "UniverseDesignEmpty"
        self.view.backgroundColor = UIColor.ud.bgBody

        let tabBarController = UITabBarController()

        self.addChild(tabBarController)
        self.view.addSubview(tabBarController.view)

        let initialView = setEmpty(type: .imSetup)
        let initialViewController = UIViewController()
        initialViewController.view.addSubview(initialView)
        initialView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview()
        }

        let positiveView = setEmpty(type: .pin)
        let positiveViewController = UIViewController()
        positiveViewController.view.addSubview(positiveView)
        positiveView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview()
        }

        let negtiveView = setEmpty(type: .noFile)
        let negtiveViewController = UIViewController()
        negtiveViewController.view.addSubview(negtiveView)
        negtiveView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview()
        }

        let viewControllerArray = [initialViewController, positiveViewController, negtiveViewController]

        tabBarController.viewControllers = viewControllerArray

        let titleArray = ["初始化", "正反馈", "负反馈"]

        for i in 0 ..< 3 {

            viewControllerArray[i].tabBarItem = UITabBarItem(title: titleArray[i],
                                                             image: UDIcon.activityFilled
                                                                .withRenderingMode(.alwaysOriginal),
                                                             selectedImage: UDIcon.activityFilled
                                                                .withRenderingMode(.alwaysOriginal))
        }
    }

    private func popAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let btnOK = UIAlertAction(title: "OK!", style: .default, handler: nil)
        alert.addAction(btnOK)
        self.present(alert, animated: true, completion: nil)
    }

    private func setEmpty(type: UDEmptyType) -> UDEmpty {
        var handler: (() -> Void)?
        var range: NSRange?
        var description = "购买iPhone请访问苹果官网购买iPhone请访问苹果官网购买iPhone请访问苹果官网"
        if case .noFile = type {
            range = .init(location: 11, length: 4)
            handler = { self.popAlert(title: "你点击了可操作文本！", message: "没事了，再见！") }
            description = "购买iPhone请访问苹果官网"
        }
        let richDescription = NSMutableAttributedString(string: description)
        richDescription.addAttribute(.font, value: UIFont.systemFont(ofSize: 30), range: .init(location: 2, length: 6))

        let empty = UDEmpty(config: .init(title: .init(titleText: "空状态Empty"),
                                          description: .init(descriptionText: richDescription,
                                                             operableRange: range),
                                          type: type,
                                          labelHandler: handler,
                                          primaryButtonConfig: ("主要操作", { _ in
                                            self.popAlert(title: "你点击了主要按钮！", message: "没事了，再见！")
                                          }),
                                          secondaryButtonConfig: ("次要操作次要操作次要操作", { _ in
                                            self.popAlert(title: "你点击了次要按钮！", message: "没事了，再见！")
                                          })))

        return empty
    }
}
