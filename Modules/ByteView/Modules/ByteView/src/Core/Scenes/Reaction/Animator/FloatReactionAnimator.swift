//
//  FloatReactionAnimator.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/10/17.
//

import UIKit
import ByteViewUI

class FloatReactionAnimator: ReactionAnimator {
    let heightRatio: CGFloat

    init(heightRatio: CGFloat) {
        self.heightRatio = heightRatio
    }

    @discardableResult
    private func animate(_ duration: TimeInterval, controlPoint1: CGPoint, controlPoint2: CGPoint, delay: TimeInterval, animation: @escaping () -> Void) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: duration, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        animator.addAnimations {
            animation()
        }
        animator.scrubsLinearly = false
        animator.startAnimation(afterDelay: delay)
        return animator
    }

    // disable-lint: magic number
    func showReaction(_ reaction: UIView, duration: TimeInterval, completion: @escaping () -> Void) {
        guard let view = reaction as? FloatReactionView else { return }
        view.prepareForAnimation()
        let ease1 = CGPoint(x: 0.25, y: 0.1)
        let ease2 = CGPoint(x: 0.25, y: 1)
        animate(duration * 0.085, controlPoint1: ease1, controlPoint2: ease2, delay: 0) {
            view.bottomView.alpha = 1
        }
        animate(duration * 0.18, controlPoint1: ease1, controlPoint2: ease2, delay: duration * 0.71) {
            view.bottomView.alpha = 0
        }
        animate(duration * 0.07, controlPoint1: ease1, controlPoint2: ease2, delay: 0) {
            view.alpha = 1
        }
        animate(duration * 0.22, controlPoint1: ease1, controlPoint2: ease2, delay: duration * 0.78) {
            view.alpha = 0
        }
        animate(duration * 0.24, controlPoint1: ease1, controlPoint2: ease2, delay: duration * 0.76) {
            view.transform = CGAffineTransformScale(view.transform, 0.9, 0.9)
        }
        animate(duration * 0.15, controlPoint1: CGPoint(x: 0.18, y: 0.89), controlPoint2: CGPoint(x: 0.32, y: 1.27), delay: 0) {
            view.reactionView.transform = .identity
        }
        animate(duration, controlPoint1: CGPoint(x: 0.46, y: 0.03), controlPoint2: CGPoint(x: 0.52, y: 0.95), delay: 0) {
            view.frame.origin.y -= self.heightRatio * VCScene.bounds.height
        }.addCompletion { _ in
            completion()
        }
    }
    // enable-lint: magic number
}
