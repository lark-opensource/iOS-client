//
//  UINavigationController+Swizzled.swift
//  AnimatedTabBar
//
//  Created by 李晨 on 2020/6/5.
//

import UIKit
import Foundation

public final class AnimatedTabbarSwizzleKit: NSObject {

    public static var hadSwizzled: Bool = false

    @objc
    public static func swizzledIfNeeed() {

        /// 只在 pad 版本生效
        if UIDevice.current.userInterfaceIdiom != .pad {
            return
        }

        if !AnimatedTabbarSwizzleKit.hadSwizzled {
            // swiftlint:disable line_length
            let swizzlingSet: [(Selector, Selector)] = [
                (#selector(UINavigationController.pushViewController(_:animated:)), #selector(UINavigationController.at_pushViewController(_:animated:))),
                 (#selector(UINavigationController.popViewController(animated:)), #selector(UINavigationController.at_popViewController(animated:))),
                 (#selector(UINavigationController.popToViewController(_:animated:)), #selector(UINavigationController.at_popToViewController(_:animated:))),
                 (#selector(UINavigationController.popToRootViewController(animated:)), #selector(UINavigationController.at_popToRootViewController(animated:))),
                 (#selector(UINavigationController.setViewControllers(_:animated:)), #selector(UINavigationController.at_setViewControllers(_:animated:))),
                 (#selector(UINavigationController.viewDidAppear(_:)), #selector(UINavigationController.at_viewDidAppear(_:)))
            ]
            // swiftlint:enable line_length

            swizzlingSet.forEach { (value) in
                let originalSelector = value.0
                let swizzledSelector = value.1
                at_swizzling(
                    forClass: UINavigationController.self,
                    originalSelector: originalSelector,
                    swizzledSelector: swizzledSelector
                )
            }
            AnimatedTabbarSwizzleKit.hadSwizzled = true
        }

    }
}

extension UINavigationController {
    // 以下方法中，由于from的splitVC和navigationVC会被释放（setViewController会被同步释放），所以在调用super之前，记录好from的相关信息
    @objc
    func at_pushViewController(_ viewController: UIViewController, animated: Bool) {
        let fromVC = self.topViewController
        /*
         这里调用两次的原因是，
         需要在 push 之前调用，否则 new push vc 的 frame 会有问题，
         同时需要在 push 之后调用，才可以取到 navigation transitionCoordinator 执行动画
         后续可以考虑拆分 更新方法
         */
        notiTabbarPushOrPop(fromVC: fromVC, toVC: viewController)
        self.at_pushViewController(viewController, animated: animated)
        notiTabbarPushOrPop(fromVC: fromVC, toVC: viewController)
    }

    @objc
    func at_popViewController(animated: Bool) -> UIViewController? {
        if let navigationController = self.navigationController, self.viewControllers.count == 1 {
            return navigationController.popViewController(animated: animated)
        } else if self.viewControllers.count == 1 {
            return nil
        }
        let fromVC = self.topViewController
        let result = self.at_popViewController(animated: animated)
        notiTabbarPushOrPop(fromVC: fromVC, toVC: topViewController!)
        return result
    }

    @objc
    func at_popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let fromVC = self.topViewController
        let result = self.at_popToViewController(viewController, animated: animated)
        notiTabbarPushOrPop(fromVC: fromVC, toVC: viewController)
        return result
    }

    @objc
    func at_popToRootViewController(animated: Bool) -> [UIViewController]? {
        let fromVC = self.topViewController
        let result = self.at_popToRootViewController(animated: animated)
        notiTabbarPushOrPop(fromVC: fromVC, toVC: self.topViewController!)
        return result
    }

    @objc
    func at_setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        if animated {
            // 缓存正确的 vc 顺序
            self.targetViewControllers = viewControllers
        }

        if let lastViewController = viewControllers.last {
            let fromVC = self.topViewController
            /*
            这里调用两次的原因是，
            需要在 push 之前调用，否则 new push vc 的 frame 会有问题，
            同时需要在 push 之后调用，才可以取到 navigation transitionCoordinator 执行动画
            后续可以考虑拆分 更新方法
            */
            notiTabbarPushOrPop(fromVC: fromVC, toVC: lastViewController)
            self.at_setViewControllers(viewControllers, animated: animated)
            notiTabbarPushOrPop(fromVC: fromVC, toVC: lastViewController)
        } else {
            self.at_setViewControllers(viewControllers, animated: animated)
        }
        if let transitionCoordinator = self.transitionCoordinator {
            /// 存在转场的时候，转场动画结束 清除 targetViewControllers
            transitionCoordinator.animate(alongsideTransition: nil) { [weak self] (_) in
                self?.targetViewControllers = nil
            }
        } else {
            /// 如果不存在转场 也直接清除 targetViewControllers
            if animated {
                self.targetViewControllers = nil
            }
        }
    }

    @objc
    func at_viewDidAppear(_ animated: Bool) {
        self.at_viewDidAppear(animated)
        refreshTabBarStatus()
    }

    func refreshTabBarStatus() {
        let toViewController = self.getTopViewControllerOrSelf(viewController: self.topViewController)
        guard let toVC = toViewController else {
            return
        }
        self.notiTabbarPushOrPop(fromVC: nil, toVC: toVC)
    }

    func notiTabbarPushOrPop(fromVC: UIViewController?, toVC: UIViewController) {
        guard let tabVC = self.tabBarController as? AnimatedTabBarController else {
            return
        }
        /// 如果 navi 是 splitVC 中 detail Navigtion，则不参与 tabbar 布局
        if let handler = AnimatedTabbarConfig.customNeedHandleTabbarLayout,
           handler(self) {
            return
        }
        tabVC.handleNaviPushOrPop(navi: self, fromVC: fromVC, toVC: toVC)
    }
}

func at_swizzling(
    forClass: AnyClass,
    originalSelector: Selector,
    swizzledSelector: Selector) {

    guard let originalMethod = class_getInstanceMethod(forClass, originalSelector),
        let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) else {
        return
    }
    if class_addMethod(
        forClass,
        originalSelector,
        method_getImplementation(swizzledMethod),
        method_getTypeEncoding(swizzledMethod)
    ) {
        class_replaceMethod(
            forClass,
            swizzledSelector,
            method_getImplementation(originalMethod),
            method_getTypeEncoding(originalMethod)
        )
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
