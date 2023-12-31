//
//  FocusOnboardingController.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/22.
//

import Foundation
import UIKit
import UniverseDesignButton
import LarkContainer

final class FocusOnboardingController: UIViewController, ActionSheetPresentable, UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy private var focusManager: FocusManager?

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum ViewType {
        case alert
        case actionPanel
    }

    var onSyncSettingTapped: (() -> Void)?

    private var didTapSyncSettingButton: (() -> Void)?

//    private var transitionManager = GenericActionSheetTransitionManager()
    private var transitionManager = FocusOnboardingTransition()

    lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.cornerRadius = 16
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.text = BundleI18n.LarkFocus.Lark_Profile_PersonalStatusUpgrade
        return label
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 28
        return stack
    }()

    lazy var confirmButton: UDButton = {
        var config = UDButton.primaryBlue.config
        config.type = .big
        let button = UDButton(config)
        button.setTitle(BundleI18n.LarkFocus.Lark_Guide_BannerButtonNewUserNavigation, for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentStack)
        contentView.addSubview(confirmButton)
        contentView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(22)
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.trailing.equalToSuperview().offset(-Cons.hMargin)
        }
        confirmButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
            make.leading.trailing.equalTo(titleLabel)
        }
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(28)
            make.bottom.equalTo(confirmButton.snp.top).offset(-28)
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.trailing.equalToSuperview().offset(-Cons.hMarginRight)
        }
        focusManager?.dataService.openMeetingSync()

        modalPresentationStyle = .custom
        transitioningDelegate = transitionManager
//        preferredContentSize = CGSize(width: 400, height: 600)
        confirmButton.addTarget(self, action: #selector(didTapConfirmButton), for: .touchUpInside)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBackgroundView(_:))))
        didTapSyncSettingButton = { [weak self] in
            self?.dismiss(animated: true, completion: {
                self?.onSyncSettingTapped?()
            })
        }
        addContentItems()
    }

    private func addContentItems() {
        let item1 = FocusOnboardingItemView()
        item1.set(
            icon: BundleResources.LarkFocus.onboarding_custom,
            title: BundleI18n.LarkFocus.Lark_Profile_DifferentStatus,
            detail: BundleI18n.LarkFocus.Lark_Profile_DifferentStatusDesc
        )
        let item2 = FocusOnboardingItemView()
        item2.set(
            icon: BundleResources.LarkFocus.onboarding_mute,
            title: BundleI18n.LarkFocus.Lark_Profile_StatusDoNotDisturb,
            detail: BundleI18n.LarkFocus.Lark_Profile_StatusDoNotDisturbDesc
        )
        let item3 = FocusOnboardingItemView()
        item3.set(
            icon: BundleResources.LarkFocus.onboarding_sync,
            title: BundleI18n.LarkFocus.Lark_Profile_AutoSyncMeetingLeaveStatus,
            detail: BundleI18n.LarkFocus.Lark_Profile_AutoSyncMeetingLeaveStatusDesc,
            tappableText: BundleI18n.LarkFocus.Lark_Profile_ModifySyncSettings,
            tapHandler: didTapSyncSettingButton
        )
        contentStack.addArrangedSubview(item1)
        contentStack.addArrangedSubview(item2)
        contentStack.addArrangedSubview(item3)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.bounds.width > 600 {
            contentView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
        } else {
            contentView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner
            ]
        }
    }

    @objc
    private func didTapBackgroundView(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if contentView.frame.contains(location) {
            return
        }
        dismiss(animated: true)
    }

    @objc
    private func didTapConfirmButton() {
        dismiss(animated: true)
    }

    enum Cons {
        static var hMargin: CGFloat { 20 }
        static var hMarginRight: CGFloat { 16 }
    }
}

// MARK: - Transition

final class GenericActionSheetTransitionManager: NSObject, UIViewControllerTransitioningDelegate {

    var transitionDuration: TimeInterval = 0.2

    let animator = GenericActionSheetTransitionAnimator(transitionType: .present)

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.type = .present
        animator.transitionDuration = transitionDuration
        return animator
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.type = .dismiss
        animator.transitionDuration = transitionDuration
        return animator
    }

}

final class GenericActionSheetTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    var transitionDuration: TimeInterval = 0.2

    enum TransitionType {
        case present
        case dismiss
    }

    var type: TransitionType

    init(transitionType: TransitionType) {
        type = transitionType
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        switch type {
        case .present:  return transitionDuration
        case .dismiss:  return transitionDuration
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch type {
        case .present:  present(transitionContext)
        case .dismiss:  dismiss(transitionContext)
        }
    }

    private func present(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let toController = transitionContext.viewController(forKey: .to) as? ActionSheetPresentable else { return }
        toController.view.alpha = 0
        toController.view.frame = transitionContext.finalFrame(for: toController)
        transitionContext.containerView.addSubview(toController.view)
        transitionContext.containerView.layoutIfNeeded()
        let contentHeight = toController.contentView.frame.height
        toController.contentView.transform = CGAffineTransform(translationX: 0, y: contentHeight)
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: {
            toController.view.alpha = 1
            toController.contentView.transform = .identity
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

    private func dismiss(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let fromController = transitionContext.viewController(forKey: .from) as? ActionSheetPresentable else { return }
        let duration = transitionDuration(using: transitionContext)
        transitionContext.containerView.addSubview(fromController.view)
        let contentHeight = fromController.contentView.frame.height
        UIView.animate(withDuration: duration, animations: {
            fromController.view.alpha = 0
            fromController.contentView.transform = CGAffineTransform(translationX: 0, y: contentHeight)
        }, completion: { _ in
            fromController.view.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

protocol ActionSheetPresentable: UIViewController {

    var contentView: UIView { get }
}
