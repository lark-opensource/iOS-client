//
//  PopoverPresentationController.swift
//  MinutesFoundation
//
//  Created by chenlehui on 2021/8/10.
//

import UIKit

class PopoverPresentationController: UIPresentationController {
    var direction: PopoverArrowDirection = .auto
    var presentedSize: CGSize = .zero
    var sourceRect: CGRect = .zero
    var sourceRectBlock: (() -> CGRect)?
    public var sourceView: UIView = UIView()
    var dismissAnimated = true
    var dimmingAlpha: CGFloat = 0.5

    private lazy var dimmingView: UIView = {
        let dimmingView = UIView()
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.backgroundColor = UIColor(white: 0.0, alpha: dimmingAlpha)
        dimmingView.alpha = 0.0
        dimmingView.isUserInteractionEnabled = false
        return dimmingView
    }()

    private lazy var decorateView: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOffset = .zero
        v.layer.shadowOpacity = 0.3
        v.layer.shadowRadius = 50
        v.layer.cornerRadius = 10
        v.alpha = 0
        return v
    }()

    private lazy var tap: UITapGestureRecognizer = {
        let ges = UITapGestureRecognizer(target: self, action: #selector(dismissAction))
        ges.delegate = self
        return ges
    }()

    private lazy var pan: UIPanGestureRecognizer = {
        let ges = UIPanGestureRecognizer(target: self, action: #selector(dismissAction))
        ges.delegate = self
        return ges
    }()

    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, dimmingAlpha: CGFloat) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.dimmingAlpha = dimmingAlpha
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        let validRect = sourceRectBlock?() ?? sourceRect
        let sr = sourceView.convert(validRect, to: containerView)
        let containerBounds = (containerView?.bounds)!
        var x = CGFloat(0)
        var y = CGFloat(0)
        func modifierX(with x: CGFloat) -> CGFloat {
            var px = x
            if x + presentedSize.width + 16 > containerBounds.width {
                px = containerBounds.width - presentedSize.width - 16
            }
            if x < 16 {
                px = 16
            }
            return px
        }

        func modifierY(with y: CGFloat) -> CGFloat {
            var py = y
            if y + presentedSize.height + 16 > containerBounds.height {
                py = containerBounds.height - presentedSize.height - 16
            }
            if y < 16 {
                py = 16
            }
            return py
        }

        func checkDirection() -> PopoverArrowDirection {
            let partitionRect = PartitionRect(rect: containerBounds)
            return partitionRect.checkDirection(with: sr)
        }

        var direction = self.direction
        if direction == .auto {
            direction = checkDirection()
        }
        switch direction {
        case .up:
            x = sr.midX - presentedSize.width / 2
            y = sr.maxY
        case .down:
            x = sr.midX - presentedSize.width / 2
            y = sr.minY - presentedSize.height
        case .left:
            x = sr.maxX
            y = sr.midY - presentedSize.height / 2
        case .right:
            x = sr.minX - presentedSize.width
            y = sr.midY - presentedSize.height / 2
        default:
            break
        }
        let rect = CGRect(x: modifierX(with: x), y: modifierY(with: y), width: presentedSize.width, height: presentedSize.height)
        return rect
    }

    override func presentationTransitionWillBegin() {
        containerView?.addGestureRecognizer(tap)
        containerView?.addGestureRecognizer(pan)
        containerView?.insertSubview(dimmingView, at: 0)
        if dimmingAlpha == 0 {
            containerView?.insertSubview(decorateView, aboveSubview: dimmingView)
        }

        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1
            decorateView.alpha = 1
            return
        }
        coordinator.animate(alongsideTransition: { (_) in
            self.dimmingView.alpha = 1
            self.decorateView.alpha = 1
        }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0
            decorateView.alpha = 0
            return
        }
        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
            self.decorateView.alpha = 0
        })
    }

    override func containerViewWillLayoutSubviews() {
        let frame = frameOfPresentedViewInContainerView
        presentedView?.frame = frame
        decorateView.frame = frame
        decorateView.backgroundColor = presentedView?.backgroundColor
        dimmingView.frame = (containerView?.bounds)!
    }

    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        return CGSize(width: 100, height: 200)
    }

    @objc private func dismissAction() {
        presentingViewController.dismiss(animated: dismissAnimated)
    }
}

extension PopoverPresentationController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: containerView)
        if frameOfPresentedViewInContainerView.contains(point) {
            return false
        }
        return true
    }
}

extension PopoverPresentationController {

    struct PartitionRect {
        let top: CGRect
        let right: CGRect
        let bottom: CGRect
        let left: CGRect

        init(rect: CGRect) {
            let width = rect.width
            let height = rect.height / 3
            top = CGRect(x: 0, y: 0, width: width, height: height)
            right = CGRect(x: width / 2, y: height, width: width / 2, height: height)
            bottom = CGRect(x: 0, y: height * 2, width: width, height: height)
            left = CGRect(x: 0, y: height, width: width / 2, height: height)
        }

        func checkDirection(with sourceRect: CGRect) -> PopoverArrowDirection {
            let sourceCenter = sourceRect.center
            if top.contains(sourceCenter) {
                return .up
            }
            if right.contains(sourceCenter) {
                return .right
            }
            if bottom.contains(sourceCenter) {
                return .down
            }
            if left.contains(sourceCenter) {
                return .left
            }
            return .up
        }
    }
}
