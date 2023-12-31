//
//  WPTransitioningPageDown.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/12/23.
//

import Foundation

// 不应当强解包，需要业务处理
// swiftlint:disable force_unwrapping

final class WPPresentionTransitioningPageDown: NSObject, UIViewControllerAnimatedTransitioning {

    // 底部高度比例，(0 ~ 1)
    let startHRatio: CGFloat

    // 底部高度比例，(0 ~ 1)，需要比 startHRatio 大
    let endHRatio: CGFloat

    init(startHRatio: CGFloat, endHRatio: CGFloat) {
        guard endHRatio > startHRatio else {
            assertionFailure()
            self.startHRatio = 0
            self.endHRatio = 1
            super.init()
            return
        }
        self.startHRatio = min(1.0, max(0.0, startHRatio))
        self.endHRatio = min(1.0, max(0.0, endHRatio))
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let toVC = transitionContext.viewController(forKey: .to)!
        transitionContext.containerView.addSubview(toVC.view)
        transitionContext.containerView.isUserInteractionEnabled = false

        let totalH = transitionContext.containerView.bounds.height
        toVC.view.frame.origin.y = totalH * startHRatio
        toVC.view.frame.size.height = 0
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                transitionContext.containerView.backgroundColor = UIColor.clear
                toVC.view.frame.size.height = totalH * (self.endHRatio - self.startHRatio)
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}

final class WPDissmissionTransitioningPageDown: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: .from)!

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                transitionContext.containerView.backgroundColor = UIColor.clear
                fromVC.view.frame.size.height = 0
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}
// swiftlint:enable force_unwrapping
