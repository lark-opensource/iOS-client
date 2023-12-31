//
//  WPTransitioningPop.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/8/24.
//

import UIKit

final class WPPresentionTransitioningPop: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 不应当强解包，需要业务处理
        // swiftlint:disable force_unwrapping
        let toVC = transitionContext.viewController(forKey: .to)!
        // swiftlint:enable force_unwrapping
        transitionContext.containerView.addSubview(toVC.view)

        toVC.view.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        toVC.view.alpha = 0
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                transitionContext.containerView.backgroundColor = UIColor.ud.bgMask
                toVC.view.transform = CGAffineTransform.identity
                toVC.view.alpha = 1
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}

final class WPDissmissionTransitioningPop: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 不应当强解包，需要业务处理
        // swiftlint:disable force_unwrapping
        let fromVC = transitionContext.viewController(forKey: .from)!
        // swiftlint:enable force_unwrapping
        fromVC.view.transform = CGAffineTransform.identity
        fromVC.view.alpha = 1
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                transitionContext.containerView.backgroundColor = UIColor.clear
                fromVC.view.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                fromVC.view.alpha = 0
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}
