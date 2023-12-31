//
//  OpenRedPacketTransition.swift
//  LarkFinance
//
//  Created by ChalrieSu on 2018/10/24.
//

import UIKit
import Foundation

final class OpenRedPacketPresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.42
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let redPacketVC = toVC as? OpenRedPacketViewController else {
                transitionContext.completeTransition(false)
                return
        }

        let containerView = transitionContext.containerView
        redPacketVC.view.layoutIfNeeded()
        containerView.addSubview(redPacketVC.view)
        redPacketVC.contentView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        redPacketVC.contentView.alpha = 0

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut,
                       animations: {
                        redPacketVC.contentView.transform = .identity
                        redPacketVC.contentView.alpha = 1
        }, completion: { (_) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

final class OpenRedPacketDismissTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let redPacketVC = fromVC as? OpenRedPacketViewController else {
                transitionContext.completeTransition(false)
                return
        }

        let containerView = transitionContext.containerView
        redPacketVC.view.layoutIfNeeded()
        containerView.addSubview(redPacketVC.view)

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       animations: {
                        redPacketVC.contentView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                        redPacketVC.contentView.alpha = 0
        }, completion: { (_) in
            redPacketVC.contentView.transform = .identity
            redPacketVC.contentView.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
