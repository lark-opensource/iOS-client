//
//  BTDismissAnimationController.swift
//  SKBrowser
//
//  Created by 吴珂 on 2020/8/4.
//  


import Foundation
import SKFoundation

final class BTDismissAnimationController: NSObject, UIViewControllerAnimatedTransitioning {

    weak var dismissingController: BTController?
    
    var animationPosition: BTAnimationPosition = .right

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard dismissingController?.dismissTransitionWasCancelled == false else {
            transitionContext.completeTransition(false)
            dismissingController?.dismissTransitionWasCancelled = false
            DocsLogger.info("animateTransition dismissTransitionWasCancelled")
            return
        }
        DocsLogger.info("animateTransition continue")
        let containerView = transitionContext.containerView
        if let toView = transitionContext.view(forKey: .to),
           let toViewController = transitionContext.viewController(forKey: .to) {
            toView.frame = transitionContext.finalFrame(for: toViewController)
            containerView.insertSubview(toView, at: 0)
        }
        if let fromView = transitionContext.view(forKey: .from) {
            var finalFrame = fromView.frame
            switch self.animationPosition {
            case .bottom:
                finalFrame = fromView.bounds.offsetBy(dx: 0, dy: fromView.bounds.size.height)
            case .right:
                if  !UserScopeNoChangeFG.ZJ.btItemViewPresentModeFixDisable {
                    finalFrame = finalFrame.offsetBy(dx: fromView.bounds.size.width, dy: 0)
                } else {
                    finalFrame = CGRect(x: containerView.bounds.size.width, y: 0, width: containerView.bounds.size.width, height: containerView.bounds.size.height)
                }
            default:
                // 默认动画从下方下掉
                finalFrame = fromView.bounds.offsetBy(dx: 0, dy: fromView.bounds.size.height)
            }
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                fromView.frame = finalFrame
            }, completion: { [weak self] completed in
                if completed,
                   false == self?.dismissingController?.hasDismissalFailed {
                    self?.dismissingController?.afterRealDismissal()
                }
                DocsLogger.info("animateTransition completed: \(completed)")
                self?.dismissingController?.hasDismissalFailed = false
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}
