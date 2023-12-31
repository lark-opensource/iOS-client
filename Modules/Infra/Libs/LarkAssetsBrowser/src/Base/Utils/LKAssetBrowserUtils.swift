//
//  LKAssetBrowserUtils.swift
//  LKBaseAssetBrowser
//
//  Created by Hayden Wang on 2022/1/25.
//

import Foundation
import UIKit
import EENavigator

enum LKAssetBrowserUtils {

    /// 取最顶层的ViewController
    static var topViewController: UIViewController? {
        return topMost(of: keyWindow?.rootViewController)
    }

    static func topViewControllerFrom(view: UIView) -> UIViewController? {
        if let window = view.window {
            return topMost(of: window.rootViewController)
        }
        return topMost(of: keyWindow?.rootViewController)
    }

    private static var keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windowApplicationScenes
                .filter({$0.activationState == .foregroundActive})
                .compactMap({$0 as? UIWindowScene})
                .first?.windows
                .first(where: { $0.isKeyWindow })
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    private static func topMost(of viewController: UIViewController?) -> UIViewController? {
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
            return topMost(of: visibleViewController)
        }

        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
           pageViewController.viewControllers?.count == 1 {
            return topMost(of: pageViewController.viewControllers?.first)
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
