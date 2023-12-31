//
//  FocusListTransitionManager.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/9.
//

import Foundation
import UIKit

public final class FocusListTransitionManager: NSObject, UIViewControllerTransitioningDelegate {

    private let animator = FocusListTransitionAnimator(transitionType: .present)

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.type = .present
        return animator
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.type = .dismiss
        return animator
    }

}

final class FocusListTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    enum TransitionType {
        case present
        case dismiss
    }

    var type: TransitionType

    init(transitionType: TransitionType) {
        type = transitionType
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        switch type {
        case .present:  return 0.3
        case .dismiss:  return 0.3
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch type {
        case .present:  present(transitionContext)
        case .dismiss:  dismiss(transitionContext)
        }
    }

    private func present(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to),
              let toController = transitionContext.viewController(forKey: .to) as? FocusListController else { return }
        let finalFrame = transitionContext.finalFrame(for: toController)
        toView.alpha = 0
        toView.frame = finalFrame
        transitionContext.containerView.addSubview(toView)
        toView.alpha = 0
        toController.processDismiss(progress: 1)
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: {
            toView.alpha = 1
            toController.processDismiss(progress: 0)
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

    private func dismiss(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let fromController = transitionContext.viewController(forKey: .from) as? FocusListController else { return }
        let duration = transitionDuration(using: transitionContext)
        transitionContext.containerView.addSubview(fromView)
        if fromController.state == .normal {
            // 有数据的情况，侧划关闭
            let loopTimes = Int(duration / 0.02)
            // 背景模糊动画
//            fromController.animateBlurEffect(toRadius: 0, opacity: 0, loopTimes: loopTimes)
            UIView.animate(withDuration: duration, animations: {
                fromController.processDismiss(progress: 1)
                fromView.alpha = 0
            }, completion: { _ in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        } else {
            // 没数据的情况，渐隐
            UIView.animate(withDuration: duration, animations: {
                fromView.alpha = 0
            }, completion: { _ in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}
