//
//  VCAnimation.swift
//  LarkSearch
//
//  Created by hebonning on 2019/9/23.
//

import Foundation
import UIKit

final class ChatKeyWordFadeAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to) as? ChatKeyWordFilterViewController
            else {
                return
        }
        transitionContext.containerView.addSubview(toViewController.view)
        toViewController.colorBgView.alpha = 0
        toViewController.view.layoutIfNeeded()

        let duration = self.transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration,
                       animations: {
                        toViewController.textView.becomeFirstResponder()
                        toViewController.colorBgView.alpha = 1
                        toViewController.view.layoutIfNeeded()
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

final class ChatKeyWordDisapearAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? ChatKeyWordFilterViewController
            else {
                return
        }

        let duration = self.transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration,
                       animations: {
                        fromViewController.colorBgView.alpha = 0
                        fromViewController.keywordView.snp.remakeConstraints { (make) in
                            make.size.equalTo(fromViewController.view.bounds.size)
                            make.left.equalTo(0)
                            make.top.equalTo(fromViewController.view.snp.bottom)
                        }
                        fromViewController.view.layoutIfNeeded()
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
