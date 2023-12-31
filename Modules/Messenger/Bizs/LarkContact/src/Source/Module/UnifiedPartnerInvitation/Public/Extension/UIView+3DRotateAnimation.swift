//
//  UIView+3DRotateAnimation.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/9/27.
//

import UIKit
import Foundation

extension UIView {
    func start3DRotateAnimation(duration: TimeInterval, delegate: CAAnimationDelegate? = nil) {

        let animationTransform_prefix: CATransform3D = CATransform3DMakeRotation(CGFloat(Double.pi / 2), 0, 1, 0)
        let animationTransform_transition: CATransform3D = CATransform3DMakeRotation(CGFloat(Double.pi * 3 / 4), 0, 1, 0)
        let animationTransform_sufix: CATransform3D = CATransform3DMakeRotation(0, 0, 1, 0)

        let animation_prefix = CABasicAnimation(keyPath: "transform")
        animation_prefix.toValue = NSValue(caTransform3D: animationTransform_prefix)
        animation_prefix.duration = duration / 2
        animation_prefix.beginTime = 0
        animation_prefix.isRemovedOnCompletion = false
        animation_prefix.fillMode = .forwards

        let animation_transition = CABasicAnimation(keyPath: "transform")
        animation_transition.toValue = NSValue(caTransform3D: animationTransform_transition)
        animation_transition.duration = 0
        animation_transition.beginTime = duration / 2
        animation_transition.isRemovedOnCompletion = false
        animation_transition.fillMode = .forwards

        let animation_sufix = CABasicAnimation(keyPath: "transform")
        animation_sufix.toValue = NSValue(caTransform3D: animationTransform_sufix)
        animation_sufix.duration = duration / 2
        animation_sufix.beginTime = duration / 2
        animation_sufix.isRemovedOnCompletion = false
        animation_sufix.fillMode = .forwards

        let groupAnimation = CAAnimationGroup()
        groupAnimation.delegate = delegate
        groupAnimation.isRemovedOnCompletion = false
        groupAnimation.duration = duration
        groupAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        groupAnimation.repeatCount = 0
        groupAnimation.fillMode = .forwards
        groupAnimation.animations = [animation_prefix, animation_transition, animation_sufix]

        layer.add(groupAnimation, forKey: "_3DRotateAnimation")
    }

}

/// 为了解决 CoreAnimation 内部强引用导致的循环引用，避免内存泄露
final class WeakLayerAnimationDelegateProxy: NSObject, CAAnimationDelegate {
    weak var weakDelegate: CAAnimationDelegate?
    init(delegate: CAAnimationDelegate) {
        self.weakDelegate = delegate
    }

    func animationDidStart(_ anim: CAAnimation) {
        weakDelegate?.animationDidStart?(anim)
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        weakDelegate?.animationDidStop?(anim, finished: flag)
    }
}
