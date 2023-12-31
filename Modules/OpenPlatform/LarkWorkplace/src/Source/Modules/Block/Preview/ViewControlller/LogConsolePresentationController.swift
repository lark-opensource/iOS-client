//
//  LogConsolePresentationController.swift
//  LarkWorkplace
//
//  Created by chenziyi on 2021/7/21.
//

import UIKit

final class LogConsolePresentationController: UIPresentationController {

    private var dimmingView = UIView()

    private var originY: CGFloat = 0

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        setupDimmingView()
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let bounds = containerView?.bounds else {
            return .zero
        }

        // 调试面板弹窗占全屏 3/4
        return CGRect(x: 0, y: bounds.height / 4, width: bounds.width, height: 3 * bounds.height / 4)
    }

    override func presentationTransitionWillBegin() {
        self.containerView?.insertSubview(dimmingView, at: 0)
        self.containerView?.addGestureRecognizer(
            UIPanGestureRecognizer(
                target: self,
                action: #selector(panGestureMethod)
            )
        )

        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|[dimmingView]|",
                options: [],
                metrics: nil,
                views: ["dimmingView": dimmingView]
            )
        )

        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[dimmingView]|",
                options: [],
                metrics: nil,
                views: ["dimmingView": dimmingView]
            )
        )

        if let coordinator = presentedViewController.transitionCoordinator {

            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 1.0
            })
        } else {
            self.dimmingView.alpha = 1.0
            return
        }
    }

    override func dismissalTransitionWillBegin() {
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 0.0
            })
        } else {
            self.dimmingView.alpha = 0.0
            return
        }
    }

    private func setupDimmingView() {
        // swiftlint:disable init_color_with_token
        dimmingView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        // swiftlint:enable init_color_with_token
        dimmingView.alpha = 0.0
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapDimmingView)))
    }

    @objc func tapDimmingView() {
        self.presentedViewController.dismiss(animated: true, completion: nil)
    }

    @objc func panGestureMethod(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.presentedView)
        switch gesture.state {
        case .began:
            originY = presentedViewController.view.frame.origin.y
        case .changed:
            if translation.y > 0 {
                self.presentedViewController.view.frame.origin.y = originY + translation.y
            }
        case .ended:
            // 弹窗上下拖动处理
            if gesture.velocity(in: self.presentedView).y > 0.0 {
                self.presentedViewController.dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.presentedViewController.view.frame.origin.y = self.originY
                }, completion: nil)
            }
        default:
            break
        }
    }
}
