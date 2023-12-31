//
//  UIViewController+Top.swift
//  LarkNavigation
//
//  Created by Meng on 2019/10/14.
//

import UIKit
import Foundation
import LarkUIKit
import AnimatedTabBar

extension UIViewController {
    private var systemSplitMaster: TabRootViewController? {
        let splitFirst = (self as? UISplitViewController)?.viewControllers.first ?? self
        let masterNavigationFirst = (splitFirst as? UINavigationController)?.viewControllers.first ?? splitFirst
        return masterNavigationFirst as? TabRootViewController
    }

    private var customSplitMaster: TabRootViewController? {
        let splitFirst = larkSplitViewController?.sideNavigationController ?? self
        let masterNavigationFirst = (splitFirst as? UINavigationController)?.viewControllers.first ?? splitFirst
        return masterNavigationFirst as? TabRootViewController
    }

    public var tabRootViewController: TabRootViewController? {
        let defaultTabRoot = self as? TabRootViewController
        let defaultNavigationRoot = (self as? UINavigationController)?.viewControllers.first as? TabRootViewController
        // UITabbarController调用setViewControllers时，当多于6个VC时，系统会默认把多余的VC加入到moreNavigation里，
        // moreNavigation自身就是一个UINavigationController，不能再push一个节点是UINavigationController的导航栈
        // 此时需要wrapper一层；此处兜底解决业务方tabVC返回一个UINavigationController的情况
        let wrapperTabRoot = (self.children.first as? UINavigationController)?.viewControllers.first as? TabRootViewController

        let defaultRoot = defaultTabRoot ?? defaultNavigationRoot
        let splitRoot = customSplitMaster ?? systemSplitMaster
        return (defaultRoot ?? wrapperTabRoot) ?? splitRoot
    }

    var tabEventVC: TabBarEventViewController? {
        return tabRootViewController as? TabBarEventViewController
    }

    public var isInMainTab: Bool {
        return self.animatedTabBarController != nil
    }
}
