//
//  UIViewController+Extension.swift
//  AnimatedTabBar
//
//  Created by Meng on 2019/10/15.
//

import Foundation
import UIKit

extension UIViewController {
    /// If the view controller has a AnimatedTabBarController as its ancestor, return it. Returns nil otherwise.
    public var animatedTabBarController: AnimatedTabBarController? {
        if let tabbarVC = self as? AnimatedTabBarController {
            return tabbarVC
        }
        if let tabbarVC = self.parent as? AnimatedTabBarController {
            return tabbarVC
        }
        if let tabbarVC = self.tabBarController as? AnimatedTabBarController {
            return tabbarVC
        }
        if let navi = self as? UINavigationController,
            let tabbarVC = navi.viewControllers.first as? AnimatedTabBarController {
            return tabbarVC
        }
        // 先检查containers是否含有tabbarVC
        if let tabbarVC = checkContainers.compactMap({ $0?.animatedTabBarController }).first {
            return tabbarVC
        }
        // 找不到 兜底从上找
        if let window = UIApplication.shared.windows.first(where: { (window) -> Bool in
            if let root = window.rootViewController as? UINavigationController,
               root.viewControllers.first is AnimatedTabBarController {
                return true
            }
            return false
        }),
        let navi = window.rootViewController as? UINavigationController,
        let tab = navi.viewControllers.first as? AnimatedTabBarController {
            return tab
        }

        return nil
    }

    private var checkContainers: [UIViewController?] {
        return [parent, presentingViewController, navigationController, splitViewController]
    }
}
