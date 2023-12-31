//
//  RankViewTransitionManager.swift
//  AnimatedTabBar
//
//  Created by Hayden on 2020/12/1.
//

import Foundation
import UIKit

final class RankViewTransitionManager: NSObject, UIViewControllerTransitioningDelegate {

    var interactor = RankViewInteractiveDismissal()

    var isQuickLauncherEnabled: Bool

    lazy var animator = RankViewTransitionAnimator(
        transitionType: .present,
        isQuickLauncherEnabled: isQuickLauncherEnabled
    )

    init(controller: UIViewController, scrollView: UIScrollView? = nil, isQuickLauncherEnabled: Bool) {
        self.isQuickLauncherEnabled = isQuickLauncherEnabled
        super.init()
        self.interactor.controller = controller
        self.interactor.scrollView = scrollView
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        animator.type = .present
        return animator
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.type = .dismiss
        return animator
    }

    func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return interactor.inProgress ? interactor : nil
    }

}

final class RankViewTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    var transitionDuration: TimeInterval = 0.25

    enum TransitionType {
        case present
        case dismiss
    }

    var type: TransitionType

    var isQuickLauncherEnabled: Bool

    init(transitionType: TransitionType, isQuickLauncherEnabled: Bool) {
        self.type = transitionType
        self.isQuickLauncherEnabled = isQuickLauncherEnabled
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        switch type {
        case .present:  return transitionDuration
        case .dismiss:  return transitionDuration
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch type {
        case .present:  present(transitionContext)
        case .dismiss:  dismiss(transitionContext)
        }
    }

    private func present(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let toController = transitionContext.viewController(forKey: .to) as? RankViewController else { return }
        let toFrame = transitionContext.finalFrame(for: toController)
        toController.view.frame = toFrame
        transitionContext.containerView.addSubview(toController.view)
        let contentHeight = toFrame.height
        toController.container.backgroundView.alpha = 0
        toController.container.guideView.transform = CGAffineTransform(translationX: 0, y: contentHeight)
        toController.container.contentView.transform = CGAffineTransform(translationX: 0, y: contentHeight)
        if isQuickLauncherEnabled {
            toController.container.mockTabBar.transform = CGAffineTransform(translationX: 0, y: contentHeight)
        }
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
            toController.container.backgroundView.alpha = 1
            toController.container.mockTabBar.transform = .identity
            toController.container.guideView.transform = .identity
            toController.container.contentView.transform = .identity
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

    private func dismiss(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let fromController = transitionContext.viewController(forKey: .from) as? RankViewController else {
            return
        }
        let duration = transitionDuration(using: transitionContext)
        let fromFrame = transitionContext.initialFrame(for: fromController)
        transitionContext.containerView.addSubview(fromController.view)
        let contentHeight = fromFrame.height
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: { [weak self] in
            guard let self = self else { return }
            fromController.container.backgroundView.alpha = 0
            fromController.container.guideView.transform = CGAffineTransform(translationX: 0, y: contentHeight)
            fromController.container.contentView.transform = CGAffineTransform(translationX: 0, y: contentHeight)
            if self.isQuickLauncherEnabled {
                fromController.container.mockTabBar.transform = CGAffineTransform(translationX: 0, y: contentHeight)
            }
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

}

final class RankViewInteractiveDismissal: UIPercentDrivenInteractiveTransition {
    var inProgress = false

    weak var controller: UIViewController? {
        didSet {
            setupGestureRecognizer()
        }
    }

    weak var scrollView: UIScrollView?

    override init() {
        super.init()
        completionCurve = .easeOut
    }

    func setupGestureRecognizer() {
        guard let rankController = controller as? RankViewController else { return }
        let toolBar = rankController.container.navigationBar
        let pan = UIPanGestureRecognizer(target: self,
                                         action: #selector(self.handlePanGesture(_:)))
        pan.delegate = self
        toolBar.addGestureRecognizer(pan)
    }

    @objc
    private func handlePanGesture(_ sender: UIPanGestureRecognizer) {

        guard let view = sender.view else { return }
        let percentThreshold: CGFloat = 0.25
        let translation = sender.translation(in: view)
        let progress = translation.y / UIScreen.main.bounds.size.height

        if !inProgress { beginDismiss() }
        switch sender.state {
        case .began:
            break
        case .changed:
            update(progress)
        case .cancelled:
            cancelDismiss(progress)
        case .ended:
            progress > percentThreshold ? finishDismiss(progress) : cancelDismiss(progress)
        default:
            break
        }
    }

    private func beginDismiss() {
        self.inProgress = true
        scrollView?.isScrollEnabled = false
        controller?.dismiss(animated: true, completion: nil)
    }

    private func finishDismiss(_ progress: CGFloat) {
        inProgress = false
        scrollView?.isScrollEnabled = true
        completionSpeed = min(1.0, max(0.1, 1.0 - progress))
        finish()
    }

    private func cancelDismiss(_ progress: CGFloat) {
        inProgress = false
        completionSpeed = min(1.0, max(0.1, progress))
        cancel()
    }

}

extension RankViewInteractiveDismissal: UIGestureRecognizerDelegate, UIScrollViewDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}
