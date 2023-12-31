//Included OSS: SDCAlertView
//Copyright (c) 2013 Scott Berrevoets
//spdx license identifier: MIT
//This file may have been modified by Beijing Feishu Technology Co., Ltd.

import UIKit

class PickerPresentationController: UIPresentationController {

    private let dimmingView = UIView()

    override init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.dimmingView.backgroundColor = UIColor(white: 0, alpha: 0.3)
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .dimmed
        self.dimmingView.alpha = 0
        self.containerView?.addSubview(self.dimmingView)
        let coordinator = self.presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 1 })
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .automatic
        let coordinator = self.presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 0 }, completion: nil)
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if let containerView = self.containerView {
            self.dimmingView.frame = containerView.frame
        }
    }
}
