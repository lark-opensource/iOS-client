//
//  MessageTranslateFeedBackTransition.swift
//  LarkChat
//
//  Created by bytedance on 2020/8/25.
//

import Foundation
import UIKit

private final class MessageTranslateFeedbackPresentationController: UIPresentationController {

    private let dimmingView = UIView()

    init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?,
                  backgroundColor: UIColor = UIColor.ud.bgMask) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        dimmingView.backgroundColor = backgroundColor
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        presentingViewController.view.tintAdjustmentMode = .dimmed
        dimmingView.alpha = 0
        containerView?.addSubview(dimmingView)
        let coordinator = presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 1 }, completion: nil)
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
            dimmingView.frame = containerView.bounds
        }
    }
}

final class MessageTranslateFeedbackTransition: NSObject, UIViewControllerTransitioningDelegate {
    private let backgroundColor: UIColor

    init(backgroundColor: UIColor) {
        self.backgroundColor = backgroundColor
    }

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController)
        -> UIPresentationController? {
            return MessageTranslateFeedbackPresentationController(presentedViewController: presented,
                                                presenting: presenting,
                                                backgroundColor: backgroundColor)
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            return nil
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}
