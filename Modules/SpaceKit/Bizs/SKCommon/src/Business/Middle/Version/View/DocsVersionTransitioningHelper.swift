//
//  DocsVersionTransitioningHelper.swift
//  SKCommon
//
//  Created by GuoXinyi on 2022/9/12.
//

import SKUIKit

class DocsVersionPresentTransitioning: NSObject {
    private let animateDuration: Double
    private let willPresent: (() -> Void)?
    private let animation: (() -> Void)?
    private let completion: (() -> Void)?

    public init(animateDuration: Double,
                willPresent: (() -> Void)? = nil,
                animation: (() -> Void)? = nil,
                completion: (() -> Void)? = nil) {
        self.animateDuration = animateDuration
        self.willPresent = willPresent
        self.animation = animation
        self.completion = completion
        super.init()
    }
}

extension DocsVersionPresentTransitioning: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animateDuration
    }

    private func animateTransition(using transitionContext: UIViewControllerContextTransitioning, with toVC: DocsVersionGraggableViewController) {
        guard let widgetView = toVC.view else { return }
        self.willPresent?()
        let containerView = transitionContext.containerView
        containerView.backgroundColor = .clear
        widgetView.backgroundColor = .clear

        /// Animation Preferences
        let totalHeight = toVC.draggableMinViewHeight

        /// Animation Move Logic
        containerView.addSubview(widgetView)
        toVC.view.frame = containerView.frame
        toVC.containerView.snp.remakeConstraints { (make) in
            if SKDisplay.phone, UIApplication.shared.statusBarOrientation.isLandscape {
                make.width.equalToSuperview().multipliedBy(0.7)
                make.centerX.equalToSuperview()
            } else {
                make.left.right.equalToSuperview()
            }
            make.height.equalTo(totalHeight)
            make.bottom.equalTo(totalHeight)
        }
        toVC.view.layoutIfNeeded()
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.5,
                       options: [],
                       animations: {
                        self.animation?()
                        let totalHeight = toVC.draggableMinViewHeight
                        toVC.containerView.snp.remakeConstraints { (make) in
                            if SKDisplay.phone, UIApplication.shared.statusBarOrientation.isLandscape {
                                make.width.equalToSuperview().multipliedBy(0.7)
                                make.centerX.equalToSuperview()
                            } else {
                                make.left.right.equalToSuperview()
                            }
                            make.height.equalTo(totalHeight)
                            make.bottom.equalTo(0)
                        }
                        toVC.view.layoutIfNeeded()
                       }, completion: { _ in
                        self.completion?()
                        transitionContext.completeTransition(true)
                       })
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) else {
            assertionFailure()
            return
        }
        if let widgetVC = toVC as? DocsVersionGraggableViewController {
            animateTransition(using: transitionContext, with: widgetVC)
        } else {
            assertionFailure()
        }
    }
}

class DocsVersionDismissTransitioning: NSObject {
    private let animateDuration: Double
    private let willDismiss: (() -> Void)?
    private let animation: (() -> Void)?
    private let completion: (() -> Void)?

    public init(animateDuration: Double,
                willDismiss: (() -> Void)? = nil,
                animation: (() -> Void)? = nil,
                completion: (() -> Void)? = nil) {
        self.animateDuration = animateDuration
        self.willDismiss = willDismiss
        self.animation = animation
        self.completion = completion
        super.init()
    }
}

extension DocsVersionDismissTransitioning: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animateDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .from) else {
            return
        }
        if let widgetVC = toVC as? DocsVersionGraggableViewController {
            animateTransition(using: transitionContext, with: widgetVC)
        }
    }

    private func animateTransition(using transitionContext: UIViewControllerContextTransitioning, with toVC: DocsVersionGraggableViewController) {
        /// Animation Logic
        let containerView = transitionContext.containerView
        containerView.backgroundColor = .clear
        let animatedView = toVC.containerView
        let alphaView = toVC.backgroundMaskView
        self.willDismiss?()
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.5,
                       options: [],
                       animations: {
                        self.animation?()
                        animatedView.frame.origin.y = containerView.frame.size.height
                        alphaView.backgroundColor = UIColor.ud.N00.withAlphaComponent(0)
                       }, completion: { _ in
                        self.completion?()
                        transitionContext.completeTransition(true)
                       })
    }
}
