//
//  LKAssetBrowserSmoothZoomAnimator.swift
//  LKBaseAssetBrowser
//
//  Created by Hayden Wang on 2022/1/25.
//

import Foundation
import UIKit

/// 更丝滑的Zoom动画
open class LKAssetBrowserSmoothZoomAnimator: NSObject, LKAssetBrowserAnimatedTransitioning {

    public var showDuration: TimeInterval = 0.25

    public var dismissDuration: TimeInterval = 0.25

    public var isNavigationAnimation = false

    public typealias TransitionViewAndFrame = (transitionView: UIView, thumbnailFrame: CGRect)
    public typealias TransitionViewAndFrameProvider = (_ index: Int, _ destinationView: UIView) -> TransitionViewAndFrame?

    /// 获取转场缩放的视图与前置Frame
    public var transitionViewAndFrameProvider: TransitionViewAndFrameProvider = { _, _ in return nil }

    /// 替补的动画方案
    open lazy var substituteAnimator: LKAssetBrowserAnimatedTransitioning = LKAssetBrowserFadeAnimator()

    public init(transitionViewAndFrame: @escaping TransitionViewAndFrameProvider) {
        transitionViewAndFrameProvider = transitionViewAndFrame
    }

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isForShow ? showDuration : dismissDuration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isForShow {
            playShowAnimation(context: transitionContext)
        } else {
            playDismissAnimation(context: transitionContext)
        }
    }

    private func playShowAnimation(context: UIViewControllerContextTransitioning) {
        guard let browser = assetBrowser else {
            context.completeTransition(!context.transitionWasCancelled)
            return
        }
        if isNavigationAnimation,
            let fromView = context.view(forKey: .from),
            let fromViewSnapshot = snapshot(with: fromView),
            let toView = context.view(forKey: .to) {
            toView.insertSubview(fromViewSnapshot, at: 0)
        }
        context.containerView.addSubview(browser.view)

        guard let (transitionView, thumbnailFrame, destinationFrame) = transitionViewAndFrames(with: browser) else {
            // 转为执行替补动画
            substituteAnimator.isForShow = isForShow
            substituteAnimator.assetBrowser = assetBrowser
            substituteAnimator.isNavigationAnimation = isNavigationAnimation
            substituteAnimator.animateTransition(using: context)
            return
        }
        browser.dimmingView.alpha = 0
        browser.galleryView.isHidden = true
        transitionView.frame = thumbnailFrame
        context.containerView.addSubview(transitionView)
        UIView.animate(withDuration: showDuration, animations: {
            browser.dimmingView.alpha = 1.0
            transitionView.frame = destinationFrame
        }, completion: { _ in
            browser.galleryView.isHidden = false
            browser.view.insertSubview(browser.dimmingView, belowSubview: browser.galleryView)
            transitionView.removeFromSuperview()
            context.completeTransition(!context.transitionWasCancelled)
        })
    }

    private func playDismissAnimation(context: UIViewControllerContextTransitioning) {
        guard let browser = assetBrowser else {
            return
        }
        guard let (transitionView, thumbnailFrame, destinationFrame) = transitionViewAndFrames(with: browser) else {
            // 转为执行替补动画
            substituteAnimator.isForShow = isForShow
            substituteAnimator.assetBrowser = assetBrowser
            substituteAnimator.isNavigationAnimation = isNavigationAnimation
            substituteAnimator.animateTransition(using: context)
            return
        }
        browser.galleryView.isHidden = true
        transitionView.frame = destinationFrame
        context.containerView.addSubview(transitionView)
        UIView.animate(withDuration: showDuration, animations: {
            browser.dimmingView.alpha = 0
            transitionView.frame = thumbnailFrame
        }) { _ in
            if let toView = context.view(forKey: .to) {
                context.containerView.addSubview(toView)
            }
            transitionView.removeFromSuperview()
            context.completeTransition(!context.transitionWasCancelled)
        }
    }

    private func transitionViewAndFrames(with browser: LKAssetBrowser) -> (UIView, CGRect, CGRect)? {
        let browserView = browser.galleryView
        let destinationView = browser.view!
        guard let transitionContext = transitionViewAndFrameProvider(browser.currentPageIndex, destinationView) else {
            return nil
        }
        guard let cell = browserView.currentPage as? LKZoomTransitionPage else {
            return nil
        }
        let showContentView = cell.showContentView
        let destinationFrame = showContentView.convert(showContentView.bounds, to: destinationView)
        return (transitionContext.transitionView, transitionContext.thumbnailFrame, destinationFrame)
    }
}
