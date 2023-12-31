//
//  UDDrawerTransitionAnimator.swift
//  UniverseDesignDrawer
//
//  Created by 袁平 on 2021/3/12.
//

import Foundation
import UIKit

class UDDrawerTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let direction: UDDrawerDirection
    weak var transitionManager: UDDrawerTransitionManager?

    enum TransitionType {
        case present
        case dismiss
    }

    var type: TransitionType
    // 用手侧滑拉出时，需要设置动画curveLinear，否则会不跟手
    var isInteract: Bool = false

    init(type: TransitionType, direction: UDDrawerDirection) {
        self.type = type
        self.direction = direction
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return UDDrawerValues.transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch type {
        case .present: present(transitionContext: transitionContext)
        case .dismiss: dismiss(transitionContext: transitionContext)
        }
    }

    private func present(transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) as? UDDrawerContainerViewController else { return }
        transitionManager?.state = .showing
        transitionContext.containerView.addSubview(toVC.view)
        toVC.view.setNeedsLayout()
        toVC.view.layoutIfNeeded()
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, delay: 0, options: [isInteract ? .curveLinear : .curveEaseOut]) {
            toVC.updateContentXPosition(to: 0)
            toVC.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            if self?.transitionManager?.state == .showing {
                self?.transitionManager?.state = .shown
            }
        }
    }

    private func dismiss(transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? UDDrawerContainerViewController else { return }
        self.transitionManager?.state = .hidding
        fromVC.view.layoutIfNeeded()
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, delay: 0, options: [isInteract ? .curveLinear : .curveEaseOut]) {
            fromVC.updateContentXPosition(to: -fromVC.contentWidth)
            fromVC.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            if self?.transitionManager?.state == .hidding {
                self?.transitionManager?.state = .hidden
            }
        }
    }
}
