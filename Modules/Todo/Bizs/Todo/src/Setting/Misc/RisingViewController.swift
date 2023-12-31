//
//  RisingViewController.swift
//  Todo
//
//  Created by 白言韬 on 2021/2/24.
//
//  Included OSS: SDCAlertView
//  Copyright (c) 2013 Scott
//  spdx license identifier: MIT

import Foundation
import UniverseDesignFont

/// 半屏弹窗，带有蒙层处理
class RisingViewController: UIViewController {

    private let transition = Transition()

    var confirmHandler: (() -> Void)?
    var cancelHandler: (() -> Void)?

    private let contentView: UIView

    private let containerView = UIView()

    private let customTitle: String

    init(contentView: UIView, customTitle: String) {
        self.contentView = contentView
        self.customTitle = customTitle
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = transition
        self.modalPresentationStyle = .custom
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        containerView.backgroundColor = UIColor.ud.bgBodyOverlay
        view.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
        }

        layoutContentView()
        layoutTitleBar()
        addOutsideDismissedTapGesture()
    }

    private func layoutContentView() {
        containerView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
        }
    }

    private func layoutTitleBar() {
        let titleBar = UIView()
        let cancelButton = UIButton()
        let titleLabel = UILabel()
        let completeButton = UIButton()

        containerView.lu.addCorner(
            corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner],
            cornerSize: CGSize(width: 12, height: 12)
        )
        containerView.clipsToBounds = true
        containerView.addSubview(titleBar)
        titleBar.addSubview(cancelButton)
        titleBar.addSubview(titleLabel)
        titleBar.addSubview(completeButton)

        cancelButton.titleLabel?.font = UDFont.systemFont(ofSize: 16)
        cancelButton.setTitle(I18N.Todo_Common_Cancel, for: .normal)
        cancelButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelAction(_:)), for: .touchUpInside)
        cancelButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleLabel.text = customTitle
        titleLabel.font = UDFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.textAlignment = .center

        completeButton.titleLabel?.font = UDFont.systemFont(ofSize: 16, weight: .medium)
        completeButton.setTitle(I18N.Todo_Common_DoneButton, for: .normal)
        completeButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        completeButton.addTarget(self, action: #selector(confirmAction(_:)), for: .touchUpInside)
        completeButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleBar.snp.makeConstraints {
            $0.height.equalTo(54)
            $0.top.left.right.equalToSuperview()
            $0.bottom.equalTo(contentView.snp_topMargin)
        }
        cancelButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        completeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints {
            $0.left.greaterThanOrEqualTo(cancelButton.snp.right).offset(8)
            $0.centerX.centerY.equalToSuperview()
            $0.right.lessThanOrEqualTo(completeButton.snp.left).offset(-8)
        }

    }

    @objc
    private func cancelAction(_ sender: UIButton) {
        cancelHandler?()
        dismiss(animated: true, completion: nil)
    }

    @objc
    private func confirmAction(_ sender: UIButton) {
        confirmHandler?()
        dismiss(animated: true, completion: nil)
    }

    private func addOutsideDismissedTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedOutside(_:)))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
    }

    @objc
    private func tappedOutside(_ sender: UITapGestureRecognizer) {
        if !self.containerView.frame.contains(sender.location(in: self.view)) {
            self.dismiss(animated: true, completion: nil)
        }
    }

}

private class Transition: NSObject, UIViewControllerTransitioningDelegate {

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

private class PresentationController: UIPresentationController {
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
