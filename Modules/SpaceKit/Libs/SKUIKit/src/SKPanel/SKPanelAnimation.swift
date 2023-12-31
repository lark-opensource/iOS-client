//
//  SKPanelAnimationController.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/1/15.
//

import UIKit
import SnapKit

public protocol SKPanelAnimationController: UIViewController {
    var animationBackgroundColor: UIColor { get }
    var animationBackgroundView: UIView { get }
    var animationContentView: UIView { get }
}

public final class SKPanelAnimation: NSObject, UIViewControllerAnimatedTransitioning {

    public enum TransitionType {
        case present
        case dismiss
    }

    private let transitionType: TransitionType
    private let duration: TimeInterval

    public init(transitionType: TransitionType, duration: TimeInterval = 0.25) {
        self.transitionType = transitionType
        self.duration = duration
    }

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch transitionType {
        case .present:
            present(using: transitionContext)
        case .dismiss:
            dismiss(using: transitionContext)
        }
    }

    private func present(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        containerView.backgroundColor = .clear
        let toVC: SKPanelAnimationController
        if let toController = transitionContext.viewController(forKey: .to) as? SKPanelAnimationController {
            toVC = toController
            containerView.addSubview(toVC.view)
            toVC.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            containerView.layoutIfNeeded()
        } else if let toController = transitionContext.viewController(forKey: .to) as? UINavigationController,
                  let rootController = toController.topViewController as? SKPanelAnimationController {
            toVC = rootController
            containerView.addSubview(toController.view)
            toController.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            containerView.layoutIfNeeded()
        } else {
            assertionFailure("to view controller is not a SKPanelAnimationController")
            return
        }
        // 如果中了布局assert，检查present的VC transitioningDelegate是否设置正确
        toVC.animationBackgroundView.backgroundColor = toVC.animationBackgroundColor.withAlphaComponent(0)
        toVC.animationContentView.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(toVC.animationContentView.frame.height)
        }
        toVC.view.layoutIfNeeded()

        UIView.animate(withDuration: transitionDuration(using: transitionContext)) {
            toVC.animationBackgroundView.backgroundColor = toVC.animationBackgroundColor
            toVC.animationContentView.snp.updateConstraints { make in
                make.bottom.equalToSuperview()
            }
            toVC.view.layoutIfNeeded()
        } completion: { completed in
            transitionContext.completeTransition(completed)
        }

    }

    private func dismiss(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        containerView.backgroundColor = .clear
        let fromVC: SKPanelAnimationController
        if let fromController = transitionContext.viewController(forKey: .from) as? SKPanelAnimationController {
            fromVC = fromController
        } else if let fromController = transitionContext.viewController(forKey: .from) as? UINavigationController,
                  let rootController = fromController.topViewController as? SKPanelAnimationController {
            fromVC = rootController
        } else {
            assertionFailure("from view controller is not a SKPanelAnimationController")
            return
        }

        UIView.animate(withDuration: transitionDuration(using: transitionContext)) {
            fromVC.animationBackgroundView.backgroundColor = fromVC.animationBackgroundColor.withAlphaComponent(0)
            fromVC.animationContentView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(fromVC.animationContentView.frame.height)
            }
            fromVC.view.layoutIfNeeded()
        } completion: { completed in
            transitionContext.completeTransition(completed)
        }
    }
}

// 提供 overFullScreen 的动画效果，如果是 popover，系统会自动用默认动画
public final class SKPanelTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SKPanelAnimation(transitionType: .present)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SKPanelAnimation(transitionType: .dismiss)
    }
}

// 提供 overFullScreen 的动画效果，如果是 formSheet 或 popover，转场动画交由系统负责
public final class SKPanelFormSheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // 当modalPresentationStyle为formSheet，且在 iPad R 视图，转场动画交由系统负责
        if presented.modalPresentationStyle == .formSheet,
           SKDisplay.pad,
           presenting.isMyWindowRegularSize() {
            return nil
        }
        return SKPanelAnimation(transitionType: .present)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // 当modalPresentationStyle为formSheet，且在 iPad R 视图，转场动画交由系统负责
        if dismissed.modalPresentationStyle == .formSheet,
           SKDisplay.pad,
           dismissed.isMyWindowRegularSize() {
            return nil
        }
        return SKPanelAnimation(transitionType: .dismiss)
    }
}

// 提供 formSheet/popover 降级为 overFullScreen/overCurrentContext 的转换效果
public final class SKPanelAdaptivePresentationDelegate: NSObject, UIAdaptivePresentationControllerDelegate {

    public var styleToModify: [UIModalPresentationStyle]
    public var downgradeStyle: UIModalPresentationStyle

    public static var `default`: SKPanelAdaptivePresentationDelegate {
        return SKPanelAdaptivePresentationDelegate(from: [.popover, .formSheet, .pageSheet], to: .overFullScreen)
    }

    public init(from originStyle: [UIModalPresentationStyle], to downgradeStyle: UIModalPresentationStyle) {
        styleToModify = originStyle
        self.downgradeStyle = downgradeStyle
        super.init()
    }

    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        switch traitCollection.horizontalSizeClass {
        case .unspecified:
            return .none
        case .compact:
            guard styleToModify.contains(controller.presentationStyle) else {
                assertionFailure("presentationStyle should be contains in styleToModify")
                return .none
            }
            return downgradeStyle
        case .regular:
            return .none
        @unknown default:
            return .none
        }
    }
}
