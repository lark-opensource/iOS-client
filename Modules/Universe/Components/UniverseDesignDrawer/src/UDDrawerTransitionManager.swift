//
//  UDDrawerTransitionManager.swift
//  UniverseDesignDrawer
//
//  Created by 袁平 on 2021/3/12.
//

import Foundation
import UIKit

/// 侧滑方向枚举
public enum UDDrawerDirection {
    /// 从左往右
    case left
    /// 从右往左
    case right
}

public final class UDDrawerTransitionManager: NSObject, UIViewControllerTransitioningDelegate {
    private lazy var animator: UDDrawerTransitionAnimator = UDDrawerTransitionAnimator(type: .present, direction: host?.direction ?? .left)
    private lazy var interactPresent: UDDrawerTransitionInteractPresent = UDDrawerTransitionInteractPresent(direction: host?.direction ?? .left)
    var state: State = .none
    private var triggerType: UDDrawerTriggerType = .click()
    weak var drawer: UDDrawerContainerViewController?
    public weak var host: UDDrawerAddable?
    public var isDrawerShown: Bool {
        return state == .showing || state == .shown || state == .hidding
    }

    public init(host: UDDrawerAddable) {
        self.host = host
        super.init()
        animator.transitionManager = self
        interactPresent.transitionManager = self
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.type = .present
        animator.isInteract = interactPresent.isAnimating
        return animator
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.type = .dismiss
        animator.isInteract = interactPresent.isAnimating
        return animator
    }

    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactPresent.isAnimating ? interactPresent : nil
    }

    public func addDrawerEdgeGesture(to: UIView) {
        guard let host = self.host else { return }
        interactPresent.addDrawerEdgeGesture(to: to, present: { [weak host, weak self] in
            guard let self = self, let host = host else { return }
            self.triggerType = .pan
            let container = UDDrawerContainerViewController(subView: host.subView,
                                                            subVC: host.subCustomVC?(.pan) ?? host.subVC,
                                                            contentWidth: host.customContentWidth?(.pan) ?? host.contentWidth,
                                                            direction: host.direction)
            container.modalPresentationStyle = .custom
            container.transitionManager = self
            host.fromVC?.present(container, animated: true, completion: nil)
        }, contentWidth: host.contentWidth)
    }

    public func updateGestureEnable(isEnable: Bool) {
        interactPresent.updateGestureEnable(isEnabled: isEnable)
    }

    public func showDrawer() {
        showDrawer { }
    }

    public func showDrawer(_ type: UDDrawerTriggerType = .click(), completion: (() -> Void)?) {
        guard let host = self.host else { return }
        self.triggerType = type
        let container = UDDrawerContainerViewController(subView: host.subView,
                                                        subVC: host.subCustomVC?(type) ?? host.subVC,
                                                        contentWidth: host.customContentWidth?(type) ?? host.contentWidth,
                                                        direction: host.direction)
        container.modalPresentationStyle = .custom
        container.transitionManager = self
        host.fromVC?.present(container, animated: true, completion: completion)
    }

    public func hideDrawer(animate: Bool, completion: (() -> Void)?) {
        drawer?.dismiss(animated: animate, completion: { [weak self] in
            if !animate {
                self?.state = .hidden
            }
            completion?()
        })
    }

    public func updateDrawerWidth() {
        drawer?.updateDrawerWidth(contentWidth: host?.customContentWidth?(triggerType) ?? host?.contentWidth ?? UDDrawerValues.contentDefaultWidth)
    }
}

extension UDDrawerTransitionManager {
    enum State {
        case none
        case showing
        case shown
        case hidding
        case hidden
    }
}
