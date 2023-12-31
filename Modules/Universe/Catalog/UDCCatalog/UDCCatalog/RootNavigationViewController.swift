//
//  RootNavigationViewController.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/8/11.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit

// swiftlint:disable all
class RootNavigationViewController: UINavigationController {
    ///whether doing transition animation（是否正在做转场动画中）
    private var isAnimating = false
    private var isSwipeGestureRecognizerEnabled: Bool {
        return self.topViewController?.naviPopGestureRecognizerEnabled ?? false
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.viewControllers = [UDCRootTabBarController()]
        self.interactivePopGestureRecognizer?.isEnabled = self.isSwipeGestureRecognizerEnabled
        self.interactivePopGestureRecognizer?.delegate = self

        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
            navigationBar.tintColor = UDThemeSettingView.Cons.themeTintColor
        } else {
            view.backgroundColor = UIColor.ud.N00
        }
    }
}

extension RootNavigationViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        //If you are doing transition animation, do not respond to swipe gestures to avoid freezing screen
        //如果正在做转场动画，不响应swipe手势，避免出现冻屏现象
        //https://bytedance.feishu.cn/docs/doccnYdREWgMt2ZvKamILKup4Wc#
        if gestureRecognizer is UIScreenEdgePanGestureRecognizer, self.isAnimating {
            return false
        }
        return self.isSwipeGestureRecognizerEnabled
    }
}

extension RootNavigationViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                                     willShow viewController: UIViewController, animated: Bool) {
        if animated {
            self.isAnimating = true
            //Use the timeout strategy to determine whether the transition animation is over by the timer
            //使用timeout兜底策略，通过timer来判断转场动画是否结束
            let duration = viewController.transitionCoordinator?.transitionDuration ?? 0
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.isAnimating = false
            }
        }
    }

    public func navigationController(_ navigationController: UINavigationController,
                                     didShow viewController: UIViewController, animated: Bool) {
        //When there is only one VC in the current viewControllers, you need to turn off theinteractivePopGestureRecognizer gesture. Otherwise, there will be a frozen screen
        //当前viewControllers只存在一个vc的时候，需要将interactivePopGestureRecognizer手势关闭，否则会出现冻屏的情况
        //https://bytedance.feishu.cn/docs/doccnYdREWgMt2ZvKamILKup4Wc#
        if self.viewControllers.count <= 1 {
            self.interactivePopGestureRecognizer?.isEnabled = false
        } else {
            self.interactivePopGestureRecognizer?.isEnabled = self.isSwipeGestureRecognizerEnabled
        }
    }
}

//Add an associated object to viewController to control whether vc supports side slip
//给viewController添加一个关联对象，用来控制vc是否支持侧滑
private var UIViewController_naviPopGestureRecognizerEnabled = "UIViewController.navi.popGestureRecognizer.enabled"

extension UIViewController {
    public var naviPopGestureRecognizerEnabled: Bool {
        get {
            return objc_getAssociatedObject(self, &UIViewController_naviPopGestureRecognizerEnabled) as? Bool ?? true
        }
        set {
            objc_setAssociatedObject(self, &UIViewController_naviPopGestureRecognizerEnabled, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
// swiftlint:enable all
