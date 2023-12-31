//
//  ImageEditDismissTransition.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/8/7.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import UIKit
import Foundation

final class ImageEditPresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private let transitionFromView: UIView
    private let transitionToView: UIView

    init(transitionFromView: UIView, transitionToView: UIView) {
        self.transitionFromView = transitionFromView
        self.transitionToView = transitionToView
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
                transitionContext.completeTransition(false)
                return
        }
        toVC.view.frame = transitionContext.containerView.bounds
        toVC.view.layoutIfNeeded()
        let orginFrame = fromVC.view.convert(transitionFromView.bounds, from: transitionFromView)
        let toFrame = toVC.view.convert(transitionToView.bounds, from: transitionToView)

        let snapView: UIView = transitionFromView.snapshotView(afterScreenUpdates: true) ?? .init()
        snapView.frame = orginFrame
        transitionContext.containerView.backgroundColor = UIColor.black
        transitionContext.containerView.addSubview(snapView)
        fromVC.view.isHidden = true

        transitionContext.containerView.addSubview(toVC.view)
        toVC.view.alpha = 0

        UIView.animate(withDuration: transitionDuration(using: transitionContext) / 2, animations: {
            snapView.frame = toFrame
        }, completion: { (_) in
            UIView.animate(
                withDuration: self.transitionDuration(using: transitionContext) / 2,
                animations: {
                    toVC.view.alpha = 1
                },
                completion: { (_) in
                    snapView.removeFromSuperview()
                    transitionContext.containerView.addSubview(toVC.view)
                    fromVC.view.isHidden = false
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                })
        })
    }
}

final class ImageEditDismissTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private let transitionFromView: UIView
    private let transitionToView: UIView

    init(transitionFromView: UIView, transitionToView: UIView) {
        self.transitionFromView = transitionFromView
        self.transitionToView = transitionToView
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
                as? CropperViewController,
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
                transitionContext.completeTransition(false)
                return
        }
        fromVC.view.isHidden = true
        toVC.view.layoutIfNeeded()
        let orginFrame = fromVC.view.convert(transitionFromView.bounds, from: transitionFromView)
        let toFrame = toVC.view.convert(transitionToView.bounds, from: transitionToView)

        transitionFromView.frame = orginFrame
        transitionContext.containerView.addSubview(transitionFromView)

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       animations: {
            self.transitionFromView.frame = toFrame
        },
                       completion: { (_) in
            self.transitionFromView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
