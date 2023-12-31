//
//  InlineAIPanelTransitioningHelper.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/4/25.
//

import Foundation
import UIKit

class InlineAIPanelPresentTransitioning: NSObject {
    private let animateDuration: Double
    private let willPresent: (() -> Void)?
    private let animation: (() -> Void)?
    private let completion: (() -> Void)?

    init(animateDuration: Double,
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

extension InlineAIPanelPresentTransitioning: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animateDuration
    }

    private func animateTransition(using transitionContext: UIViewControllerContextTransitioning, with toVC: InlineAIPanelViewGragableViewController) {
        guard let widgetView = toVC.view else { return }
        self.willPresent?()
        let containerView = transitionContext.containerView
        containerView.backgroundColor = .clear
        widgetView.backgroundColor = .clear
        
        /// Animation Preferences
        let totalHeight = toVC.defaultHeight
        let offsetBottom: CGFloat =  32
        
        /// Animation Move Logic
        containerView.addSubview(widgetView)
        toVC.view.frame = containerView.frame
        toVC.currentContainerView().frame = CGRect(x: 6, y: containerView.frame.size.height, width: toVC.view.frame.size.width - 12, height: totalHeight)
        let duration = self.transitionDuration(using: transitionContext)
        if duration == 0 {
            self.animation?()
            toVC.currentContainerView().frame = CGRect(x: 6, y: containerView.frame.size.height - totalHeight - offsetBottom, width: toVC.view.frame.size.width - 16, height: totalHeight)
            self.completion?()
            transitionContext.completeTransition(true)
        } else {
            UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                           delay: 0,
                           usingSpringWithDamping: 0.85,
                           initialSpringVelocity: 0.5,
                           options: [],
                           animations: {
                self.animation?()
                toVC.currentContainerView().frame = CGRect(x: 6, y: containerView.frame.size.height - totalHeight - offsetBottom, width: toVC.view.frame.size.width - 16, height: totalHeight)
           }, completion: { _ in
                self.completion?()
                transitionContext.completeTransition(true)
           })
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) else {
            assertionFailure()
            return
        }
        if let widgetVC = toVC as? InlineAIPanelViewGragableViewController {
            animateTransition(using: transitionContext, with: widgetVC)
        } else {
            assertionFailure()
        }
    }
}

class InlineAIPanelDismissTransitioning: NSObject {
    private let animateDuration: Double
    private let overwritingDismiss: Bool
    private let willDismiss: (() -> Void)?
    private let animation: (() -> Void)?
    private let completion: (() -> Void)?

    init(animateDuration: Double,
         overwritingDismiss: Bool = false,
         willDismiss: (() -> Void)? = nil,
         animation: (() -> Void)? = nil,
         completion: (() -> Void)? = nil) {
        self.animateDuration = animateDuration
        self.overwritingDismiss = overwritingDismiss
        self.willDismiss = willDismiss
        self.animation = animation
        self.completion = completion
        super.init()
    }
}

extension InlineAIPanelDismissTransitioning: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animateDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .from) else {
            return
        }
        if let widgetVC = toVC as? InlineAIPanelViewGragableViewController {
            animateTransition(using: transitionContext, with: widgetVC)
        }
    }

    private func animateTransition(using transitionContext: UIViewControllerContextTransitioning, with toVC: InlineAIPanelViewGragableViewController) {
        /// Animation Logic
        let containerView = transitionContext.containerView
        containerView.backgroundColor = .clear
        let animatedView = toVC.currentContainerView()
        self.willDismiss?()
        let duration: TimeInterval = max(self.transitionDuration(using: transitionContext), 0.25)
        UIView.animate(withDuration: duration, animations: {
            self.animation?()
            if !self.overwritingDismiss {
                animatedView.frame.origin.y = containerView.frame.size.height
            }
            animatedView.layoutIfNeeded()
          }, completion: { _ in
            self.completion?()
            transitionContext.completeTransition(true)
        })
    }
}
