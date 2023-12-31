//
//   AlertPresentSlideUp.swift
//   Alert
//
//  Created by WangXiaoZhen on 2018/1/20.
//  Included OSS: PopKit
//  Copyright 2017 PopKit
//  spdx license identifier: MIT

import UIKit
import SKFoundation

class  AlertPresentSlideUp: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) as?  DocsAlertController else { return }
        let fromVC = transitionContext.viewController(forKey: .from)!
        let containerView = transitionContext.containerView
        // 设置动画前的状态
        toVC.dimBackgroundView.alpha = 0
        toVC.alertView.frame = CGRect(x: fromVC.view.frame.minX,
                                      y: fromVC.view.ext.height,
                                      width: fromVC.view.frame.width,
                                      height: fromVC.view.ext.height)
        containerView.addSubview(toVC.view)
        // 开始动画
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.0, options: .curveLinear, animations: {
                        toVC.dimBackgroundView.alpha = 1
                        toVC.alertView.frame = transitionContext.finalFrame(for: toVC)
        }, completion: { (_) in
            transitionContext.completeTransition(true)
        })
    }
}

class  AlertDismissSlideDown: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as?  DocsAlertController else {
            return
        }
        // 设置动画前的状态
        fromVC.dimBackgroundView.alpha = 1
        var finalY: CGFloat = 0.0
        finalY = fromVC.view.ext.height
        let duration = transitionDuration(using: transitionContext)
        // 开始动画
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.0, options: .curveLinear,
                       animations: {
                        fromVC.dimBackgroundView.alpha = 0
                        fromVC.alertView.frame.origin.y += finalY
        }, completion: { (_) in
            transitionContext.completeTransition(true)
        })
    }
}

class  AlertMoveFilePresentSlideUp: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) as?  MoveFilesAlertController else { return }
        let fromVC = transitionContext.viewController(forKey: .from)!
        let containerView = transitionContext.containerView
        // 设置动画前的状态
        toVC.dimBackgroundView.alpha = 0
        toVC.alertView.frame = CGRect(x: fromVC.view.frame.minX,
                                      y: fromVC.view.ext.height,
                                      width: fromVC.view.frame.width,
                                      height: fromVC.view.ext.height)
        containerView.addSubview(toVC.view)
        // 开始动画
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.0, options: .curveLinear, animations: {
                        toVC.dimBackgroundView.alpha = 1
                        toVC.alertView.frame = transitionContext.finalFrame(for: toVC)
        }, completion: { (_) in
            transitionContext.completeTransition(true)
        })
    }
}

class  AlertMoveFileDismissSlideDown: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as?  MoveFilesAlertController else {
            return
        }
        // 设置动画前的状态
        fromVC.dimBackgroundView.alpha = 0.4
        let duration = transitionDuration(using: transitionContext)
        // 开始动画
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.0, options: .curveLinear,
                       animations: {
                        fromVC.dimBackgroundView.alpha = 0
            fromVC.alertView.frame.origin.y = SKDisplay.activeWindowBounds.height
        }, completion: { (_) in
            transitionContext.completeTransition(true)
        })
    }
}
