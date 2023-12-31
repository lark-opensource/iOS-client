//
//  BTDismissInteractionController.swift
//  SKBitable
//
//  Created by 吴珂 on 2020/8/3.
//  


import UIKit
import SKFoundation

final class BTDismissInteractionController: UIPercentDrivenInteractiveTransition {
    var shouldBeginRealDismissal = false
    var interactive: Bool = false
    weak var dismissingController: BTController?
    var prevColor: UIColor?
    var cardWidth: CGFloat = .zero
    var windowHeight: CGFloat = .zero
    var dismissing: Bool = false
    
    func handlePanGesture(_ gesture: UIPanGestureRecognizer, setViewScrollable: (Bool) -> Void) {
        let translation = gesture.translation(in: gesture.view?.superview)
        let velocity = gesture.velocity(in: gesture.view?.superview)
        switch gesture.state {
        case .began:
            startDismissing()
            shouldBeginRealDismissal = true
            dismissingController?.dismissTransitionWasCancelled = false
            dismissingController?.hasDismissalFailed = true
        case .changed:
            guard interactive else { return }
            setViewScrollable(false)
            var fraction = translation.y / windowHeight
            fraction = min(max(fraction, 0), 1.0)
            shouldBeginRealDismissal = velocity.y > 1000 || (fraction > 0.3 && velocity.y > 0)
            updateDismissingProgress(fraction: fraction)
            update(fraction)
        case .ended:
                 guard interactive else { return }
                 interactive = false
                 if !shouldBeginRealDismissal {
                     dismissingController?.dismissTransitionWasCancelled = true
                     cancel()
                     dismissingController?.restoreForInteractiveDismiss()
                     setViewScrollable(true)
                 } else {
                     dismissingController?.hasDismissalFailed = false
                     finish()
                 }
             case .cancelled, .failed:
                 guard interactive else { return }
                 interactive = false
                 dismissingController?.dismissTransitionWasCancelled = true
                 cancel()
                 dismissingController?.restoreForInteractiveDismiss()
                 setViewScrollable(true)
             default:
                 break
             }
         }
    
    func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view?.superview)
        let velocity = gesture.velocity(in: gesture.view?.superview)
        switch gesture.state {
        case .began:
            startDismissing()
            shouldBeginRealDismissal = true
            dismissingController?.dismissTransitionWasCancelled = false
            dismissingController?.hasDismissalFailed = true
        case .changed:
            guard interactive else { return }
            var fraction = translation.x / cardWidth
            fraction = min(max(fraction, 0), 1.0)
            shouldBeginRealDismissal = velocity.x > 500 || (fraction > 0.3 && velocity.x > 0)
            update(fraction)
        case .ended:
            guard interactive else { return }
            interactive = false
            if !shouldBeginRealDismissal {
                if UserScopeNoChangeFG.ZJ.btItemViewPresentModeFixDisable {
                    dismissingController?.dismissTransitionWasCancelled = true
                }
                cancel()
                dismissingController?.restoreForInteractiveDismiss()
            } else {
                dismissingController?.hasDismissalFailed = false
                finish()
            }
        case .cancelled, .failed:
            guard interactive else { return }
            interactive = false
            dismissingController?.dismissTransitionWasCancelled = true
            cancel()
            dismissingController?.restoreForInteractiveDismiss()
        default:
            break
        }
    }
    
    func updateDismissingProgress(fraction: CGFloat) {
        dismissingController?.updateBackgroundViewColor(fraction)
    }
    
    func startDismissing() {
        interactive = true
        if UserScopeNoChangeFG.ZJ.btCardReform {
            if let cardsView = dismissingController?.cardsView {
                dismissingController?.prepareForInteractiveDismiss()
                cardWidth = cardsView.bounds.width
            }
        } else {
            if let window = dismissingController?.view.window {
                dismissingController?.prepareForInteractiveDismiss()
                windowHeight = window.bounds.height
            }
        }
        dismissingController?.dismiss(animated: true, completion: nil)
    }
}
