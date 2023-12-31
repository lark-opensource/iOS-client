//
//  UDCTabBarController.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/8/11.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignIcon

class UDCRootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.ud.N00
        }

        let componentsVC = UDCComponentsList()
        componentsVC.title = "UD Components"
        componentsVC.tabBarItem = UITabBarItem(title: "components",
                                             image: UDIcon.appOutlined,
                                             tag: 0)

        let auroraVC = AuroraDemoController()
        auroraVC.title = "Aurora View"
        auroraVC.tabBarItem = UITabBarItem(title: "aurora",
                                           image: UDIcon.myaiColorful,
                                           tag: 1)

        let playgroundVC = PlaygroundVC()
        playgroundVC.title = "Playground"
        playgroundVC.tabBarItem = UITabBarItem(title: "playground",
                                               image: UDIcon.codingTestOutlined,
                                               tag: 2)
        self.viewControllers = [componentsVC, auroraVC, playgroundVC]
        self.title = "Universe Design"

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Theme", style: .plain, target: self, action: #selector(didTapThemeButton))

        tabBar.tintColor = UDThemeSettingView.Cons.themeTintColor
        if #available(iOS 15.0, *) {
            self.tabBar.scrollEdgeAppearance = self.tabBar.standardAppearance
        }
    }

    @objc private func didTapThemeButton() {
        let themeController = UDThemeSettingController()
        navigationController?.pushViewController(themeController, animated: true)
    }
}
