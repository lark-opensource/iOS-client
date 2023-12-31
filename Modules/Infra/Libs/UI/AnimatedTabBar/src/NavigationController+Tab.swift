//
//  NavigationController+Tab.swift
//  AnimatedTabBar
//
//  Created by 李晨 on 2020/6/5.
//

import UIKit
import Foundation

public struct NaviTransitionContext {
    weak var vc: UIViewController?
    var needTabbar: Bool?

    public init(vc: UIViewController? = nil) {
        self.vc = vc
        self.needTabbar = vc?.isLkShowTabBar
    }
}

extension UIViewController {
    var selectedByTabbar: Bool {
        /*
         额外判断 vc 是否是 tab.moreNavigationController
         避免错误更新 tabbar 显隐
         */
        guard let tabbar = tabBarController,
            let selected = tabbar.selectedViewController,
            self != tabbar.moreNavigationController else { return false }
        // 已经找到了tabbar那一层，就不往上找了
        if tabbar === self { return false }
        // 自己就是被选中的
        if selected === self {
            return true
        }
        // parent被选中
        if let parent = self.parent, parent.selectedByTabbar {
            return true
        }
        // host被选中
        if let host = self.presentingViewController, host.selectedByTabbar {
            return true
        }
        return false
    }
}

extension UINavigationController {

    func getTopViewControllerOrSelf(viewController: UIViewController?) -> UIViewController? {
        guard let viewController = viewController else {
            return nil
        }
        if let navigationController = viewController as? UINavigationController {
            return navigationController.topViewController
        }
        return viewController
    }
}

public final class AnimatedTabbarConfig {
    /// 自定义是否需要展示 tabbar
    public static var customNeedShowTabbar: ((UIViewController) -> Bool?)?

    /// 自定义是否需要响应 Tabar 布局
    public static var customNeedHandleTabbarLayout: ((UIViewController) -> Bool)?
}

extension UIViewController {
    private struct AssociatedKeys {
        static var isLkShowTabBar = "isLkShowTabBar"
    }

    public var isLkShowTabBar: Bool {
        get {
            if let result = AnimatedTabbarConfig.customNeedShowTabbar?(self) {
                return result
            }

            if let isLkShowTabBar = objc_getAssociatedObject(self, &AssociatedKeys.isLkShowTabBar) as? Bool {
                return isLkShowTabBar
            }
            return false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isLkShowTabBar, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension UINavigationController {
    private struct AssociatedKeys {
        static var targetViewControllers = "targetViewControllers"
    }

    // 获取当前正确的 vc 顺序
    var actualViewControllers: [UIViewController] {
        return self.targetViewControllers ?? self.viewControllers
    }

    /// navi 目标设置的 vc array，为了处理动画中无法获取到正确顺序的问题，动画结束会被清空
    var targetViewControllers: [UIViewController]? {
        get {
            if let targetVCS = objc_getAssociatedObject(self, &AssociatedKeys.targetViewControllers) as? [UIViewController] {
                return targetVCS
            }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.targetViewControllers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
