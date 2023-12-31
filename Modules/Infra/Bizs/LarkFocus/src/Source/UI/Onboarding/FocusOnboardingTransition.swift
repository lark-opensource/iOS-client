//
//  FocusOnboardingTransition.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/10/11.
//

import Foundation
import UIKit
import UniverseDesignColor

/// 视图展示样式，缩放展示的alert
public enum OnboardingPresentTransform {
    // 缩放展示的alert
    case scale
    // 平移展示的ActionSheet
    case translation
}

public final class FocusOnboardingTransition: NSObject, UIViewControllerTransitioningDelegate, UIAdaptivePresentationControllerDelegate {
    /// 是否显示 Dimming 黑色背景
    public var showDimmingView: Bool = false
    public var dismissCompletion: (() -> Void)?
    public var presentTransform: OnboardingPresentTransform = .translation {
        didSet {
            presentAnimatedTransition.present = presentTransform
            dismissAnimatedTransition.present = presentTransform
        }
    }

    lazy var dimmingView: UIView = {
        let dimmingView = UIView()
        // dimmingView.backgroundColor = UDColor.bgMask
        return dimmingView
    }()

    lazy var presentAnimatedTransition: FocusOnboardingPresentAnimatedTransitioning = {
        var transition = FocusOnboardingPresentAnimatedTransitioning()
        transition.present = presentTransform
        if self.showDimmingView {
            transition.dimmingView = self.dimmingView
        }
        return transition
    }()

    lazy var dismissAnimatedTransition: FocusOnboardingDismissAnimatedTransitioning = {
        var transition = FocusOnboardingDismissAnimatedTransitioning()
        transition.present = presentTransform
        if self.showDimmingView {
            transition.dimmingView = self.dimmingView
        }
        return transition
    }()

    public init(dismissCompletion: (() -> Void)? = nil) {
        self.dismissCompletion = dismissCompletion
        super.init()
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let vc = FocusOnboardingPresentationController(presentedViewController: presented, presenting: presenting)
        vc.dimmingView = self.dimmingView
        vc.delegate = self
        return vc
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presentAnimatedTransition
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissAnimatedTransition
    }
}

final class FocusOnboardingPresentAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    weak var dimmingView: UIView?
    var present: OnboardingPresentTransform = .translation

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
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

        var transform: CGAffineTransform
        switch present {
        case .scale:
            transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        case .translation:
            transform = CGAffineTransform(translationX: 0, y: controller.view.bounds.height)
        }
        controller.view.transform = transform
        controller.view.alpha = 0
        self.dimmingView?.alpha = 0

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: { [weak self] in
            controller.view.transform = CGAffineTransform.identity
            controller.view.alpha = 1
            self?.dimmingView?.alpha = 1
        }, completion: { transitionContext.completeTransition($0) })
    }
}

final class FocusOnboardingDismissAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {

    weak var dimmingView: UIView?
    var present: OnboardingPresentTransform = .translation

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = UITransitionContextViewControllerKey.from
        guard let controller = transitionContext.viewController(forKey: key) else { return }

        var transform: CGAffineTransform
        switch present {
        case .scale:
            transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        case .translation:
            transform = CGAffineTransform(translationX: 0, y: controller.view.bounds.height)
        }

        controller.view.transform = CGAffineTransform.identity
        controller.view.alpha = 1
        self.dimmingView?.alpha = 1

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: { [weak self] in
            controller.view.transform = transform
            controller.view.alpha = 0
            self?.dimmingView?.alpha = 0
        }, completion: { [weak self] in
            transitionContext.completeTransition($0)
            self?.dimmingView?.removeFromSuperview()
        })
    }
}

final class FocusOnboardingPresentationController: UIPresentationController {

    weak var dimmingView: UIView?
    var dismissCompletion: (() -> Void)?

    init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?,
                  dismissCompletion: (() -> Void)? = nil) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.dismissCompletion = dismissCompletion
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .dimmed
        if let dimmingView = self.dimmingView {
            dimmingView.removeFromSuperview()
        }
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .automatic
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        let vc = self.presentedViewController
        if !vc.isBeingDismissed {
            if let containerView = self.presentedViewController.view.superview,
                let dimmingView = self.dimmingView {
                containerView.insertSubview(dimmingView, at: 0)
                dimmingView.snp.makeConstraints { (maker) in
                    maker.edges.equalToSuperview()
                }
                dimmingView.layoutIfNeeded()
            }
        }
        dismissCompletion?()
    }
}
