//
//  LKSplitViewControllerTransitionCoordinatorContext.swift
//  LarkSplitViewController
//
//  Created by 邱沛 on 2020/5/29.
//

import UIKit
import Foundation

final class LKSplitViewControllerTransitionCoordinatorContext: NSObject, UIViewControllerTransitionCoordinatorContext {

    var containerView: UIView

    init(container: UIView) {
        self.containerView = container
        super.init()
    }

    var isAnimated: Bool = true

    var presentationStyle: UIModalPresentationStyle = .custom

    var initiallyInteractive: Bool = false

    var isInterruptible: Bool = false

    var isInteractive: Bool = false

    var isCancelled: Bool = false

    // Should be set by invoker
    var transitionDuration: TimeInterval = 0.0

    // Not interactivelly, no need for implement this
    var percentComplete: CGFloat = 0.0

    // Not interactivelly
    var completionVelocity: CGFloat = 0

    // Use default animation curve by default
    var completionCurve: UIView.AnimationCurve = .easeInOut

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        // Don't depend on this of SplitViewController, it's not a system-based transition
        return nil
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        // Don't depend on this of SplitViewController, it's not a system-based transition
        return nil
    }

    var targetTransform: CGAffineTransform = .identity
}
