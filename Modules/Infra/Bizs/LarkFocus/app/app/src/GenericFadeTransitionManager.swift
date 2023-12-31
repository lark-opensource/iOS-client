//
//  GenericFadeTransitionManager.swift
//  Social
//
//  Created by Hayden on 2019/11/29.
//  Copyright © 2019 shengsheng. All rights reserved.
//

import Foundation
import UIKit

class GenericFadeTransitionManager: NSObject, UIViewControllerTransitioningDelegate {

    /// Singleton
    public static let `default` = GenericFadeTransitionManager()

    let animator = GenericFadeTransitionAnimator(transitionType: .present)

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.type = .present
        return animator
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.type = .dismiss
        return animator
    }

}

class GenericFadeTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    enum TransitionType {
        case present
        case dismiss
    }

    var type: TransitionType

    init(transitionType: TransitionType) {
        type = transitionType
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        switch type {
        case .present:  return 0.2
        case .dismiss:  return 0.2
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch type {
        case .present:  present(transitionContext)
        case .dismiss:  dismiss(transitionContext)
        }
    }

    private func present(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to) else { return }
        toView.alpha = 0
        toView.frame = UIScreen.main.bounds
        transitionContext.containerView.addSubview(toView)
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: {
            toView.alpha = 1
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

    private func dismiss(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else { return }
        let duration = transitionDuration(using: transitionContext)
        transitionContext.containerView.addSubview(fromView)
        UIView.animate(withDuration: duration, animations: {
            fromView.alpha = 0
        }, completion: { _ in
            fromView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
