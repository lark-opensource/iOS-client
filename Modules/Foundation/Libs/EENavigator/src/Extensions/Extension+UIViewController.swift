//
//  Extension+UIViewController.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/6.
//

import UIKit
import Foundation

extension UIViewController {

    public var nearestNavigation: UINavigationController? {
        return (self as? UINavigationController) ?? self.navigationController
    }

    /// Pop self and dismiss presented viewControllers
    ///
    /// - Parameters:
    ///   - animated: with animation or not
    ///   - dismissPresented: dismiss presentedViewControllers or not
    ///   - completion: completion handler
    public func popSelf(
        animated: Bool = true,
        dismissPresented: Bool = true,
        completion: (() -> Void)? = nil) {

        guard let navigation = self.navigationController else {
            assertionFailure("NavigationController not found")
            return
        }

        func index(of target: UIViewController, in navigation: UINavigationController) -> Int? {
            var target = target
            while !navigation.viewControllers.contains(target) {
                guard let parent = target.parent else {
                    return nil
                }
                target = parent
            }
            return navigation.viewControllers.firstIndex(of: target)
        }

        func doPop() {
            when(animated: animated, action: {
                guard let idx = index(of: self, in: navigation) else {
                    assertionFailure("Cannot find \(String(describing: self)) in navigation")
                    return nil
                }
                if idx == 0 {
                    assertionFailure("Cannot pop root viewController")
                    return nil
                }

                let frontController = navigation.viewControllers[idx - 1]
                navigation.popToViewController(frontController, animated: animated)
                return navigation
            }, completion: completion)
        }

        if dismissPresented,
            let presentedViewController = navigation.presentedViewController {
            presentedViewController.dismiss(animated: animated, completion: doPop)
        } else {
            doPop()
        }
    }

    // Returns the top most view controller from given view controller's stack.
    public class func topMost(
        of viewController: UIViewController?,
        checkSupport: Bool
    ) -> UIViewController? {

        if checkSupport && !(viewController?.supportNavigator ?? false) {
            return nil
        }

        // presented view controller
        if let presentedViewController = viewController?.presentedViewController {
            return self.topMost(
                of: presentedViewController,
                checkSupport: checkSupport
            ) ?? viewController
        }

        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return self.topMost(
                of: selectedViewController,
                checkSupport: checkSupport
            ) ?? viewController
        }

        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController {
            return self.topMost(
                of: visibleViewController,
                checkSupport: checkSupport
            ) ?? viewController
        }

        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
            pageViewController.viewControllers?.count == 1 {
            return self.topMost(
                of: pageViewController.viewControllers?.first,
                checkSupport: checkSupport
            ) ?? viewController
        }

        // detailvc is the topmost vc
        if let lastVC = (viewController as? UISplitViewController)?.viewControllers.last {
            return self.topMost(
                of: lastVC,
                checkSupport: checkSupport
            ) ?? viewController
        }

        if let lastVC = (viewController as? LKSplitVCDelegate)?.lkTopMost {
            return topMost(
                of: lastVC,
                checkSupport: checkSupport
            ) ?? viewController
        }

        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return self.topMost(
                    of: childViewController,
                    checkSupport: checkSupport
                ) ?? viewController
            }
        }

        return viewController
    }

    // Find the sibling with specified identifier in the same navigationController
    func findSibling(by identifier: String?) -> UIViewController? {
        if identifier == nil {
            return nil
        }

        if self.identifier == identifier {
            return self
        }

        if let navigationController = self.navigationController,
            let controller = navigationController.viewControllers.first(where: { (controller) -> Bool in
                return controller.identifier == identifier
            }) {
                return controller
            }

        return nil
    }

    // Find the ancestor with specified identifier
    func findAncestor(by identifier: String?) -> UIViewController? {
        if identifier == nil {
            return nil
        }

        if self.identifier == identifier {
            return self
        }

        if let controller = self.presenter {
            return controller.findAncestor(by: identifier)
        }

        if let navigationController = self.navigationController {
            if let controller = navigationController.viewControllers.first(where: { (controller) -> Bool in
                return controller.identifier == identifier
            }) {
                return controller
            }
            return navigationController.findAncestor(by: identifier)
        }

        if let tabBarController = self.tabBarController {
            return tabBarController.findAncestor(by: identifier)
        }

        // Ignore some case such as UIPageController and child view controller

        return nil
    }
}

private var uiViewControllerIdentifierKey: Void?
extension UIViewController: Resource {
    public var identifier: String? {
        get {
            return objc_getAssociatedObject(self, &uiViewControllerIdentifierKey) as? String
        }
        set(newValue) {
            objc_setAssociatedObject(self, &uiViewControllerIdentifierKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private var uiViewControllerPresenter: Void?
private var uiViewControllerPresentee: Void?
private var uiViewControllerSupportNavigator: Void?

extension UIViewController {
    public weak var presenter: UIViewController? {
        get {
            return objc_getAssociatedObject(self, &uiViewControllerPresenter) as? UIViewController
        }
        set(newValue) {
            objc_setAssociatedObject(self, &uiViewControllerPresenter, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }

    public weak var presentee: UIViewController? {
        get {
            return objc_getAssociatedObject(self, &uiViewControllerPresentee) as? UIViewController
        }
        set(newValue) {
            objc_setAssociatedObject(self, &uiViewControllerPresentee, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }

    /// support Navigator automatic identification, default is True, when supportNavigator is false，
    /// Navigator.defaultFrom will ignore this viewcontroller and childrens
    public var supportNavigator: Bool {
        get {
            return (objc_getAssociatedObject(self, &uiViewControllerSupportNavigator) as? Bool) ?? true
        }
        set(newValue) {
            objc_setAssociatedObject(self, &uiViewControllerSupportNavigator, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
