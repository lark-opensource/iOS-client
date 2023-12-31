//
//  Orientation+UINavigationController.swift
//  LarkOrientationDev
//
//  Created by 李晨 on 2020/2/27.
//

import UIKit
import Foundation

extension UINavigationController {

    static var orientationNaviSwizzingFunc: [(AnyClass, Selector, Selector)] {
        return [
            (UINavigationController.self,
             #selector(UINavigationController.pushViewController(_:animated:)),
             #selector(UINavigationController.lo_pushViewController(_:animated:))),
            (UINavigationController.self,
             #selector(UINavigationController.setViewControllers(_:animated:)),
             #selector(UINavigationController.lo_setViewControllers(_:animated:))),
            (UINavigationController.self,
             #selector(UINavigationController.popToRootViewController(animated:)),
             #selector(UINavigationController.lo_popToRootViewController(animated:))),
            (UINavigationController.self,
             #selector(UINavigationController.popToViewController(_:animated:)),
             #selector(UINavigationController.lo_popToViewController(_:animated:))),
            (UINavigationController.self,
             #selector(UINavigationController.popViewController(animated:)),
             #selector(UINavigationController.lo_popViewController(animated:))),
        ]
    }

    @objc
    func lo_pushViewController(_ viewController: UIViewController, animated: Bool) {
        self.lo_pushViewController(viewController, animated: animated)
        Orientation.updateOrientationIfNeeded(vc: viewController)
    }

    @objc
    func lo_setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        self.lo_setViewControllers(viewControllers, animated: animated)
        if let last = viewControllers.last {
            Orientation.updateOrientationIfNeeded(vc: last)
        }
    }

    @objc
    func lo_popToRootViewController(animated: Bool) -> [UIViewController]? {
        let currentVC = self.topViewController
        let vcCount = self.viewControllers.count
        let toVC = vcCount > 1 ? self.viewControllers[vcCount - 2] : nil

        return fixOrientationWhenPop(
            currentVC: currentVC,
            toVC: toVC) { () -> [UIViewController]? in
            return lo_popToRootViewController(animated: animated)
        }
    }

    @objc
    func lo_popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let currentVC = self.topViewController
        let toVC = self.viewControllers.contains(viewController) ? viewController : nil
        return fixOrientationWhenPop(
            currentVC: currentVC,
            toVC: toVC) { () -> [UIViewController]? in
            return lo_popToViewController(viewController, animated: animated)
        }
    }

    @objc
    func lo_popViewController(animated: Bool) -> UIViewController? {
        let currentVC = self.topViewController
        let vcCount = self.viewControllers.count
        let toVC = vcCount > 1 ? self.viewControllers[vcCount - 2] : nil

        return fixOrientationWhenPop(
            currentVC: currentVC,
            toVC: toVC) { () -> UIViewController? in
            return lo_popViewController(animated: animated)
        }
    }

    private func checkInPopGestureHande() -> Bool {
        if let interactivePopGestureRecognizer = self.interactivePopGestureRecognizer,
            [UIGestureRecognizer.State.began, UIGestureRecognizer.State.changed].contains(interactivePopGestureRecognizer.state) {
            return true
        }
        return false
    }

    func fixOrientationWhenPop<T>(
        currentVC: UIViewController?,
        toVC: UIViewController?,
        action: () -> T) -> T {
        /// 判断是否处于拖拽手势中
        if checkInPopGestureHande() {
            return action()
        }

        guard let toVC = toVC else {
            return action()
        }
        /// 当前设备方向
        let current = UIDevice.current.orientation
        /// 新页面支持的方向
        let toOrientations = toVC.supportedInterfaceOrientations

        /// 判断方向是否兼容
        guard !toOrientations.contains(current.toInterfaceOrientation) else {
            return action()
        }

        /// 获取任意支持的方向
        let toOrientation = toOrientations.anyOrientation

        let currentOrientations = currentVC?.supportedInterfaceOrientations ?? current.toInterfaceOrientation

        /// 判断当前页面是否支持 toOrientation, 如果支持的话先转屏
        if currentOrientations.contains(toOrientation.toInterfaceOrientation) {
            UIDevice.current.setValue(toOrientation.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
            return action()
        }

        let value = action()
        UIDevice.current.setValue(toOrientation.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        return value
    }

}


