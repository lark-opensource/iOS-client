//
//  UDPanelStyleTransitioning.swift
//  UniverseDesignPopover
//
//  Created by Hayden on 2023/4/11.
//

import UIKit

open class UDPanelStylePresentationTransitioning: NSObject, UIViewControllerAnimatedTransitioning {

    public weak var dimmingView: UIView?

    public private(set) var animationDuration: TimeInterval

    public init(duration: TimeInterval = 0.25, dimmingView: UIView? = nil) {
        self.animationDuration = duration
        self.dimmingView = dimmingView
    }

    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }

    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = UITransitionContextViewControllerKey.to
        guard let controller = transitionContext.viewController(forKey: key) else {
            return
        }

        if let dimmingView = dimmingView {
            transitionContext.containerView.addSubview(dimmingView)
            dimmingView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            dimmingView.layoutIfNeeded()
        }

        transitionContext.containerView.addSubview(controller.view)
        controller.view.frame = transitionContext.containerView.bounds

        controller.view.transform = CGAffineTransform(
            translationX: 0,
            y: controller.view.bounds.height)
        controller.view.alpha = 0
        self.dimmingView?.alpha = 0

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: { [weak self] in
            controller.view.transform = CGAffineTransform.identity
            controller.view.alpha = 1
            self?.dimmingView?.alpha = 1
        }, completion: { transitionContext.completeTransition($0) })
    }
}

open class UDPanelStyleDismissalTransitioning: NSObject, UIViewControllerAnimatedTransitioning {

    public weak var dimmingView: UIView?

    public private(set) var animationDuration: TimeInterval

    public init(duration: TimeInterval = 0.25, dimmingView: UIView? = nil) {
        self.animationDuration = duration
        self.dimmingView = dimmingView
    }

    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }

    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = UITransitionContextViewControllerKey.from
        guard let controller = transitionContext.viewController(forKey: key) else { return }

        controller.view.transform = CGAffineTransform.identity
        controller.view.alpha = 1
        self.dimmingView?.alpha = 1

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: { [weak self] in
            controller.view.transform = CGAffineTransform(
                translationX: 0,
                y: controller.view.bounds.height
            )
            controller.view.alpha = 0
            self?.dimmingView?.alpha = 0
        }, completion: { [weak self] in
            transitionContext.completeTransition($0)
            self?.dimmingView?.removeFromSuperview()
        })
    }
}
