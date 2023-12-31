//
//  File.swift
//  LarkLogin
//
//  Created by SuPeng on 1/9/19.
//

import Foundation
import UIKit

extension UIView {
    func screenshot() -> UIImage? {
        let transform = self.transform
        self.transform = .identity
        var screenshot: UIImage?
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, UIScreen.main.scale)
        if let context = UIGraphicsGetCurrentContext() {
            self.layer.render(in: context)
            screenshot = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        self.transform = transform
        return screenshot
    }

    func screenshotView() -> UIView {
        return UIImageView(image: screenshot())
    }
}

class V3LoginNaviPushTransition: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from) as? BaseViewController,
            let toVC = transitionContext.viewController(forKey: .to) as? BaseViewController else {
                transitionContext.completeTransition(false)
                return
        }

        let containerView = transitionContext.containerView

        containerView.addSubview(toVC.view)
        toVC.view.layoutIfNeeded()
        toVC.view.alpha = 0

        let fromContentView = fromVC.moveBoddyView.screenshotView()
        containerView.addSubview(fromContentView)
        fromContentView.frame = fromVC.view.convert(fromVC.moveBoddyView.frame, to: containerView)
        fromVC.moveBoddyView.alpha = 0

        let toContentView = toVC.moveBoddyView.screenshotView()
        containerView.addSubview(toContentView)
        toContentView.frame = toVC.view.convert(toVC.moveBoddyView.frame, to: containerView)
        toContentView.frame.origin = CGPoint(x: toContentView.frame.origin.x + 100,
                                             y: toContentView.frame.origin.y)
        toContentView.alpha = 0

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       options: .curveEaseOut,
                       animations: {
                        fromContentView.frame.origin = CGPoint(x: fromContentView.frame.origin.x - 100,
                                                               y: fromContentView.frame.origin.y)
                        fromContentView.alpha = 0

                        toContentView.frame.origin = CGPoint(x: toContentView.frame.origin.x - 100,
                                                             y: toContentView.frame.origin.y)
                        toContentView.alpha = 1
        }, completion: { (_) in
            fromContentView.removeFromSuperview()
            toContentView.removeFromSuperview()
            toVC.view.alpha = 1
            fromVC.moveBoddyView.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

class V3LoginNaviPopTransition: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from) as? BaseViewController,
            let toVC = transitionContext.viewController(forKey: .to) as? BaseViewController else {
                transitionContext.completeTransition(false)
                return
        }

        let containerView = transitionContext.containerView

        containerView.insertSubview(toVC.view, at: 0)
        toVC.view.alpha = 0

        let fromContentView = fromVC.moveBoddyView.screenshotView()
        containerView.addSubview(fromContentView)
        fromContentView.frame = fromVC.view.convert(fromVC.moveBoddyView.frame, to: containerView)
        fromVC.moveBoddyView.alpha = 0

        let toContentView = toVC.moveBoddyView.screenshotView()
        containerView.addSubview(toContentView)
        toContentView.frame = toVC.view.convert(toVC.moveBoddyView.frame, to: containerView)
        toContentView.frame.origin = CGPoint(x: toContentView.frame.origin.x - 100,
                                             y: toContentView.frame.origin.y)
        toContentView.alpha = 0

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       options: .curveEaseOut,
                       animations: {
                        fromContentView.frame.origin = CGPoint(x: fromContentView.frame.origin.x + 100,
                                                               y: fromContentView.frame.origin.y)
                        fromContentView.alpha = 0

                        toContentView.frame.origin = CGPoint(x: toContentView.frame.origin.x + 100,
                                                             y: toContentView.frame.origin.y)
                        toContentView.alpha = 1
        }, completion: { (_) in
            fromContentView.removeFromSuperview()
            toContentView.removeFromSuperview()
            toVC.view.alpha = 1
            fromVC.moveBoddyView.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
