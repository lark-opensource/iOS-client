//
//  UDPresentationController.swift
//  UniverseDesignPopover
//
//  Created by Hayden on 2023/4/13.
//

import UIKit
import UniverseDesignColor

open class UDDimmingPresentationController: UIPresentationController {

    /// 是否展示 Dimming 蒙层
    open var showDimmingView: Bool = true {
        didSet {
            dimmingView.isHidden = !showDimmingView
        }
    }

    /// 是否根据 `SizeClass` 调整 present 样式（`formSheet` / `custom`)
    open var autoTransformPresentationStyle: Bool = false

    /// present 完成回调
    open var presentCompletion: (() -> Void)?

    /// dismiss 完成回调
    open var dismissCompletion: (() -> Void)?

    private lazy var dimmingView: UIView = {
        let dimmingView = UIView()
        dimmingView.backgroundColor = UDColor.bgMask
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        return dimmingView
    }()

    public override init(presentedViewController: UIViewController,
                         presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        if let containerView = containerView {
            // Add the dimming view to the container view
            containerView.addSubview(dimmingView)
            // Set the constraints of the dimming view to fill the container view
            NSLayoutConstraint.activate([
                dimmingView.topAnchor.constraint(equalTo: containerView.topAnchor),
                dimmingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                dimmingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                dimmingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
        }

        // Animate the alpha of the dimming view during the presentation, if possible
        presentingViewController.view.tintAdjustmentMode = .dimmed
        self.dimmingView.alpha = 0.0
        if let transitionCoordinator = presentingViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 1.0
            }, completion: nil)
        } else {
            // If the transition coordinator is nil, add the dimming view without animating its alpha value
            self.dimmingView.alpha = 1.0
        }
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        presentCompletion?()
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentingViewController.view.tintAdjustmentMode = .automatic
        // Animate the alpha of the dimming view during dismissal, if possible
        if let transitionCoordinator = presentingViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 0.0
            }, completion: { _ in
                self.dimmingView.removeFromSuperview()
            })
        } else {
            // If the transition coordinator is nil, remove the dimming view without animating its alpha value
            self.dimmingView.alpha = 0.0
            self.dimmingView.removeFromSuperview()
        }
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        dismissCompletion?()
    }

    open override func adaptivePresentationStyle(for traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if autoTransformPresentationStyle {
            return traitCollection.horizontalSizeClass == .regular ? .formSheet : .custom
        } else {
            return super.adaptivePresentationStyle(for: traitCollection)
        }
    }
}
