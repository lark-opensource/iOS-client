//
//  AlbumListTransition.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/9/5.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation

final class AlbumListPresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private let transitionView: UIView

    init(transitionView: UIView) {
        self.transitionView = transitionView
        self.transitionView.translatesAutoresizingMaskIntoConstraints = false
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            transitionContext.completeTransition(false)
            return
        }

        transitionContext.containerView.addSubview(toVC.view)
        toVC.view.layoutIfNeeded()
        let originBgColor = toVC.view.backgroundColor
        let originAnchorPoint = transitionView.layer.anchorPoint
        let originTransform = transitionView.transform
        let originFrame = transitionView.frame

        transitionView.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
        transitionView.frame = originFrame
        transitionView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        toVC.view.backgroundColor = toVC.view.backgroundColor?.withAlphaComponent(0)

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 1.3,
                       options: .allowUserInteraction,
                       animations: {
            self.transitionView.transform = originTransform
            toVC.view.backgroundColor = originBgColor

        },
                       completion: { (_) in
            self.transitionView.layer.anchorPoint = originAnchorPoint
            self.transitionView.frame = originFrame
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

final class AlbumListDismissTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private let transitionView: UIView

    init(transitionView: UIView) {
        self.transitionView = transitionView
        self.transitionView.translatesAutoresizingMaskIntoConstraints = false
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else {
            transitionContext.completeTransition(false)
            return
        }
        let originBgColor = fromVC.view.backgroundColor
        let originAnchorPoint = transitionView.layer.anchorPoint
        let originTransform = transitionView.transform
        let originFrame = transitionView.frame

        transitionView.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
        transitionView.frame = originFrame
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            self.transitionView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            fromVC.view.backgroundColor = originBgColor?.withAlphaComponent(0)
        }, completion: { _ in
            self.transitionView.layer.anchorPoint = originAnchorPoint
            self.transitionView.transform = originTransform
            self.transitionView.frame = originFrame
            fromVC.view.backgroundColor = originBgColor
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
