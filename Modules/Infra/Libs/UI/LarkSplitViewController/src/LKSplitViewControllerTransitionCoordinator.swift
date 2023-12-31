//
//  LKSplitViewControllerTransitionCoordinator.swift
//  LarkSplitViewController
//
//  Created by 邱沛 on 2020/5/29.
//

import UIKit
import Foundation

final class LKSplitViewControllerTransitionCoordinator: NSObject, UIViewControllerTransitionCoordinator {

    // MARK: Stored callback
    private(set) var alongsideAnimations: [((UIViewControllerTransitionCoordinatorContext) -> Void)] = []

    private(set) var alongsideCompletions: [((UIViewControllerTransitionCoordinatorContext) -> Void)] = []

    // MARK: Internal

    var context: LKSplitViewControllerTransitionCoordinatorContext

    init(container: UIView) {
        self.context = LKSplitViewControllerTransitionCoordinatorContext(container: container)
        super.init()
    }

    // MARK: Internal Interface

    func doAlongsideAnimation(removeCallbackAfterUse: Bool = true) {
        alongsideAnimations.forEach { [weak self] in
            guard let self = self else { return }
            $0(self.context)
        }
        if removeCallbackAfterUse {
            alongsideAnimations.removeAll()
        }
    }

    func doAlongsideCompletion(removeCallbackAfterUse: Bool = true) {
        alongsideCompletions.forEach { [weak self] in
            guard let self = self else { return }
            $0(self.context)
        }
        if removeCallbackAfterUse {
            alongsideCompletions.removeAll()
        }
    }

    // MARK: System Interface

    func animate(
        alongsideTransition animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)? = nil
    ) -> Bool {
        if let animation = animation {
            self.alongsideAnimations.append(animation)
        }
        if let completion = completion {
            self.alongsideCompletions.append(completion)
        }
        return true
    }

    func animateAlongsideTransition(
        in view: UIView?,
        animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)? = nil
    ) -> Bool {
        // No need for implement this
        return false
    }

    func notifyWhenInteractionEnds(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {
        // Not interactivelly, no need for implement this
    }

    func notifyWhenInteractionChanges(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {
        // Not interactivelly, no need for implement this
    }

    var isAnimated: Bool {
           get { return context.isAnimated }
           set { context.isAnimated = newValue }
       }

    var presentationStyle: UIModalPresentationStyle {
           get { return context.presentationStyle }
           set { context.presentationStyle = newValue }
       }

    var initiallyInteractive: Bool {
           get { return context.initiallyInteractive }
           set { context.initiallyInteractive = newValue }
       }

    var isInterruptible: Bool {
           get { return context.isInterruptible }
           set { context.isInterruptible = newValue }
       }

    var isInteractive: Bool {
           get { return context.isInteractive }
           set { context.isInteractive = newValue }
       }

    var isCancelled: Bool {
           get { return context.isCancelled }
           set { context.isCancelled = newValue }
       }

    // Should be set by invoker
    var transitionDuration: TimeInterval {
           get { return context.transitionDuration }
           set { context.transitionDuration = newValue }
       }

    // Not interactivelly, no need for implement this
    var percentComplete: CGFloat {
           get { return context.percentComplete }
           set { context.percentComplete = newValue }
       }

    // Not interactivelly
    var completionVelocity: CGFloat {
        get { return context.completionVelocity }
        set { context.completionVelocity = newValue }
    }

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        return context.viewController(forKey: key)
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        return context.view(forKey: key)
    }

    var targetTransform: CGAffineTransform {
        get { return context.targetTransform }
        set { context.targetTransform = newValue }
    }

    var containerView: UIView {
        get { return context.containerView }
        set { context.containerView = newValue }
    }

    // Use default animation curve by default
    var completionCurve: UIView.AnimationCurve {
        get { return context.completionCurve }
        set { context.completionCurve = newValue }
    }
}
