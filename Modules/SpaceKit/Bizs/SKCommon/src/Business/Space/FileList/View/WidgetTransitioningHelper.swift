//
//  WidgetTransitioningHelper.swift
//  SKCommon
//
//  Created by lizechuang on 2020/8/31.
//

import SKUIKit

class WidgetBrowserPresentTransitioning: NSObject {
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

extension WidgetBrowserPresentTransitioning: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animateDuration
    }

    private func animateTransition(using transitionContext: UIViewControllerContextTransitioning, with toVC: SKWidgetViewController) {
        guard let widgetView = toVC.view else { return }
        self.willPresent?()
        let containerView = transitionContext.containerView

        /// Animation Preferences
        let alpha: CGFloat = 1
        let totalHeight = toVC.contentHeight + toVC.bottomSafeAreaHeight

        /// Animation Alpha Logic
        let alphaAnimatedView = UIView(frame: containerView.frame)
        containerView.addSubview(alphaAnimatedView)
        alphaAnimatedView.backgroundColor = toVC.dismissButton.backgroundColor
        alphaAnimatedView.alpha = 0

        /// Animation Move Logic
        containerView.addSubview(widgetView)
        toVC.view.frame = containerView.frame
        toVC.backgroundView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
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
                        let totalHeight = toVC.contentHeight + toVC.bottomSafeAreaHeight
                        toVC.backgroundView.snp.remakeConstraints { (make) in
                            make.left.right.equalToSuperview()
                            make.height.equalTo(totalHeight)
                            make.bottom.equalTo(0)
                        }
                        toVC.view.layoutIfNeeded()
                        alphaAnimatedView.alpha = alpha
                       }, completion: { _ in
                        self.completion?()
                        alphaAnimatedView.removeFromSuperview()
                        transitionContext.completeTransition(true)
                       })
    }

    private func animateTransition(using transitionContext: UIViewControllerContextTransitioning, with toVC: SKTranslucentWidgetController) {
        guard let widgetView = toVC.view else { return }
        self.willPresent?()
        let containerView = transitionContext.containerView

        /// Animation Preferences
        let alpha: CGFloat = 1
        let totalHeight = toVC.contentHeight + toVC.bottomSafeAreaHeight

        /// Animation Alpha Logic
        let alphaAnimatedView = UIView(frame: containerView.frame)
        containerView.addSubview(alphaAnimatedView)
        alphaAnimatedView.backgroundColor = toVC.dismissButton.backgroundColor
        alphaAnimatedView.alpha = 0

        /// Animation Move Logic
        containerView.addSubview(widgetView)
        toVC.view.frame = containerView.frame
        toVC.backgroundView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
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
                        let totalHeight = toVC.contentHeight + toVC.bottomSafeAreaHeight
                        toVC.backgroundView.snp.remakeConstraints { (make) in
                            make.left.right.equalToSuperview()
                            make.height.equalTo(totalHeight)
                            make.bottom.equalTo(0)
                        }
                        toVC.view.layoutIfNeeded()
                        alphaAnimatedView.alpha = alpha
                       }, completion: { _ in
                        self.completion?()
                        alphaAnimatedView.removeFromSuperview()
                        transitionContext.completeTransition(true)
                       })
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) else {
            assertionFailure()
            return
        }
        if let widgetVC = toVC as? SKWidgetViewController {
            animateTransition(using: transitionContext, with: widgetVC)
        } else if let widgetVC = toVC as? SKTranslucentWidgetController {
            animateTransition(using: transitionContext, with: widgetVC)
        } else {
            assertionFailure()
        }
    }
}

class WidgetBrowserDismissTransitioning: NSObject {
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

extension WidgetBrowserDismissTransitioning: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animateDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .from) else {
            return
        }
        if let widgetVC = toVC as? SKWidgetViewController {
            animateTransition(using: transitionContext, with: widgetVC)
        } else if let widgetVC = toVC as? SKTranslucentWidgetController {
            animateTransition(using: transitionContext, with: widgetVC)
        }
    }

    private func animateTransition(using transitionContext: UIViewControllerContextTransitioning, with toVC: SKWidgetViewController) {
        /// Animation Logic
        let containerView = transitionContext.containerView
        let animatedView = toVC.backgroundView
        let alphaView = toVC.dismissButton
        self.willPresent?()
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
    private func animateTransition(using transitionContext: UIViewControllerContextTransitioning, with toVC: SKTranslucentWidgetController) {
        /// Animation Logic
        let containerView = transitionContext.containerView
        let animatedView = toVC.backgroundView
        let alphaView = toVC.dismissButton
        self.willPresent?()
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
