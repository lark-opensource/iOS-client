//
//  EdgeNaviAnimator.swift
//  LarkUIKit
//
//  Created by Supeng on 2021/2/5.
//

import UIKit
import Foundation
public protocol EdgeNaviAnimatorGesDelegate: UIGestureRecognizerDelegate {}
public final class EdgeNaviAnimator: UIPercentDrivenInteractiveTransition {

    public init(pushViewController: @escaping () -> Void) {
        self.pushViewController = pushViewController
        super.init()
    }
    public weak var gestureDelegate: EdgeNaviAnimatorGesDelegate?
    private let pushViewController: () -> Void
    private let edgeGesture: UIScreenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer()
    private let animationDuration: TimeInterval = 0.3
    private let interactiveAnimationOptions: UIView.AnimationOptions = .curveLinear
    private let nonInteractiveAnimationOptions: UIView.AnimationOptions = .curveEaseInOut
    public private(set) var interactive = false

    public func addGesture(to view: UIView) {
        edgeGesture.edges = .right
        edgeGesture.delegate = self
        edgeGesture.addTarget(self, action: #selector(edgeGestureDidInvoke(_:)))
        view.addGestureRecognizer(edgeGesture)
    }

    @objc
    private func edgeGestureDidInvoke(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if case .began = recognizer.state {
            interactive = true
            pushViewController()
            return
        }
        let translation = recognizer.translation(in: recognizer.view!.superview!)
        let location = recognizer.location(in: recognizer.view!.superview!)

        guard let width = recognizer.view?.bounds.width else { return }

        let locationX = width - location.x
        let tanslationX = max(0, -translation.x)

        let ratio = min(max(tanslationX / (width * (1 / 3)), 0), 1)
        let caculatedX = tanslationX * (1 - ratio) + locationX * ratio

        let progress = min(max(abs(caculatedX / width), 0.01), 0.99)

        switch recognizer.state {
        case .changed:
            update(progress)
        case .cancelled, .ended:
            if progress < 0.3 {
                cancel()
            } else {
                finish()
            }
            interactive = false
        default:
            break
        }
    }
}

extension EdgeNaviAnimator: UIViewControllerAnimatedTransitioning {
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to)!

        let shadowView = UIView()
        shadowView.backgroundColor = UIColor.black
        shadowView.alpha = 0
        shadowView.frame = transitionContext.containerView.bounds
        transitionContext.containerView.addSubview(shadowView)

        transitionContext.containerView.addSubview(toVC.view)
        toVC.view.frame = transitionContext.containerView.bounds
        toVC.view.layoutIfNeeded()
        toVC.view.frame.origin = CGPoint(x: transitionContext.containerView.bounds.width, y: 0)

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                       delay: 0,
                       options: interactive ? [interactiveAnimationOptions] : [nonInteractiveAnimationOptions],
                       animations: {
                        shadowView.alpha = 0.12
                        toVC.view.frame.origin = .zero
                        fromVC.view.frame.origin = CGPoint(x: -transitionContext.containerView.bounds.width * 0.3, y: 0)
                       },
                       completion: { _ in
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                        fromVC.view.frame.origin = .zero
                        shadowView.removeFromSuperview()
                        self.interactive = false
                       })
    }
}

extension EdgeNaviAnimator: CustomNaviAnimation {
    public func pushAnimationController(from: UIViewController,
                                        to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        interactive ? self : nil
    }

    public func interactiveTransitioning(with animatedTransitioning: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        interactive ? self : nil
    }
}

extension EdgeNaviAnimator: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let shouldBeRequiredToFail = self.gestureDelegate?.gestureRecognizer?(gestureRecognizer, shouldBeRequiredToFailBy: otherGestureRecognizer) {
            return shouldBeRequiredToFail
        }
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let shouldRequireFailureOf = self.gestureDelegate?.gestureRecognizer?(gestureRecognizer, shouldRequireFailureOf: otherGestureRecognizer) {
            return shouldRequireFailureOf
        }
        return false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith erGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let result = self.gestureDelegate?.gestureRecognizer?(gestureRecognizer, shouldRecognizeSimultaneouslyWith: erGestureRecognizer) {
            return result
        }
        return false
    }
}
