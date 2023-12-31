//
//  AddContactSearchTransition.swift
//  LarkContact
//
//  Created by ChalrieSu on 2018/9/13.
//

import Foundation
import UIKit

final class AddContactSearchPresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private let transitionFromView: UIView
    private let transitionToView: UIView

    init(transitionFromView: UIView, transitionToView: UIView) {
        self.transitionFromView = transitionFromView
        self.transitionToView = transitionToView
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
                transitionContext.completeTransition(false)
                return
        }

        toVC.view.layoutIfNeeded()
        guard let snapShot = transitionToView.snapshotView(afterScreenUpdates: true) else {
            transitionContext.completeTransition(false)
            return
        }
        transitionContext.containerView.addSubview(toVC.view)
        toVC.view.alpha = 0

        let bgView = UIView()
        bgView.backgroundColor = .white
        bgView.frame = toVC.view.frame
        transitionContext.containerView.insertSubview(bgView, belowSubview: toVC.view)

        let startFrame = transitionFromView.convert(transitionFromView.bounds, to: transitionContext.containerView)
        var finalFrame = transitionToView.convert(transitionToView.bounds, to: transitionContext.containerView)
        finalFrame.origin.y += UIApplication.shared.statusBarFrame.height

        transitionContext.containerView.addSubview(snapShot)
        snapShot.frame.origin.x = startFrame.origin.x
        snapShot.frame.centerY = startFrame.centerY

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       animations: {
                        snapShot.frame = finalFrame
        }) { (finished) in
            toVC.view.alpha = 1
            snapShot.removeFromSuperview()
            bgView.removeFromSuperview()
            transitionContext.completeTransition(finished)
        }
    }
}
