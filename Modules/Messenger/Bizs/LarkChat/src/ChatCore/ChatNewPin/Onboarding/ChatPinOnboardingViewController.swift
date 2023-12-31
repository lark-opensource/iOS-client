//
//  ChatPinOnboardingViewController.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/10/30.
//

import Foundation
import FigmaKit
import UniverseDesignColor
import UniverseDesignShadow
import UniverseDesignIcon
import EENavigator
import LarkSDKInterface
import LarkModel

final class ChatPinOnboardingViewController: UIViewController {

    final class TapBackgroundView: UIView {
        private let tapHandler: () -> Void

        init(tapHandler: @escaping () -> Void) {
            self.tapHandler = tapHandler
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.tapHandler()
            super.touchesBegan(touches, with: event)
        }
    }

    weak var sourceView: UIView?
    lazy var tapBackgroundView: UIView = {
        let tapBackgroundView = TapBackgroundView(tapHandler: { [weak self] in
            self?.dismiss(animated: true)
        })
        return tapBackgroundView
    }()

    private let userGeneralSettings: UserGeneralSettings?
    private let nav: Navigatable
    private weak var targetVC: UIViewController?
    private let chat: Chat

    init(sourceView: UIView,
         targetVC: UIViewController?,
         userGeneralSettings: UserGeneralSettings?,
         nav: Navigatable,
         chat: Chat) {
        self.sourceView = sourceView
        self.targetVC = targetVC
        self.userGeneralSettings = userGeneralSettings
        self.nav = nav
        self.chat = chat
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var shadowBackgroundView: UIView = {
        let shadowBackgroundView = UIView()
        shadowBackgroundView.backgroundColor = UIColor.ud.bgFloat
        shadowBackgroundView.layer.ud.setShadow(type: .s5Down)
        shadowBackgroundView.layer.cornerRadius = ChatPinOnboardingView.containerCornerRadius
        return shadowBackgroundView
    }()

    private lazy var onboardingView: ChatPinOnboardingView = {
        let onboardingView = ChatPinOnboardingView(
            detailLinkConfig: self.userGeneralSettings?.chatPinOnboardingDetailLinkConfig,
            targetVC: self.targetVC,
            nav: self.nav,
            chat: chat,
            isFromInfo: true
        )
        onboardingView.layer.borderWidth = 1
        onboardingView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        return onboardingView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.clear
        self.view.addSubview(shadowBackgroundView)
        self.view.addSubview(onboardingView)
        shadowBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        onboardingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.dismiss(animated: true)
    }

}

extension ChatPinOnboardingViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ChatPinOnboardingPresentTransition()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ChatPinOnboardingDismissTransition()
    }
}

final class ChatPinOnboardingPresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
              let onboardingVC = toVC as? ChatPinOnboardingViewController,
              let sourceView = onboardingVC.sourceView else {
                transitionContext.completeTransition(false)
                return
        }
        transitionContext.containerView.addSubview(onboardingVC.tapBackgroundView)
        transitionContext.containerView.addSubview(onboardingVC.view)

        let containerPadding: CGFloat = 16
        let vcWidth: CGFloat = min(transitionContext.containerView.bounds.width, 375) - containerPadding * 2
        let sourceRect = sourceView.convert(sourceView.bounds, to: transitionContext.containerView)
        onboardingVC.tapBackgroundView.frame = transitionContext.containerView.bounds
        onboardingVC.view.snp.makeConstraints { make in
            make.width.equalTo(vcWidth)
            make.centerX.equalToSuperview().offset(sourceRect.centerX - transitionContext.containerView.bounds.centerX)
            make.top.equalToSuperview().inset(sourceRect.maxY + 4)
        }
        onboardingVC.view.layoutIfNeeded()
        onboardingVC.view.alpha = 0

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                onboardingVC.view.alpha = 1
            },
            completion: { transitionContext.completeTransition($0) }
        )
    }
}

final class ChatPinOnboardingDismissTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let onboardingVC = fromVC as? ChatPinOnboardingViewController else {
                transitionContext.completeTransition(false)
                return
        }

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                onboardingVC.view.alpha = 0
            },
            completion: { transitionContext.completeTransition($0) }
        )
    }
}

final class ChatPinOnboardingCollectionViewCell: ChatPinListCardBaseCell {

    static var reuseIdentifier: String { return String(describing: ChatPinOnboardingCollectionViewCell.self) }

    private lazy var onboardingView: ChatPinOnboardingView = {
        let onboardingView = ChatPinOnboardingView(
            showClose: true,
            isFromInfo: false
        )
        return onboardingView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        containerView.layer.borderWidth = 1
        containerView.layer.ud.setBorderColor( UIColor.ud.bgFloat)
        self.containerView.addSubview(onboardingView)
        onboardingView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
    }

    func updateAndLayout(targetVC: UIViewController?, nav: Navigatable, chat: Chat, detailLinkConfig: ChatPinOnboardingDetailLinkConfig?, closeHandler: @escaping () -> Void) -> CGFloat {
        onboardingView.update(targetVC: targetVC, nav: nav, chat: chat, detailLinkConfig: detailLinkConfig, closeHandler: closeHandler)
        onboardingView.layoutIfNeeded()
        return onboardingView.bounds.height + ContainerUIConfig.verticalMargin * 2
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
