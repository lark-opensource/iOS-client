//
//  Tabbar.swift
//  MultiUIWindowSolution
//
//  Created by bytedance on 2022/4/21.
//

import Foundation
import UIKit

// swiftlint:disable all
class TabbarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.gray
        feed.tabBarItem = feedItem
        vc.tabBarItem = vcItem
        self.viewControllers = [feed,vc]
        tabBar.tintColor = .systemBlue
        if #available(iOS 15.0, *) {
            self.tabBar.scrollEdgeAppearance = self.tabBar.standardAppearance
        }
    }

    lazy var feed = FeedVC()
    lazy var feedItem = UITabBarItem(title: "消息",
                                     image: UIImage(),
                                     tag: 0)
    lazy var vc = ViewController()
    lazy var vcItem = UITabBarItem(title: "其他",
                                   image: UIImage(),
                                   tag: 1)
}
