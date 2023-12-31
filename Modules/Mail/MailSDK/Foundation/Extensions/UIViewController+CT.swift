//
//  UIViewController+CT.swift
//  DocsSDK
//
//  Created by nine on 2019/1/29.
//

import Foundation

extension UIViewController: MailExtensionCompatible {}

extension MailExtension where BaseType == UIViewController {
    @available(*, deprecated, message: "deprecated! get ui context first")
    class var rootViewController: UIViewController? {
        let currentWindows = UIApplication.shared.windows
        var rootViewController: UIViewController?
        for window in currentWindows.filter({ $0.windowLevel == .normal }) {
            if let windowRootViewController = window.rootViewController {
                rootViewController = windowRootViewController
                break
            }
        }
        return rootViewController
    }
    @available(*, deprecated, message: "deprecated! get ui context first")
    static var businessWindow: UIWindow? {
        return UIApplication.shared.windows.first {
            $0.rootViewController != nil && $0.windowLevel == .normal
        }
    }
    @available(*, deprecated, message: "deprecated! get ui context first")
    static var topMostWindow: UIWindow? {
        return UIApplication.shared.windows.first {
            $0.rootViewController != nil && ($0.windowLevel == .alert + 1)
        }
    }
    @available(*, deprecated, message: "deprecated! get ui context first")
    class var topMost: UIViewController? {
        return self.topMost(of: rootViewController)
    }
    @available(*, deprecated, message: "deprecated! get ui context first")
    class func topMost(of viewController: UIViewController?) -> UIViewController? {
        // presented view controller
        if let presentedViewController = viewController?.presentedViewController {
            return self.topMost(of: presentedViewController)
        }

        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return self.topMost(of: selectedViewController)
        }

        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController {
            return self.topMost(of: visibleViewController)
        }

        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
            pageViewController.viewControllers?.count == 1 {
            return self.topMost(of: pageViewController.viewControllers?.first)
        }

        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return self.topMost(of: childViewController)
            }
        }

        return viewController
    }
}
