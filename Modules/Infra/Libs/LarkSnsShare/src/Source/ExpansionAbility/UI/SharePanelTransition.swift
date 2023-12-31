//
//  SharePanelTransition.swift
//  LarkSnsShare
//
//  Created by bytedance on 2022/3/17.

import Foundation
import UIKit

// ignore magic number checking for ViewController
// disable-lint: magic number

private final class SharePanelPresentationController: UIPresentationController {

    private let dimmingView: UIView = {
        let dimmingView = UIView()
        dimmingView.backgroundColor = ShareColor.maskColor
        return dimmingView
    }()

    private var currentUserInterfaceStyle: SharePanelTheme = .unspecified

    @available(iOS 13.0, *)
    var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        set {
            switch newValue {
            case .light:
                self.dimmingView.backgroundColor = ShareColor.maskColor.alwaysLight
            case .dark:
                self.dimmingView.backgroundColor = ShareColor.maskColor.alwaysDark
            default:
                self.dimmingView.backgroundColor = ShareColor.maskColor
            }
            self.currentUserInterfaceStyle = SharePanelTheme.convert(from: newValue)
        }
        get {
            return SharePanelTheme.convert(from: currentUserInterfaceStyle)
        }
    }

    override init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .dimmed
        self.dimmingView.alpha = 0
        self.containerView?.addSubview(self.dimmingView)
        if let coordinator = self.presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { [weak self] _ in
                self?.dimmingView.alpha = 1
            }, completion: nil)
        } else {
            self.dimmingView.alpha = 1
        }
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .automatic
        if let coordinator = self.presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { [weak self] _ in
                self?.dimmingView.alpha = 0
            }, completion: nil)
        } else {
            self.dimmingView.alpha = 0
        }
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if let containerView = self.containerView {
            self.dimmingView.frame = containerView.frame
        }
    }

    override func adaptivePresentationStyle(for traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if traitCollection.horizontalSizeClass == .regular {
            return .formSheet
        } else {
            return .custom
        }
    }
}

final class SharePanelTransition: NSObject, UIViewControllerTransitioningDelegate {
    private var currentUserInterfaceStyle: SharePanelTheme = .unspecified

    @available(iOS 13.0, *)
    var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        set {
            self.currentUserInterfaceStyle = SharePanelTheme.convert(from: newValue)
        }
        get {
            return SharePanelTheme.convert(from: currentUserInterfaceStyle)
        }
    }
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController)
        -> UIPresentationController? {
            let sharePanelPresentationController = SharePanelPresentationController(presentedViewController: presented, presenting: presenting)
            if #available(iOS 13.0, *) {
                sharePanelPresentationController.overrideUserInterfaceStyle = SharePanelTheme.convert(from: currentUserInterfaceStyle)
            }
            return sharePanelPresentationController
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            if let horizontalSizeClass = presenting.view.superview?.traitCollection.horizontalSizeClass,
               horizontalSizeClass == .regular {
                return nil
            } else {
                return SharePanelPresentAnimatedTransitioning()
            }
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}

final class SharePanelPresentAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    weak var dimmingView: UIView?

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
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
