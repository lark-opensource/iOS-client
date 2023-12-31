//
//  DimmingAnimation.swift
//  SpaceKit
//
//  Created by 邱沛 on 2020/6/29.
//

import UIKit
import UniverseDesignColor

public final class DimmingPresentAnimation: NSObject, UIViewControllerAnimatedTransitioning, CAAnimationDelegate {
    private let animateDuration: Double
    private let willPresent: (() -> Void)?
    private let animation: (() -> Void)?
    private let completion: (() -> Void)?
    private let layerAnimationOnly: Bool    // 是否只使用 layer 动画实现（部分场景不适合用 UIView 动画，会导致布局抖动）
    
    private var transitionContext: UIViewControllerContextTransitioning?

    public init(animateDuration: Double,
         willPresent: (() -> Void)? = nil,
         animation: (() -> Void)? = nil,
         completion: (() -> Void)? = nil,
         layerAnimationOnly: Bool = false) {
        self.animateDuration = animateDuration
        self.willPresent = willPresent
        self.animation = animation
        self.completion = completion
        self.layerAnimationOnly = layerAnimationOnly
        super.init()
    }

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animateDuration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        container.backgroundColor = .clear
        let containerVC: UIViewController? = transitionContext.viewController(forKey: .to)
        var toVC = containerVC
        if let navVC = toVC as? UINavigationController {
            toVC = navVC.viewControllers.first
        }
        guard let toVC = toVC as? DraggableViewController, let containerVC = containerVC else {
            assertionFailure("cannot get correct VC")
            return
        }
        container.addSubview(containerVC.view)
        containerVC.view.frame = container.frame
        toVC.view.frame = container.frame
        if layerAnimationOnly {
            toVC.view.backgroundColor = UDColor.bgMask
        } else {
        toVC.contentView.snp.remakeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(toVC.view.bounds.height)
            make.height.equalTo(toVC.view.bounds.height - toVC.contentViewMaxY)
        }
        toVC.view.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0)
        }
        toVC.view.layoutIfNeeded()
        self.willPresent?()
        if layerAnimationOnly {
            self.transitionContext = transitionContext
            
            let backgroundAniamtion = CABasicAnimation(keyPath: "backgroundColor")
            backgroundAniamtion.fromValue = UIColor.ud.N1000.withAlphaComponent(0).cgColor
            backgroundAniamtion.toValue = UDColor.bgMask.cgColor
            backgroundAniamtion.duration = transitionDuration(using: transitionContext)
            backgroundAniamtion.repeatCount = 1
            toVC.view.layer.add(backgroundAniamtion, forKey: "viewAnimation")
            
            let size = toVC.contentView.frame.size
            let center = toVC.contentView.center
            let positionAnimation = CABasicAnimation(keyPath: "position")
            positionAnimation.fromValue = CGPoint(x: center.x, y: center.y + size.height)
            positionAnimation.toValue = center
            positionAnimation.duration = transitionDuration(using: transitionContext)
            positionAnimation.repeatCount = 1
            positionAnimation.delegate = self
            toVC.contentView.layer.add(positionAnimation, forKey: "contentViewAnimation")
        } else {
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            self.animation?()
            toVC.contentView.snp.remakeConstraints { (make) in
                make.top.equalTo(toVC.contentViewMaxY)
                make.bottom.leading.trailing.equalToSuperview()
            }
            toVC.view.backgroundColor = UDColor.bgMask
            toVC.view.layoutIfNeeded()
        }, completion: { _ in
            self.completion?()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
        }
    }
    
    public func animationDidStart(_ anim: CAAnimation) {
        self.animation?()
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.completion?()
        
        if let transitionContext = self.transitionContext {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        self.transitionContext = nil
    }
}

public final class DimmingDismissAnimation: NSObject, UIViewControllerAnimatedTransitioning, CAAnimationDelegate {
    private let animateDuration: Double
    private let willDismiss: (() -> Void)?
    private let animation: (() -> Void)?
    private let completion: (() -> Void)?
    private let layerAnimationOnly: Bool    // 是否只使用 layer 动画实现（部分场景不适合用 UIView 动画，会导致布局抖动）

    private var transitionContext: UIViewControllerContextTransitioning?

    public init(animateDuration: Double,
         willDismiss: (() -> Void)? = nil,
         animation: (() -> Void)? = nil,
         completion: (() -> Void)? = nil,
         layerAnimationOnly: Bool = false) {
        self.animateDuration = animateDuration
        self.willDismiss = willDismiss
        self.animation = animation
        self.completion = completion
        self.layerAnimationOnly = layerAnimationOnly
        super.init()
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animateDuration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        container.backgroundColor = .clear
        var fromVC: UIViewController? = transitionContext.viewController(forKey: .from)
        if let navVC = fromVC as? UINavigationController {
            fromVC = navVC.viewControllers.first
        }
        guard let fromVC = fromVC as? DraggableViewController else {
            assertionFailure("cannot get correct VC")
            return
        }
        self.willDismiss?()
        
        if layerAnimationOnly {
            self.transitionContext = transitionContext
            
            let backgroundAniamtion = CABasicAnimation(keyPath: "backgroundColor")
            backgroundAniamtion.fromValue = fromVC.view.backgroundColor?.cgColor ?? UIColor.clear.cgColor
            backgroundAniamtion.toValue = UIColor.ud.N1000.withAlphaComponent(0).cgColor
            backgroundAniamtion.duration = transitionDuration(using: transitionContext)
            backgroundAniamtion.repeatCount = 1
            backgroundAniamtion.isRemovedOnCompletion = false   // 结束后固定动画结果，不然会闪现初始状态
            backgroundAniamtion.fillMode = .forwards            // 结束后固定动画结果，不然会闪现初始状态
            fromVC.view.layer.add(backgroundAniamtion, forKey: "viewAnimation")
            
            let size = fromVC.contentView.frame.size
            let center = fromVC.contentView.center
            let positionAnimation = CABasicAnimation(keyPath: "position")
            positionAnimation.fromValue = center
            positionAnimation.toValue = CGPoint(x: center.x, y: center.y + size.height)
            positionAnimation.duration = transitionDuration(using: transitionContext)
            positionAnimation.repeatCount = 1
            positionAnimation.isRemovedOnCompletion = false // 结束后固定动画结果，不然会闪现初始状态
            positionAnimation.fillMode = .forwards          // 结束后固定动画结果，不然会闪现初始状态
            positionAnimation.delegate = self
            fromVC.contentView.layer.add(positionAnimation, forKey: "contentViewAnimation")
        } else {
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            self.animation?()
            fromVC.contentView.snp.remakeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(fromVC.view.bounds.maxY)
                make.height.equalTo(fromVC.view.bounds.height - fromVC.contentViewMaxY)
            }
            fromVC.view.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0)
            fromVC.view.layoutIfNeeded()
        }, completion: { _ in
            self.completion?()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
        }
    }
    
    public func animationDidStart(_ anim: CAAnimation) {
        self.animation?()
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.completion?()
        
        if let transitionContext = self.transitionContext {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        self.transitionContext = nil
    }
}
