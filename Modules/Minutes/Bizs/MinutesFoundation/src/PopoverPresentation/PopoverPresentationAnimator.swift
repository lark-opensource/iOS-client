//
//  PopoverPresentationAnimator.swift
//  MinutesFoundation
//
//  Created by chenlehui on 2021/8/10.
//

import UIKit

public final class PopoverPresentationAnimator: NSObject {
    public var isPresentation: Bool
    weak var toViewController: UIViewController?
    weak var fromViewController: UIViewController?

    public required init(isPresentation: Bool) {
        self.isPresentation = isPresentation
        super.init()
    }
}

extension PopoverPresentationAnimator: UIViewControllerAnimatedTransitioning {

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isPresentation ? 0.1 : 0.25
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        toViewController?.beginAppearanceTransition(true, animated: true)

        fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)

        let key = isPresentation ? UITransitionContextViewControllerKey.to : UITransitionContextViewControllerKey.from
        let controller = transitionContext.viewController(forKey: key)!
        if isPresentation {
            transitionContext.containerView.addSubview(controller.view)
        }
        let duration = transitionDuration(using: transitionContext)

        controller.view.alpha = isPresentation ? 0 : 1
        UIView.animate(withDuration: duration) {
            controller.view.alpha = self.isPresentation ? 1 : 0
        } completion: { (isFinished) in
            transitionContext.completeTransition(isFinished)
        }
    }

    public func animationEnded(_ transitionCompleted: Bool) {
        if transitionCompleted {
            toViewController?.endAppearanceTransition()
        }
    }
}
