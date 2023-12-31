//
//  MedalAnimationView+Transition.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/9/8.
//

import Foundation
import UIKit
import UniverseDesignColor
import FigmaKit

public final class MedalAnimationPresentationController: UIPresentationController {

    private lazy var dimmingView: UIView = {
        let blurView = VisualBlurView()
        blurView.blurRadius = Cons.dimmingViewBlurRadius
        blurView.fillColor = UIColor.ud.primaryOnPrimaryFill
        blurView.fillOpacity = Cons.dimmingViewFillOpacity
        return blurView
    }()

    override public init(presentedViewController: UIViewController,
                         presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    override public func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .dimmed
        self.dimmingView.alpha = 0
        self.containerView?.addSubview(self.dimmingView)
        let coordinator = self.presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 1 })
    }

    override public func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .automatic
        let coordinator = self.presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 0 }, completion: nil)
    }

    override public func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if let containerView = self.containerView {
            self.dimmingView.frame = containerView.frame
        }
    }
}

final class MedalAnimationransitioningDelegate: UIViewController, UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController,
                                       presenting: UIViewController?,
                                       source: UIViewController)
        -> UIPresentationController? {
            return MedalAnimationPresentationController(presentedViewController: presented, presenting: presenting)
    }

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            return MedalAnimationAnimator(isPresenting: true)
    }

    public func animationController(forDismissed dismissed: UIViewController) ->
        UIViewControllerAnimatedTransitioning? {
        return MedalAnimationAnimator(isPresenting: false)
    }
}

public final class MedalAnimationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool

    public init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Cons.transitionDuration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = isPresenting ? UITransitionContextViewControllerKey.to : UITransitionContextViewControllerKey.from
        let controller = transitionContext.viewController(forKey: key)!

        if isPresenting {
            transitionContext.containerView.addSubview(controller.view)
        }

        controller.view.transform = isPresenting ? CGAffineTransform(scaleX: 0.3, y: 0.3) : CGAffineTransform.identity
        controller.view.alpha = isPresenting ? 0 : 1
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            controller.view.transform = self.isPresenting ? CGAffineTransform.identity :
                CGAffineTransform(scaleX: 0.3, y: 0.3)
            controller.view.alpha = self.isPresenting ? 1 : 0
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

extension MedalAnimationPresentationController {
    enum Cons {
        static var dimmingViewBlurRadius: CGFloat = 24
        static var dimmingViewFillOpacity: CGFloat = 0.4
    }
}

extension MedalAnimationAnimator {
    enum Cons {
        static var transitionDuration: TimeInterval = 0.25
    }
}

