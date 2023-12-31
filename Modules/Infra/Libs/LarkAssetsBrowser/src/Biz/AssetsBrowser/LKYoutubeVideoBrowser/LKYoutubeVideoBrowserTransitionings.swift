//
//  LKYoutubeVideoBrowserTransitionings.swift
//  LarkCore
//
//  Created by zc09v on 2019/6/11.
//

import UIKit
import Foundation

// swiftlint:disable type_name
final class LKYoutubeVideoBrowserPresentTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    // swiftlint:enable type_name
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) as? LKYoutubeVideoBrowser else {
            return
        }
        let containerView = transitionContext.containerView
        containerView.backgroundColor = UIColor.black
        if let thumbnail = toVC.fromThumbnail, let imageSize = thumbnail.image?.size {
            let animatedImageView = UIImageView(frame: thumbnail.frame)
            animatedImageView.contentMode = .scaleAspectFill
            animatedImageView.clipsToBounds = true
            animatedImageView.image = thumbnail.image
            animatedImageView.frame = thumbnail.convert(thumbnail.bounds, to: containerView)
            containerView.addSubview(animatedImageView)

            let zoomScale = LKYoutubeVideoBrowser.minZoomScaleFor(
                boundsSize: containerView.bounds.size,
                imageSize: imageSize
            )
            var targetWidth = imageSize.width * zoomScale
            var targetHeight = imageSize.height * zoomScale
            if targetHeight > containerView.frame.height {
                targetHeight = containerView.frame.height
                targetWidth = targetHeight * imageSize.width / imageSize.height
            }
            let targetX = (containerView.frame.width - targetWidth) / 2
            let targetY = (containerView.frame.height - targetHeight) / 2
            let targetFrame = CGRect(x: targetX, y: targetY, width: targetWidth, height: targetHeight)

            UIView.animate(
                withDuration: self.transitionDuration(using: transitionContext),
                delay: 0,
                options: .curveLinear,
                animations: {
                    animatedImageView.frame = targetFrame
                },
                completion: { _ in
                    containerView.backgroundColor = UIColor.clear
                    animatedImageView.removeFromSuperview()
                    containerView.addSubview(toVC.view)
                    transitionContext.completeTransition(true)
                })
        } else {
            containerView.backgroundColor = UIColor.black.withAlphaComponent(0)
            UIView.animate(
                withDuration: self.transitionDuration(using: transitionContext),
                delay: 0,
                options: .curveLinear,
                animations: {
                    containerView.backgroundColor = UIColor.black
                },
                completion: { _ in
                    containerView.backgroundColor = UIColor.clear
                    containerView.addSubview(toVC.view)
                    transitionContext.completeTransition(true)
                })
        }
    }
}

// swiftlint:disable type_name
final class LKYoutubeVideoBrowserDismissTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    // swiftlint:enable type_name
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? LKYoutubeVideoBrowser,
              let toVC = transitionContext.viewController(forKey: .to) else {
            return
        }
        let coverImageView = fromVC.coverImageView
        if let thumbnail = fromVC.fromThumbnail, viewIsShow(in: toVC, view: thumbnail) {
            let containerView = transitionContext.containerView
            let dissmissFrame = fromVC.view.convert(coverImageView.frame, to: containerView)
            fromVC.view.removeFromSuperview()
            containerView.backgroundColor = UIColor.clear
            let animatedImageView = UIImageView(frame: dissmissFrame)
            animatedImageView.contentMode = thumbnail.contentMode
            animatedImageView.clipsToBounds = true
            animatedImageView.image = coverImageView.image
            containerView.addSubview(animatedImageView)

            let targetFrame = thumbnail.convert(thumbnail.bounds, to: containerView)
            UIView.animate(
                withDuration: self.transitionDuration(using: transitionContext),
                delay: 0,
                options: .curveLinear,
                animations: {
                    animatedImageView.frame = targetFrame
                    containerView.backgroundColor = UIColor.clear
                }, completion: { _ in
                    transitionContext.completeTransition(true)
                })
        } else {
            let containerView = transitionContext.containerView
            UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                           delay: 0,
                           options: .curveLinear,
                           animations: {
                containerView.alpha = 0
            }, completion: { _ in
                fromVC.view.removeFromSuperview()
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
