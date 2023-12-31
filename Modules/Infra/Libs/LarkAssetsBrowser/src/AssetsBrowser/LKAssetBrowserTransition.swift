//
//  LKAssetBrowserTransition.swift
//  LarkAssetsBrowser
//
//  Created by Saafo on 2022/2/16.
//

import Foundation
import UIKit
import LarkExtensions
import LarkUIKit

public protocol LKAssetBrowserVCProtocol: UIViewController {
    var currentThumbnail: UIImageView? { get }
    var currentPageView: LKAssetPageView? { get }
    // TODO: Useless, remove later.
    var backScrollView: UIScrollView! { get }
}
extension LKAssetBrowserViewController: LKAssetBrowserVCProtocol {}

/// AssetBrowser 自定义动画提供者
public protocol LKAssetBrowserTransitionProvider: AnyObject {
    func presentAnimationDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval?
    func dismissAnimationDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval?
    /// 进入动画
    /// - Note: 调用 coordinator 来定制动画结束态及完成态
    func presentAnimation(using transitionContext: UIViewControllerContextTransitioning,
                          fromView: UIView,
                          toFrame: CGRect,
                          coordinator: LKAssetBrowserTransitionCoordinator) -> Bool
    /// 退出动画
    /// - Note: 调用 coordinator 来定制动画结束态及完成态
    func dismissAnimation(using transitionContext: UIViewControllerContextTransitioning,
                          fromFrame: CGRect,
                          toView: UIView,
                          coordinator: LKAssetBrowserTransitionCoordinator) -> Bool
}

public extension LKAssetBrowserTransitionProvider {
    func presentAnimationDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval? {
        return 0.2
    }
    func dismissAnimationDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval? {
        return 0.2
    }
}

/// BaseImageViewWrapper 动画专用
public final class BaseImageViewWrapperTransition: LKAssetBrowserTransitionProvider {
    public func presentAnimation(using transitionContext: UIViewControllerContextTransitioning,
                          fromView: UIView,
                          toFrame: CGRect,
                          coordinator: LKAssetBrowserTransitionCoordinator) -> Bool {
        guard let imageWrapper = fromView.superview as? BaseImageViewWrapper,
              let imageView = fromView as? BaseImageView,
              let imageSize = imageView.image?.size else { return false }
        let containerView = transitionContext.containerView
        let animatedImageView = UIImageView(frame: imageView.frame)
        animatedImageView.image = imageView.image
        animatedImageView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        let animatedImageViewContainer = UIView(frame: imageWrapper.convert(imageWrapper.bounds, to: containerView))
        animatedImageViewContainer.addSubview(animatedImageView)
        animatedImageViewContainer.clipsToBounds = true
        containerView.addSubview(animatedImageViewContainer)
        coordinator.animate(alongsideTransition: {
            animatedImageView.frame = CGRect(origin: .zero, size: toFrame.size)
            animatedImageViewContainer.frame = toFrame
        }, completion: {
            animatedImageViewContainer.removeFromSuperview()
        })
        return true
    }
    public func dismissAnimation(using transitionContext: UIViewControllerContextTransitioning,
                          fromFrame: CGRect,
                          toView: UIView,
                          coordinator: LKAssetBrowserTransitionCoordinator) -> Bool {
        guard let imageWrapper = toView.superview as? BaseImageViewWrapper,
              let imageView = toView as? BaseImageView,
              let imageSize = imageView.image?.size else { return false }
        let containerView = transitionContext.containerView
        let animatedImageView = UIImageView(frame: CGRect(origin: .zero, size: fromFrame.size))
        animatedImageView.image = imageView.image
        imageView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        let animatedImageViewContainer = UIView(frame: fromFrame)
        animatedImageViewContainer.addSubview(animatedImageView)
        animatedImageViewContainer.clipsToBounds = true
        containerView.addSubview(animatedImageViewContainer)
        coordinator.animate(alongsideTransition: {
            animatedImageView.frame = imageView.frame
            animatedImageViewContainer.frame = imageWrapper.convert(imageWrapper.bounds, to: containerView)
        }, completion: {
            animatedImageViewContainer.removeFromSuperview()
        })
        return true
    }
    public init() {}
}


/// AssetBrowser 过渡动画协调器
public final class LKAssetBrowserTransitionCoordinator {
    var animations = [() -> Void]()
    var completions = [() -> Void]()
    /// 定制动画结束态及完成态的状态
    public func animate(alongsideTransition animation: @escaping () -> Void,
                        completion: @escaping () -> Void) {
        animations.append(animation)
        completions.append(completion)
    }
    func animate() {
        animations.forEach { $0() }
        animations = []
    }
    func complete() {
        completions.forEach { $0() }
        completions = []
    }
}

/// AssetBrowser 的进入退出过渡动画
public final class LKAssetBrowserTransition {

    public var provider: LKAssetBrowserTransitionProvider?

    public var present: UIViewControllerAnimatedTransitioning {
        Transitioning(duration: presentDuration, animation: presentAnimation)
    }

    public var dismiss: UIViewControllerAnimatedTransitioning {
        Transitioning(duration: dismissDuration, animation: dismissAnimation)
    }

    /// - Parameter provider: 如果需要自定义过渡动画，传入 Provider
    public init(with provider: LKAssetBrowserTransitionProvider? = nil) {
        self.provider = provider
    }

    private lazy var presentDuration: ((UIViewControllerContextTransitioning?) -> TimeInterval) = { [weak self] in
        self?.presentAnimationDuration(using: $0, custom: self?.provider) ?? 0.2
    }

    private lazy var dismissDuration: ((UIViewControllerContextTransitioning?) -> TimeInterval) = { [weak self] in
        self?.dismissAnimationDuration(using: $0, custom: self?.provider) ?? 0.2
    }

    private lazy var presentAnimation: ((UIViewControllerContextTransitioning) -> Void) = { [weak self] in
        self?.presentAnimation(using: $0, custom: self?.provider)
    }

    private lazy var dismissAnimation: ((UIViewControllerContextTransitioning) -> Void) = { [weak self] in
        self?.dismissAnimation(using: $0, custom: self?.provider)
    }

    private final class Transitioning: NSObject, UIViewControllerAnimatedTransitioning {
        var duration: (UIViewControllerContextTransitioning?) -> TimeInterval
        var animation: ((UIViewControllerContextTransitioning) -> Void)

        init(duration: @escaping (UIViewControllerContextTransitioning?) -> TimeInterval,
             animation: @escaping (UIViewControllerContextTransitioning) -> Void) {
            self.duration = duration
            self.animation = animation
        }

        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            self.duration(transitionContext)
        }

        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            self.animation(transitionContext)
        }
    }
}

// MARK: Animation Skeleton

extension LKAssetBrowserTransition {

    func presentAnimationDuration(using transitionContext: UIViewControllerContextTransitioning?,
                                  custom provider: LKAssetBrowserTransitionProvider? = nil) -> TimeInterval {
        provider?.presentAnimationDuration(using: transitionContext) ?? 0.2
    }

    func dismissAnimationDuration(using transitionContext: UIViewControllerContextTransitioning?,
                                  custom provider: LKAssetBrowserTransitionProvider? = nil) -> TimeInterval {
        provider?.dismissAnimationDuration(using: transitionContext) ?? 0.2
    }

    func presentAnimation(using transitionContext: UIViewControllerContextTransitioning,
                          custom provider: LKAssetBrowserTransitionProvider? = nil) {
        guard let toVC = transitionContext.viewController(forKey: .to),
              let broserVC = ((toVC as? UINavigationController)?.viewControllers.last ?? toVC) as? LKAssetBrowserVCProtocol else {
                  transitionContext.completeTransition(false)
                  return
              }

        let containerView = transitionContext.containerView
        containerView.backgroundColor = UIColor.black
        let duration = self.presentAnimationDuration(using: transitionContext, custom: provider)

        guard let thumbnail = broserVC.currentThumbnail, let imageSize = thumbnail.image?.size else {
            containerView.backgroundColor = UIColor.black.withAlphaComponent(0)
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: .curveLinear,
                           animations: {
                containerView.backgroundColor = UIColor.black
            }, completion: { _ in
                containerView.backgroundColor = UIColor.clear
                containerView.addSubview(toVC.view)
                toVC.view.frame = containerView.bounds
                transitionContext.completeTransition(true)
            })
            return
        }

        var priorityHorizontalFullScreen = false
        if let zoomingView = broserVC.currentPageView as? LKPhotoZoomingScrollView {
            priorityHorizontalFullScreen = zoomingView.priorityHorizontalFullScreen
        }

        let zoomScale = LKPhotoZoomingScrollView.getMinimumZoomScale(
            forBounds: containerView.bounds.size,
            imageSize: imageSize,
            preferHorizontalFullScreen: priorityHorizontalFullScreen
        )
        let targetFrame = LKPhotoZoomingScrollView.getCentralizedFrame(
            size: imageSize * zoomScale,
            boundsSize: containerView.bounds.size
        )

        let coordinator = LKAssetBrowserTransitionCoordinator()
        if let provider = provider,
           provider.presentAnimation(using: transitionContext,
                                     fromView: thumbnail,
                                     toFrame: targetFrame,
                                     coordinator: coordinator) {
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: .curveLinear,
                           animations: {
                coordinator.animate()
            }, completion: { _ in
                containerView.backgroundColor = UIColor.clear
                coordinator.complete()
                containerView.addSubview(toVC.view)
                toVC.view.frame = containerView.bounds
                transitionContext.completeTransition(true)
            })
        } else {
            let animatedImageView = UIImageView(frame: thumbnail.frame)
            animatedImageView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
            animatedImageView.contentMode = .scaleAspectFill
            animatedImageView.clipsToBounds = true
            animatedImageView.image = thumbnail.image
            animatedImageView.frame = thumbnail.convert(thumbnail.bounds, to: containerView)
            containerView.addSubview(animatedImageView)
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: .curveLinear,
                           animations: {
                animatedImageView.frame = targetFrame
            }, completion: { _ in
                containerView.backgroundColor = UIColor.clear
                animatedImageView.removeFromSuperview()
                containerView.addSubview(toVC.view)
                toVC.view.frame = containerView.bounds
                transitionContext.completeTransition(true)
            })
        }
    }

    func dismissAnimation(using transitionContext: UIViewControllerContextTransitioning,
                          custom provider: LKAssetBrowserTransitionProvider? = nil) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let browseVC = ((fromVC as? UINavigationController)?.viewControllers.last ?? fromVC) as? LKAssetBrowserVCProtocol,
              let toVC = transitionContext.viewController(forKey: .to),
              let pageView = browseVC.currentPageView else {
                  return
              }
        let containerView = transitionContext.containerView
        let duration = self.dismissAnimationDuration(using: transitionContext, custom: provider)

        guard let thumbnail = browseVC.currentThumbnail, viewIsShow(in: toVC, view: thumbnail) else {
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: .curveLinear,
                           animations: {
                containerView.alpha = 0
            }, completion: { _ in
                fromVC.view.removeFromSuperview()
                transitionContext.completeTransition(true)
            })
            return
        }

        browseVC.currentPageView?.isHidden = true

        let coordinator = LKAssetBrowserTransitionCoordinator()
        if let provider = provider,
           provider.dismissAnimation(using: transitionContext,
                                     fromFrame: pageView.dismissFrame,
                                     toView: thumbnail,
                                     coordinator: coordinator) {
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: .curveLinear,
                           animations: {
                coordinator.animate()
                fromVC.view.alpha = 0

            }, completion: { _ in
                fromVC.view.alpha = 1
                coordinator.complete()
                browseVC.currentPageView?.isHidden = false
                transitionContext.completeTransition(true)
            })
        } else {
            let animatedImageView = UIImageView(frame: pageView.dismissFrame)
            animatedImageView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
            animatedImageView.contentMode = thumbnail.contentMode
            animatedImageView.clipsToBounds = true
            animatedImageView.image = pageView.dismissImage
            containerView.addSubview(animatedImageView)

            let targetFrame = thumbnail.convert(thumbnail.bounds, to: containerView)

            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: .curveLinear,
                           animations: {
                animatedImageView.frame = targetFrame
                fromVC.view.alpha = 0
            }, completion: { _ in
                fromVC.view.alpha = 1
                browseVC.currentPageView?.isHidden = false
                transitionContext.completeTransition(true)
            })
        }
    }

    private func viewIsShow(in target: UIViewController, view: UIView) -> Bool {
        var superView = view.superview
        while superView != nil {
            if superView == target.view {
                return true
            } else {
                superView = superView?.superview
            }
        }
        return false
    }
}
