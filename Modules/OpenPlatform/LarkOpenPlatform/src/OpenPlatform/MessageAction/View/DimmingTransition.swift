//
//  DimmingTransition.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/5/17.
//

import UIKit
import UniverseDesignTheme
import UniverseDesignColor

class DimmingPresentationController: UIPresentationController {

    private let dimmingView = UIView()

    init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?,
                  backgroundColor: UIColor) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        dimmingView.backgroundColor = backgroundColor
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        presentingViewController.view.tintAdjustmentMode = .dimmed
        dimmingView.alpha = 0
        containerView?.addSubview(dimmingView)
        let coordinator = presentedViewController.transitionCoordinator
                coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 1 }, completion: { _ in
            if self.dimmingView.alpha == 0 {
                self.dimmingView.alpha = 1
            }
        })
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentingViewController.view.tintAdjustmentMode = .automatic
        let coordinator = presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 0 }, completion: nil)
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if let containerView = containerView {
            dimmingView.frame = containerView.frame
        }
    }
}

class DimmingTransition: NSObject, UIViewControllerTransitioningDelegate {
    private let backgroundColor: UIColor

    init(backgroundColor: UIColor = UIColor.ud.bgMask) {
        self.backgroundColor = backgroundColor
    }

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController)
        -> UIPresentationController? {
            return DimmingPresentationController(presentedViewController: presented,
                                                presenting: presenting,
                                                backgroundColor: backgroundColor)
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
        return DimmingAnimator(isPresenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DimmingAnimator(isPresenting: false)
    }
}

class DimmingAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool

    public init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = isPresenting ? UITransitionContextViewControllerKey.to : UITransitionContextViewControllerKey.from
        let controller = transitionContext.viewController(forKey: key)!

        if isPresenting {
            transitionContext.containerView.addSubview(controller.view)
        }

//        controller.view.transform = isPresenting ? CGAffineTransform(scaleX: 0.3, y: 0.3) : CGAffineTransform.identity
        controller.view.alpha = isPresenting ? 0 : 1
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
//            controller.view.transform = self.isPresenting ? CGAffineTransform.identity :
//                CGAffineTransform(scaleX: 0.3, y: 0.3)
            controller.view.alpha = self.isPresenting ? 1 : 0
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
