//
//  UIViewController+CT.swift
//  SpaceKit
//
//  Created by nine on 2019/1/29.
//

import Foundation
import EENavigator
import LarkTraitCollection
import LarkSplitViewController
import LarkUIKit
import SKFoundation
import UIKit

extension UIViewController: DocsExtensionCompatible {}

extension DocsExtension where BaseType == UIViewController {

    public class func topLast(of viewController: UIViewController?) -> UIViewController? {
        guard let viewController = viewController else { return nil }
        if let presenter = viewController.presenter {
            return presenter
        }
        if let nav = viewController.navigationController,
            nav.viewControllers.count > 1,
            let index = nav.viewControllers.firstIndex(of: viewController) {
            return nav.viewControllers[index - 1]
        }
        return nil
    }

    public class func topMost(of viewController: UIViewController?) -> UIViewController? {

        if let presentedViewController = viewController?.presentedViewController {
            return topMost(of: presentedViewController)
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

        // LKSplitViewController
        if let svc = viewController as? SplitViewController {
          return self.topMost(of: svc.topMost)
        }
        if let svc = viewController as? SplitViewController {
            return self.topMost(of: svc.topMost)
        }

        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return self.topMost(of: childViewController)
            }
        }

        return viewController
    }

    
    /// 这个方法在找顶层控制器，遇到 presentedVC 时会过滤掉一些情况。当 presentedVC 的 presentingVC 不是传入的控制器或者是传入的控制器的导航栏控制器。
    public class func topMostWhichFiltedUnmatchVC(of viewController: UIViewController?) -> UIViewController? {
        
        if let presentedViewController = viewController?.presentedViewController {
            if presentedViewController.presentingViewController === viewController?.navigationController ||
                presentedViewController.presentingViewController === viewController {
                return self.topMost(of: presentedViewController)
            } else {
                return unwrapContainerVC(of: viewController)
            }
        }

        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
          let selectedViewController = tabBarController.selectedViewController {
          return self.topMost(of: selectedViewController)
        }

        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
          let visibleViewController = navigationController.topViewController {
          return self.topMost(of: visibleViewController)
        }

        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
          pageViewController.viewControllers?.count == 1 {
          return self.topMost(of: pageViewController.viewControllers?.first)
        }

        // LKSplitViewController
        if let svc = viewController as? SplitViewController {
          return self.topMost(of: svc.topMost)
        }
        if let svc = viewController as? SplitViewController {
          return self.topMost(of: svc.topMost)
        }

        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
          if let childViewController = subview.next as? UIViewController {
            return self.topMost(of: childViewController)
          }
        }

        return viewController
      }

    /// 如果 controller 是个容器控制器那就给解析出来。
    private class func unwrapContainerVC(of viewController: UIViewController?) -> UIViewController? {
        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return self.unwrapContainerVC(of: selectedViewController)
        }
        
        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
           let topViewController = navigationController.topViewController {
            return self.unwrapContainerVC(of: topViewController)
        }
        
        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
           pageViewController.viewControllers?.count == 1 {
            return self.unwrapContainerVC(of: pageViewController.viewControllers?.first)
        }
        
        // LKSplitViewController
        if let svc = viewController as? SplitViewController {
          return self.topMost(of: svc.topMost)
        }
        if let svc = viewController as? SplitViewController {
            return self.unwrapContainerVC(of: svc.topMost)
        }
        
        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return self.unwrapContainerVC(of: childViewController)
            }
        }
        return viewController
    }
}

extension UIViewController {
    public var lkSplitViewController: SplitViewController? {
        if let target = self as? SplitViewController {
            return target
        }
        return parent?.lkSplitViewController
    }
    
    public func tryBecomeFirstResponderIfNeed() -> Bool {
        let isFirstResponder = self.isFirstResponder
        if !isFirstResponder {
            self.becomeFirstResponder()
            return true
        }
        return false
    }
}


extension UIViewController {
    public func isMyWindowRegularSize() -> Bool {
        return view.isMyWindowRegularSize()
    }
    public func isMyWindowCompactSize() -> Bool {
        return view.isMyWindowCompactSize()
    }
    public var isMyWindowRegularSizeInPad: Bool {
        return SKDisplay.pad && isMyWindowRegularSize()
    }
}

extension UIViewController {
    
    public func addContentVC(_ child: UIViewController, frame: CGRect? = nil) {
        addChild(child)
        view.addSubview(child.view)
        if let frame = frame {
            child.view.frame = frame
        } else {
            child.view.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        child.didMove(toParent: self)
    }
    
    public func removeContentVC(_ child: UIViewController) {
        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
        child.didMove(toParent: nil)
    }
}

extension UIView {
    public func isMyWindowRegularSize() -> Bool {
        return isMyWindowUISizeClass(.regular)
    }
    public func isMyWindowCompactSize() -> Bool {
        return isMyWindowUISizeClass(.compact)
    }
    public func isMyWindowUISizeClass(_ sizeClass: UIUserInterfaceSizeClass) -> Bool {
        let traitCollection = window?.traitCollection
        return traitCollection?.horizontalSizeClass == sizeClass
    }
}
