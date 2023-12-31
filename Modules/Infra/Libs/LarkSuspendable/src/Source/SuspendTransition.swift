//
//  SuspendTransition.swift
//  LarkSuspendable
//
//  Created by bytedance on 2021/1/5.
//

import UIKit
import Foundation
import LarkUIKit

// swiftlint:disable all
// MARK: - present 转场类型
public enum SuspendModalTransitionType {
    case present
    case dismiss
    case none
}

// MARK: - navigation 转场类型
public enum SuspendNavigationTransitionType {
    case push
    case pop
    case custom
    case none
}
// swiftlint:enable all

public final class SuspendTransition: NSObject {

    private var operationType: SuspendNavigationTransitionType
    private weak var transitionContext: UIViewControllerContextTransitioning?
    private weak var maskLayer: CAShapeLayer?

    public init(type: SuspendNavigationTransitionType) {
        self.operationType = type
        super.init()
    }
}

// MARK: - Private Methods
extension SuspendTransition {

    private func pushAnimation(transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) else {
                completeTransition(transitionContext: transitionContext)
                return
        }
        guard let fromVC = transitionContext.viewController(forKey: .from) else {
            return
        }
        // 添加到containerView中
        let containerView = transitionContext.containerView
        containerView.addSubview(toVC.view)

        toVC.view.frame = transitionContext.finalFrame(for: toVC)

        var beginFrame: CGRect = CGRect(
            origin: UIScreen.main.bounds.center,
            size: .zero
        )
        if let bubbleView = SuspendManager.shared.suspendController?.bubbleView {
            beginFrame = bubbleView.convert(bubbleView.bounds, to: toVC.view)
        }
        let cornerRadius = SuspendConfig.bubbleSize.height / 2
        let beginPath = UIBezierPath(roundedRect: beginFrame, cornerRadius: cornerRadius)
        let endPath = UIBezierPath(roundedRect: UIScreen.main.bounds, cornerRadius: cornerRadius)
        let maskLayer = CAShapeLayer()
        self.maskLayer = maskLayer
        maskLayer.path = endPath.cgPath
        toVC.view.layer.mask = maskLayer
        // 开始动画
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = beginPath.cgPath
        animation.toValue = endPath.cgPath
        animation.duration = transitionDuration(using: transitionContext)
        animation.delegate = self
        maskLayer.add(animation, forKey: "path")
    }

    private func popAnimation(transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to) else {
                completeTransition(transitionContext: transitionContext)
                return
        }
        let containerView = transitionContext.containerView
        containerView.addSubview(toVC.view)
        containerView.addSubview(fromVC.view)

        toVC.view.frame = transitionContext.finalFrame(for: toVC)

        var endFrame: CGRect = CGRect(
            origin: UIScreen.main.bounds.center,
            size: .zero
        )
        if let bubbleView = SuspendManager.shared.suspendController?.bubbleView {
            endFrame = bubbleView.convert(bubbleView.bounds, to: fromVC.view)
        }
        let cornerRadius = SuspendConfig.bubbleSize.height / 2
        let beginPath = UIBezierPath(roundedRect: UIScreen.main.bounds, cornerRadius: cornerRadius)
        let endPath = UIBezierPath(roundedRect: endFrame, cornerRadius: cornerRadius)
        let maskLayer = CAShapeLayer()
        maskLayer.path = endPath.cgPath
        self.maskLayer = maskLayer
        fromVC.view.layer.mask = maskLayer
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = beginPath.cgPath
        animation.toValue = endPath.cgPath
        animation.duration = transitionDuration(using: transitionContext)
        animation.delegate = self
        maskLayer.add(animation, forKey: "path")
    }

    /// 结束动画
    private func completeTransition(transitionContext: UIViewControllerContextTransitioning?) {
        guard let transitionContext = transitionContext else { return }
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
    }

}

// MARK: - UIViewControllerAnimatedTransitioning

extension SuspendTransition: UIViewControllerAnimatedTransitioning {

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return SuspendConfig.animateDuration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        switch operationType {
        case .push:
            pushAnimation(transitionContext: transitionContext)
        case .pop:
            popAnimation(transitionContext: transitionContext)
        default:
            completeTransition(transitionContext: transitionContext)
        }
    }

}

// MARK: - CAAnimationDelegate

extension SuspendTransition: CAAnimationDelegate {

    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        maskLayer?.superlayer?.mask = nil
        maskLayer?.removeFromSuperlayer()
        completeTransition(transitionContext: transitionContext)
    }
}
