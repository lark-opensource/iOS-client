//
//  ChatMenuExtendTransition.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/9/23.
//

import Foundation
import UIKit

final class ChatMenuExtendPresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.1
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
              let chatMenuExtendVC = toVC as? ChatMenuExtendViewController,
              let sourceView = chatMenuExtendVC.sourceView else {
                transitionContext.completeTransition(false)
                return
        }

        transitionContext.containerView.addSubview(chatMenuExtendVC.tapBackgroundView)
        transitionContext.containerView.addSubview(chatMenuExtendVC.shadowBackgroundView)
        transitionContext.containerView.addSubview(chatMenuExtendVC.view)
        transitionContext.containerView.addSubview(chatMenuExtendVC.arrowView)

        chatMenuExtendVC.tapBackgroundView.frame = transitionContext.containerView.bounds

        let vcMargin: CGFloat = 8
        var vcSize = chatMenuExtendVC.contentSize
        vcSize.width = min(transitionContext.containerView.bounds.width - vcMargin * 2, vcSize.width)
        chatMenuExtendVC.preferredContentSize = vcSize
        let sourceRect = sourceView.convert(sourceView.bounds, to: transitionContext.containerView)
        var vcMinX: CGFloat = sourceRect.centerX - vcSize.width / 2.0
        vcMinX = max(vcMinX, vcMargin)
        vcMinX = min(transitionContext.containerView.bounds.width - vcMargin - vcSize.width, vcMinX)

        chatMenuExtendVC.view.frame = CGRect(x: vcMinX, y: sourceRect.minY - 20 - vcSize.height, width: vcSize.width, height: vcSize.height)
        chatMenuExtendVC.shadowBackgroundView.frame = chatMenuExtendVC.view.frame
        chatMenuExtendVC.arrowView.frame.origin = CGPoint(x: sourceRect.centerX - chatMenuExtendVC.arrowView.frame.width / 2, y: chatMenuExtendVC.shadowBackgroundView.frame.maxY - 0.5)

        chatMenuExtendVC.view.layoutIfNeeded()
        chatMenuExtendVC.view.transform = CGAffineTransform(translationX: 0, y: 30)
        chatMenuExtendVC.shadowBackgroundView.transform = CGAffineTransform(translationX: 0, y: 30)
        chatMenuExtendVC.arrowView.transform = CGAffineTransform(translationX: 0, y: 30)
        chatMenuExtendVC.view.alpha = 0
        chatMenuExtendVC.shadowBackgroundView.alpha = 0
        chatMenuExtendVC.arrowView.alpha = 0

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                chatMenuExtendVC.view.transform = CGAffineTransform.identity
                chatMenuExtendVC.shadowBackgroundView.transform = CGAffineTransform.identity
                chatMenuExtendVC.arrowView.transform = CGAffineTransform.identity
                chatMenuExtendVC.view.alpha = 1
                chatMenuExtendVC.shadowBackgroundView.alpha = 1
                chatMenuExtendVC.arrowView.alpha = 1
            },
            completion: { transitionContext.completeTransition($0) }
        )
    }
}

final class ChatMenuExtendDismissTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.1
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let chatMenuExtendVC = fromVC as? ChatMenuExtendViewController else {
                transitionContext.completeTransition(false)
                return
        }

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                chatMenuExtendVC.view.transform = CGAffineTransform(translationX: 0, y: 30)
                chatMenuExtendVC.shadowBackgroundView.transform = CGAffineTransform(translationX: 0, y: 30)
                chatMenuExtendVC.arrowView.transform = CGAffineTransform(translationX: 0, y: 30)
                chatMenuExtendVC.view.alpha = 0
                chatMenuExtendVC.shadowBackgroundView.alpha = 0
                chatMenuExtendVC.arrowView.alpha = 0
            },
            completion: { transitionContext.completeTransition($0) }
        )
    }
}
