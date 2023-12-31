//
//  SlidePresentationManager.swift
//  SlidePresentation
//
//  Created by chenlehui on 2020/8/17.
//

import UIKit

public enum SlidePresentationStyle {
    public enum Direction {
        case top, left, bottom, right
    }

    case actionSheet(Direction)
    case alert(Direction)
}

public final class SlidePresentationManager: NSObject {

    public var style: SlidePresentationStyle
    public var animator: PresentationAnimator.Type
    public var presentedSize: CGSize
    public var isObserveKeyBoard = false
    public var dismissAnimated = true
    public var backgroundAlpha: CGFloat = 0.5
    public var keyBoardHeightOffset: CGFloat = 0.0
    public var isPanCloseEnabled = false
    public var isUsingSpring: Bool = false
    public var autoSize: (() -> CGSize)?

    public init(style: SlidePresentationStyle = .actionSheet(.bottom), presentedSize: CGSize = .zero, animator: PresentationAnimator.Type = SlidePresentationAnimator.self, isObserveKeyBoard: Bool = false, keyBoardHeightOffset: CGFloat = 0.0) {
        self.style = style
        self.animator = animator
        self.presentedSize = presentedSize
        self.isObserveKeyBoard = isObserveKeyBoard
        self.keyBoardHeightOffset = keyBoardHeightOffset
        super.init()
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension SlidePresentationManager: UIViewControllerTransitioningDelegate {

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = SlidePresentationController(presentedViewController: presented, presenting: presenting, style: style, presentedSize: presentedSize, isObserveKeyBoard: isObserveKeyBoard, keyBoardHeightOffset: keyBoardHeightOffset, dimmingAlpha: backgroundAlpha)
        presentationController.dismissAnimated = dismissAnimated
        presentationController.isPanCloseEnabled = isPanCloseEnabled
        presentationController.autoSize = autoSize
        return presentationController
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animator.init(style: style, isPresentation: true, isUsingSpring: isUsingSpring) as? UIViewControllerAnimatedTransitioning
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animator.init(style: style, isPresentation: false, isUsingSpring: false) as? UIViewControllerAnimatedTransitioning
    }
}
