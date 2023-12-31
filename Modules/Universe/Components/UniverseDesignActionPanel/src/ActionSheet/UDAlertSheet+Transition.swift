//
//  UDAlert.swift
//  UniverseDesignActionPanel
//
//  Created by bytedance on 2021/4/11.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignPopover

/// 视图展示样式，缩放展示的alert
public enum PresentTransform {
    // 缩放展示的alert
    case scale
    // 平移展示的ActionSheet
    case translation
}

public final class UDAlertTransition: NSObject, UIViewControllerTransitioningDelegate, UIAdaptivePresentationControllerDelegate {
    /// 是否显示 Dimming 黑色背景
    public var showDimmingView: Bool = true
    public var dismissCompletion: (() -> Void)?
    public var presentTransform: PresentTransform = .translation {
        didSet {
            presentAnimatedTransition.present = presentTransform
            dismissAnimatedTransition.present = presentTransform
        }
    }

    lazy var presentAnimatedTransition: UDAlertPresentAnimatedTransitioning = {
        var transition = UDAlertPresentAnimatedTransitioning()
        transition.present = presentTransform
        return transition
    }()

    lazy var dismissAnimatedTransition: UDAlertDismissAnimatedTransitioning = {
        var transition = UDAlertDismissAnimatedTransitioning()
        transition.present = presentTransform
        return transition
    }()

    init(dismissCompletion: (() -> Void)? = nil) {
        self.dismissCompletion = dismissCompletion
        super.init()
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationVC = UDDimmingPresentationController(presentedViewController: presented, presenting: presenting)
        presentationVC.showDimmingView = showDimmingView
        presentationVC.dismissCompletion = dismissCompletion
        presentationVC.delegate = self
        return presentationVC
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presentAnimatedTransition
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissAnimatedTransition
    }
}

class UDAlertPresentAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    weak var dimmingView: UIView?
    var present: PresentTransform = .translation

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
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
        }, completion: {
            transitionContext.completeTransition($0)
        })
    }
}

class UDAlertDismissAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {

    weak var dimmingView: UIView?
    var present: PresentTransform = .translation

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
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
