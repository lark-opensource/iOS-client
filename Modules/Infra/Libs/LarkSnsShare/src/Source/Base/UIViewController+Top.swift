//
//  UIViewController+Top.swift
//  LarkSnsShare
//
//  Created by shizhengyu on 2020/11/19.
//

import UIKit
import Foundation

extension UIViewController {
    static func topMostController() -> UIViewController? {
        let currentWindows = UIApplication.shared.windows
        var rootViewController: UIViewController?
        for window in currentWindows {
            if let windowRootViewController = window.rootViewController {
                rootViewController = windowRootViewController
                break
            }
        }
        return topMost(of: rootViewController)
    }

    static func topMost(of viewController: UIViewController?) -> UIViewController? {
        // presented view controller
        if let presentedViewController = viewController?.presentedViewController {
            return topMost(of: presentedViewController)
        }

        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return topMost(of: selectedViewController)
        }

        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController {
            return self.topMost(of: visibleViewController)
        }

        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
            pageViewController.viewControllers?.count == 1 {
            return topMost(of: pageViewController.viewControllers?.first)
        }

        // detailvc is the topmost vc
        if let lastVC = (viewController as? UISplitViewController)?.viewControllers.last {
            return topMost(of: lastVC)
        }

        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return topMost(of: childViewController)
            }
        }

        return viewController
    }
}
