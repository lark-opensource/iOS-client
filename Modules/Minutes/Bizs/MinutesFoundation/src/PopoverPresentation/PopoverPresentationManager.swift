//
//  PopoverPresentationManager.swift
//  MinutesFoundation
//
//  Created by chenlehui on 2021/8/10.
//

import UIKit

public enum PopoverArrowDirection {
    case auto
    case up
    case down
    case left
    case right
}

public final class PopoverPresentationManager: NSObject {
    public var direction: PopoverArrowDirection = .auto
    public var presentedSize: CGSize = .zero
    public var sourceRect: CGRect = .zero
    public var sourceRectBlock: (() -> CGRect)?
    public var sourceView: UIView = UIView()
    public var dismissAnimated = true
    public var backgroundAlpha: CGFloat = 0.5
    public var isUsingSpring: Bool = false

    public override init() {
        super.init()
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension PopoverPresentationManager: UIViewControllerTransitioningDelegate {

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = PopoverPresentationController(presentedViewController: presented, presenting: presenting, dimmingAlpha: backgroundAlpha)
        presentationController.direction = direction
        presentationController.presentedSize = presentedSize
        presentationController.sourceRect = sourceRect
        presentationController.sourceView = sourceView
        presentationController.sourceRectBlock = sourceRectBlock
        return presentationController
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PopoverPresentationAnimator(isPresentation: true)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PopoverPresentationAnimator(isPresentation: false)
    }
}
