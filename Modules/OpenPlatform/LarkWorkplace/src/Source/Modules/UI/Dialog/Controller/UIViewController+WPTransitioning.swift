//
//  UIViewController+WPTransitioning.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/8/24.
//

import UIKit

enum WPModalTransitioningStyle {
    // 弹窗效果
    case pop

    // 类似 ActionSheet, heightRatio 参数为高度占比，[0, 1]
    case pageUp(heightRatio: Float)

    // 从上至下展开，start 为展开起始位置占页面的比例 [0, 1]，end 为展开结束位置占页面的比例 [0, 1]
    case pageDown(start: CGFloat = 0, end: CGFloat = 1)
}

final class WPModalTransitioningAnimator: NSObject, UIViewControllerTransitioningDelegate {
    /// 转场风格
    let style: WPModalTransitioningStyle

    init(_ style: WPModalTransitioningStyle) {
        self.style = style
        super.init()
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        switch style {
        case .pop:
            return WPPresentionTransitioningPop()
        case .pageUp(let ratio):
            return WPPresentionTransitioningPageUp(heightRatio: ratio)
        case .pageDown(let start, let end):
            return WPPresentionTransitioningPageDown(startHRatio: start, endHRatio: end)
        }
    }

    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        switch style {
        case .pop:
            return WPDissmissionTransitioningPop()
        case .pageUp:
            return WPDissmissionTransitioningPageUp()
        case .pageDown:
            return WPDissmissionTransitioningPageDown()
        }
    }
}

extension UIViewController {
    private enum AssociateKeys {
        static var modalAnimator: Void?
    }

    /// 给 UIViewController 设置自定义的 Modal 转场风格
    // 变量命名不要带下划线
    // swiftlint:disable identifier_name
    var wp_modalStyle: WPModalTransitioningStyle? {
        get {
            wp_modalAnimator?.style
        }
        set {
            if let val = newValue {
                wp_modalAnimator = WPModalTransitioningAnimator(val)
            } else {
                wp_modalAnimator = nil
            }
        }
    }

    private var wp_modalAnimator: WPModalTransitioningAnimator? {
        get {
            objc_getAssociatedObject(self, &AssociateKeys.modalAnimator) as? WPModalTransitioningAnimator
        }
        set {
            objc_setAssociatedObject(self, &AssociateKeys.modalAnimator, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if newValue != nil {
                modalPresentationStyle = .custom
            } else {
                if #available(iOS 13.0, *) {
                    modalPresentationStyle = .automatic
                } else {
                    modalPresentationStyle = .fullScreen
                }
            }
            transitioningDelegate = newValue
        }
    }
    // swiftlint:enable identifier_name
}
