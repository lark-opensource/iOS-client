//
//  VCAnimation.swift
//  LarkSearch
//
//  Created by hebonning on 2019/9/23.
//

import Foundation
import UIKit

protocol PresentWithFadeAnimatorVC: AnyObject {
    var colorBgView: UIView { get }
    var contentView: UIView { get }
}

final class PresentWithFadeAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to),
            let toVC = toViewController as? (PresentWithFadeAnimatorVC & UIViewController)
        else {
            assertionFailure("invalid call, only can be used by UIViewController&PresentWithFadeAnimatorVC")
            return
        }
        transitionContext.containerView.addSubview(toVC.view)
        toVC.colorBgView.alpha = 0
        toVC.view.layoutIfNeeded()
        // 只要动画期间的临时状态，所以不动size，应该也不影响layout的效果
        toVC.contentView.frame.origin.y = toVC.view.bounds.height

        let duration = self.transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: {
                        toVC.colorBgView.alpha = 1
                        toVC.contentView.frame.origin.y = toVC.view.bounds.height - toVC.contentView.frame.size.height
                        toViewController.view.layoutIfNeeded()
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

final class DismissWithFadeAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromViewController = transitionContext.viewController(forKey: .from),
            let fromVC = fromViewController as? PresentWithFadeAnimatorVC
        else {
            assertionFailure("invalid call, only can be used by UIViewController&PresentWithFadeAnimatorVC")
            return
        }

        let duration = self.transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, delay: 0, animations: {
            // 只要动画期间的临时状态，所以不动size，应该也不影响layout的效果
            fromVC.colorBgView.alpha = 0
            fromVC.contentView.frame.origin.y = fromViewController.view.bounds.height
            // fromVC.contentView.snp.remakeConstraints { (make) in
            //     make.size.equalTo(fromViewController.view.bounds.size)
            //     make.left.equalTo(0)
            //     make.top.equalTo(fromViewController.view.snp.bottom)
            // }
            fromViewController.view.layoutIfNeeded()
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
