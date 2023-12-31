//
//  MinutesRightSideAnimator.swift
//  Minutes
//
//  Created by lvdaqian on 2021/2/1.
//

import Foundation

public final class MinutesRightSideAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool

    public init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }

    // disable-lint: magic number
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    // enable-lint: magic number

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = isPresenting ? UITransitionContextViewControllerKey.to : UITransitionContextViewControllerKey.from
        let controller = transitionContext.viewController(forKey: key)!

        if isPresenting {
            transitionContext.containerView.addSubview(controller.view)
        }

        controller.view.transform = isPresenting ? CGAffineTransform(translationX: 208, y: 0) : CGAffineTransform.identity
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            controller.view.transform = self.isPresenting ? CGAffineTransform.identity :
                CGAffineTransform(translationX: 208, y: 0)
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
