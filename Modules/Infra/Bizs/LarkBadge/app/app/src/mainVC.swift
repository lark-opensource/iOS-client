//
//  mainVC.swift
//  BadgeDemo
//
//  Created by 康涛 on 2019/3/27.
//  Copyright © 2019 康涛. All rights reserved.
//

import Foundation
import UIKit
import LarkBadge

class MainVC: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let controller1 = ViewController()
        let controller2 = UIViewController()
        let controller3 = UIViewController()

        setupChildController(controller: controller1, title: "tt", image: "logo", selectedImage: "logo")
        setupChildController(controller: controller2, title: "tt2", image: "logo", selectedImage: "logo")
        setupChildController(controller: controller3, title: "tt3", image: "logo", selectedImage: "logo")
        controller3.tabBarItem.badge.observe(for: Path().tab_calendar)
    }

    func setupChildController(controller: UIViewController, title: String, image: String, selectedImage: String) {
        controller.tabBarItem.title = title
        controller.tabBarItem.image = UIImage(named: image)?.withRenderingMode(.alwaysOriginal)
        controller.tabBarItem.selectedImage = UIImage(named: selectedImage)?.withRenderingMode(.alwaysOriginal)
        self.addChild(UINavigationController(rootViewController: controller))
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.title == "tt2" {
        }
    }

}
