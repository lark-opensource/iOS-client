//
//  Utils+VC.swift
//  Todo
//
//  Created by wangwanxin on 2021/9/29.
//

import LarkNavigation
import LarkSplitViewController
import LarkUIKit

extension Utils {
    enum ViewController { }
}

extension Utils.ViewController {

    static func getHomeV3() -> V3HomeViewController? {
        if let tabController = RootNavigationController.shared.viewControllers.first as? UITabBarController {
            if let vc = tabController.selectedViewController as? V3HomeViewController {
                return vc
            }
            if let splitVC = tabController.selectedViewController as? SplitViewController,
               let naviVC = splitVC.sideNavigationController as? LkNavigationController,
               let vc = naviVC.viewControllers.first(where: { $0 is V3HomeViewController }) as? V3HomeViewController {
                return vc
            }
        }
        return nil
    }
}
