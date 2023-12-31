//
//  WPTransitioningPageUp.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/11/1.
//

import Foundation

final class WPPresentionTransitioningPageUp: NSObject, UIViewControllerAnimatedTransitioning {

    // 高度占比，[0, 1]
    let heightRatio: Float

    init(heightRatio: Float) {
        self.heightRatio = min(1.0, max(0.0, heightRatio))
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 不应该出现强解包，需要业务调整
        // swiftlint:disable force_unwrapping
        let toVC = transitionContext.viewController(forKey: .to)!
        // swiftlint:enable force_unwrapping
        transitionContext.containerView.addSubview(toVC.view)
        let totalH = transitionContext.containerView.bounds.height
        toVC.view.frame.origin.y = totalH
        toVC.view.frame.size.height = 0
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                transitionContext.containerView.backgroundColor = UIColor.ud.bgMask
                toVC.view.frame.origin.y = totalH * CGFloat(1 - self.heightRatio)
                toVC.view.frame.size.height = totalH * CGFloat(self.heightRatio)
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}

final class WPDissmissionTransitioningPageUp: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 不应该出现强解包，需要业务调整
        // swiftlint:disable force_unwrapping
        let fromVC = transitionContext.viewController(forKey: .from)!
        // swiftlint:enable force_unwrapping
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                transitionContext.containerView.backgroundColor = UIColor.clear
                fromVC.view.frame.origin.y = transitionContext.containerView.bounds.height
                fromVC.view.frame.size.height = 0
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}
