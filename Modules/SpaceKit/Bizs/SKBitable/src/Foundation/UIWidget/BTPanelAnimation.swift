//
//  SKPanelAnimationController.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/1/15.
//

import UIKit
import SKUIKit
import SnapKit
import UniverseDesignColor

public protocol BTPanelAnimationCustumDurationType {
    var duration: TimeInterval { get set }
}

public protocol BTPanelAnimationController: UIViewController {
    var animationContentView: UIView { get }
}

public final class BTPanelAnimation: NSObject, UIViewControllerAnimatedTransitioning, UINavigationControllerDelegate {

    public enum TransitionType {
        case present
        case dismiss
    }

    private var navigationOperation: UINavigationController.Operation?
    private var transitionType: TransitionType?
    private let duration: TimeInterval
    private var showMask: Bool {
        didSet {
            backgroundMaskView.isHidden = !showMask
        }
    }

    private lazy var backgroundMaskView = UIView().construct { it in
        it.backgroundColor = UDColor.bgMask
    }

    public init(transitionType: TransitionType?, duration: TimeInterval = 0.25, showMask: Bool = true) {
        self.transitionType = transitionType
        self.duration = duration
        self.showMask = showMask
    }

    public init(navigationOperation: UINavigationController.Operation?, duration: TimeInterval = 0.25, showMask: Bool = true) {
        self.navigationOperation = navigationOperation
        self.duration = duration
        self.showMask = showMask
    }

    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        navigationOperation = operation
        return self
    }

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if let transitionType = transitionType {
            switch transitionType {
            case .present:
                present(using: transitionContext)
            case .dismiss:
                dismiss(using: transitionContext)
            }

            return
        }

        if let navigationOperation = navigationOperation {
            switch navigationOperation {
            case .push:
                push(using: transitionContext)
            case .pop:
                pop(using: transitionContext)
            default:
                break
            }
        }
    }

    private func present(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        containerView.backgroundColor = .clear

        containerView.addSubview(backgroundMaskView)
        backgroundMaskView.isHidden = !showMask
        backgroundMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let toVC: BTPanelAnimationController
        if let toController = transitionContext.viewController(forKey: .to) as? BTPanelAnimationController {
            toVC = toController
            containerView.addSubview(toVC.view)
            toVC.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            containerView.layoutIfNeeded()
        } else if let toController = transitionContext.viewController(forKey: .to) as? UINavigationController,
                  let rootController = toController.topViewController as? BTPanelAnimationController {
            toVC = rootController
            containerView.addSubview(toController.view)
            toController.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            containerView.layoutIfNeeded()
        } else {
            assertionFailure("to view controller is not a BTPanelAnimationController")
            return
        }
        backgroundMaskView.backgroundColor = UDColor.bgMask.withAlphaComponent(0)
        toVC.animationContentView.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(toVC.animationContentView.frame.height)
        }
        toVC.view.layoutIfNeeded()

        UIView.animate(withDuration: transitionDuration(using: transitionContext)) {
            self.backgroundMaskView.backgroundColor = UDColor.bgMask
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
        let fromVC: BTPanelAnimationController
        if let fromController = transitionContext.viewController(forKey: .from) as? BTPanelAnimationController {
            fromVC = fromController
        } else if let fromController = transitionContext.viewController(forKey: .from) as? UINavigationController,
                  let rootController = fromController.topViewController as? BTPanelAnimationController {
            fromVC = rootController
        } else {
            assertionFailure("from view controller is not a BTPanelAnimationController")
            return
        }

        UIView.animate(withDuration: transitionDuration(using: transitionContext)) {
            self.backgroundMaskView.backgroundColor = UDColor.bgMask.withAlphaComponent(0)
            fromVC.animationContentView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(fromVC.animationContentView.frame.height)
            }
            fromVC.view.layoutIfNeeded()
        } completion: { completed in
            transitionContext.completeTransition(completed)
        }
    }

    private func push(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard let toView = transitionContext.view(forKey: .to),
              let toVC = transitionContext.viewController(forKey: .to) else {
            return
        }
        containerView.backgroundColor = .clear

        containerView.addSubview(toView)
        toView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().offset(containerView.frame.width)
        }
        containerView.layoutIfNeeded()
        let duration = (toVC as? BTPanelAnimationCustumDurationType)?.duration ?? transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration) {
            toView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            containerView.layoutIfNeeded()
        } completion: { completed in
            transitionContext.completeTransition(completed)
        }
    }

    private func pop(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        containerView.backgroundColor = .clear

        guard let fromView = transitionContext.view(forKey: .from),
              let fromVC = transitionContext.viewController(forKey: .from),
              let toView = transitionContext.view(forKey: .to) else { return }

        containerView.insertSubview(toView, belowSubview: fromView)
        toView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        containerView.layoutIfNeeded()
        let duration = (fromVC as? BTPanelAnimationCustumDurationType)?.duration ?? transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration) {
            fromView.frame.origin.x += fromView.frame.width
        } completion: { completed in
            transitionContext.completeTransition(completed)
        }
    }
}

// 提供 overFullScreen 的动画效果，如果是 popover，系统会自动用默认动画
public final class BTPanelTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    private var shouldShowAlphaMask: Bool = true
    
    public init(
        shouldShowAlphaMask: Bool = true
    ) {
        self.shouldShowAlphaMask = shouldShowAlphaMask
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BTPanelAnimation(transitionType: .present, showMask: shouldShowAlphaMask)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BTPanelAnimation(transitionType: .dismiss, showMask: shouldShowAlphaMask)
    }
}
