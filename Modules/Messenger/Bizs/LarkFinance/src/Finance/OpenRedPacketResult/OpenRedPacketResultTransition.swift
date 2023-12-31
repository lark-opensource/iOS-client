//
//  OpenRedPacketTransition.swift
//  LarkFinance
//
//  Created by ChalrieSu on 2018/10/23.
//

import UIKit
import Foundation
import LarkUIKit
import LarkExtensions

final class OpenRedPacketResultTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let redPacketVC = fromVC.transitionViewController as? OpenRedPacketViewController,
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let resultVC = toVC.transitionViewController as? RedPacketResultViewController else {
                transitionContext.completeTransition(false)
                return
        }

        let containerView = transitionContext.containerView
        let resultView: UIView = resultVC.view
        resultView.layoutIfNeeded()

        containerView.insertSubview(toVC.view, at: 0)
        var targetFrame: CGRect = .zero
        let topConvertedFrame = containerView.convert(redPacketVC.topContainerView.bounds, from: redPacketVC.topContainerView)
        let bottomConvertedFrame = containerView.convert(redPacketVC.bottomContainerView.bounds, from: redPacketVC.bottomContainerView)
        targetFrame.size = CGSize(width: topConvertedFrame.width,
                                  height: bottomConvertedFrame.bottom - topConvertedFrame.top)
        targetFrame.top = topConvertedFrame.top
        targetFrame.centerX = topConvertedFrame.centerX

        let targetRatio = targetFrame.width / targetFrame.height
        let resultViewRatio = resultView.frame.width / resultView.frame.height
        let ratio: CGFloat
        if targetRatio > resultViewRatio {
            ratio = targetFrame.height / resultView.frame.height
        } else {
            ratio = targetFrame.width / resultView.frame.width
        }
        resultView.alpha = 0
        resultView.transform = CGAffineTransform(scaleX: ratio, y: ratio)

        let topOriginFrame = redPacketVC.topContainerView.frame
        let bottomOriginFrame = redPacketVC.bottomContainerView.frame
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       options: .curveEaseIn,
                       animations: {
            var newTopFrame: CGRect = .zero
            newTopFrame.size = topOriginFrame.size * 1.44
            newTopFrame.bottom = 0
            newTopFrame.centerX = containerView.bounds.width / 2
            redPacketVC.topContainerView.frame = newTopFrame

            var newBottomFrame: CGRect = .zero
            newBottomFrame.size = bottomOriginFrame.size * 1.44
            newBottomFrame.top = containerView.bounds.height
            newBottomFrame.centerX = containerView.bounds.width / 2
            redPacketVC.bottomContainerView.frame = newBottomFrame

            redPacketVC.contentViews.forEach { $0.alpha = 0 }

            resultView.transform = .identity
            resultView.alpha = 1
        }, completion: { (_) in
            redPacketVC.topContainerView.frame = topOriginFrame
            redPacketVC.bottomContainerView.frame = bottomOriginFrame
            redPacketVC.contentViews.forEach { $0.alpha = 1 }

            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

}
