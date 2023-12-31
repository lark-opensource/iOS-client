//
//  RisingController.swift
//  Calendar
//
//  Created by zhuchao on 2019/5/22.
//

// Included OSS: SDCAlertView
// Copyright (c) 2013 Scott Berrevoets
// spdx license identifier: MIT License

import UIKit
import Foundation
import CalendarFoundation
import LarkUIKit

protocol RisingViewRelayoutProtocol {
    func relayout(newWidth: CGFloat)
}

class RisingView: UIView, RisingViewRelayoutProtocol {
    func relayout(newWidth: CGFloat) {
        fatalError("Must Override")
    }
}

final class RisingController: UIViewController {

    private let transition = Transition()

    /// 点击背景区域dismiss回掉
    var dismissedByTapOutside: (() -> Void)?

    private let contentView: RisingView

    init(contentView: RisingView) {
        self.contentView = contentView
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = transition
        self.modalPresentationStyle = .custom
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] (_) in
            guard Display.pad else {
                return
            }
            self?.contentView.relayout(newWidth: size.width)
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutContentView(contentView)
        addTapGesture()
    }

    private func layoutContentView(_ view: UIView) {
        self.view.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }

    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
    }

    @objc
    private func tapped(_ sender: UITapGestureRecognizer) {
        if !self.contentView.frame.contains(sender.location(in: self.view)) {
            self.dismiss(animated: true, completion: nil)
            dismissedByTapOutside?()
        }
    }

}

private final class PresentationController: UIPresentationController {
    private let dimmingView = UIView()

    override init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.dimmingView.backgroundColor = UIColor.ud.bgMask
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .dimmed
        self.dimmingView.alpha = 0
        self.containerView?.addSubview(self.dimmingView)
        let coordinator = self.presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 1 }, completion: nil)
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

private final class Transition: NSObject, UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController)
        -> UIPresentationController? {
            return PresentationController(presentedViewController: presented, presenting: presenting)
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
