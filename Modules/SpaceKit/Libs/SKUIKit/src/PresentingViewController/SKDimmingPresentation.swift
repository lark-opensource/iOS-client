//
//  DimmingPresentation.swift
//  SKUIKit
//
//  Created by zengsenyuan on 2022/6/23.
//  


import UIKit
import UniverseDesignColor

public final class SKDimmingPresentation: UIPresentationController {

    public var isNeedChangeDimmingWhenDismiss: Bool = true
    
    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgMask
        return view
    }()
    
    public override init(presentedViewController: UIViewController,
                         presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    public override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .dimmed
        self.dimmingView.alpha = 0
        self.containerView?.addSubview(self.dimmingView)
        _ = presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1
        }, completion: nil)
    }
    
    public override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .automatic
        if isNeedChangeDimmingWhenDismiss {
            _ = presentedViewController.transitionCoordinator?.animate(alongsideTransition: {_ in
                self.dimmingView.alpha = 0.0
            }, completion: nil)
        }
    }
    
    public override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if let containerView = self.containerView {
            self.dimmingView.frame = containerView.frame
        }
    }
}
