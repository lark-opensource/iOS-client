//
//  LKAssetBrowserFadeAnimator.swift
//  LKBaseAssetBrowser
//
//  Created by Hayden Wang on 2022/1/25.
//

import Foundation
import UIKit

open class LKAssetBrowserFadeAnimator: NSObject, LKAssetBrowserAnimatedTransitioning {

    open var showDuration: TimeInterval = 0.25

    open var dismissDuration: TimeInterval = 0.25

    open var isNavigationAnimation: Bool = false

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isForShow ? showDuration : dismissDuration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let browser = assetBrowser else {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }
        if isNavigationAnimation, isForShow,
            let fromView = transitionContext.view(forKey: .from),
            let fromViewSnapshot = snapshot(with: fromView),
            let toView = transitionContext.view(forKey: .to) {
            toView.insertSubview(fromViewSnapshot, at: 0)
        }
        if isForShow {
            browser.dimmingView.alpha = 0
            browser.galleryView.alpha = 0
            if let toView = transitionContext.view(forKey: .to) {
                transitionContext.containerView.addSubview(toView)
            }
        } else {
            if isNavigationAnimation,
                let fromView = transitionContext.view(forKey: .from),
                let toView = transitionContext.view(forKey: .to) {
                transitionContext.containerView.insertSubview(toView, belowSubview: fromView)
            }
        }
        browser.galleryView.isHidden = true
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            browser.galleryView.isHidden = false
            browser.dimmingView.alpha = self.isForShow ? 1.0 : 0
            browser.galleryView.alpha = self.isForShow ? 1.0 : 0
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
