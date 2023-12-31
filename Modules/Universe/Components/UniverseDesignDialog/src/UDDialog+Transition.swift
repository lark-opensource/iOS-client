//
//  UDDialog+Transition.swift
//  UniverseDesignDialog
//
//  Created by 姚启灏 on 2020/10/14.
//

import Foundation
import UIKit
import UniverseDesignColor

public final class UDDialogPresentationController: UIPresentationController {

    var dimmingView = UIView()

    override public init(presentedViewController: UIViewController,
                         presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.dimmingView.backgroundColor = UDDialogColorTheme.dialogMaskBgColor
    }

    override public func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .dimmed
        self.dimmingView.alpha = 0
        self.containerView?.addSubview(self.dimmingView)
        let coordinator = self.presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1
        }, completion: { _ in
            /// alongsideTransition 可能会执行失败，如果业务方是在viewWillAppear触发（非预期，正确使用不应该在此调用），还没加到navi里
            /// 为了兼容业务不正确使用，只好在组件补偿失败的情况下也执行下动画
            /// https://stackoverflow.com/questions/29017047/when-using-uiviewcontrollertransitioncoordinator-animatealongsidetransitioncom
            UIView.animate(withDuration: coordinator?.transitionDuration ?? 0.25) {
                self.dimmingView.alpha = 1
            }
        })
    }

    override public func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .automatic
        let coordinator = self.presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        })
    }

    override public func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if let containerView = self.containerView {
            self.dimmingView.frame = CGRect(origin: .zero, size: .square(max(containerView.frame.width, containerView.frame.height)))
        }
    }
}

class UDDialogTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    lazy var dimmingView: UIView = {
        let dimmingView = UIView()
        dimmingView.backgroundColor = UDColor.bgMask
        return dimmingView
    }()
    
    public func presentationController(forPresented presented: UIViewController,
                                       presenting: UIViewController?,
                                       source: UIViewController)
        -> UIPresentationController? {
            let vc = UDDialogPresentationController(presentedViewController: presented, presenting: presenting)
            vc.dimmingView = dimmingView
            return vc
    }

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            return UDDialogAnimator(isPresenting: true)
    }

    public func animationController(forDismissed dismissed: UIViewController) ->
        UIViewControllerAnimatedTransitioning? {
        return UDDialogAnimator(isPresenting: false)
    }
}

public final class UDDialogAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool

    public init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = isPresenting ? UITransitionContextViewControllerKey.to : UITransitionContextViewControllerKey.from
        let controller = transitionContext.viewController(forKey: key)!
        controller.view.frame = transitionContext.containerView.bounds

        if isPresenting {
            transitionContext.containerView.addSubview(controller.view)
        }

        controller.view.transform = isPresenting ? CGAffineTransform(scaleX: 0.3, y: 0.3) : CGAffineTransform.identity
        controller.view.alpha = isPresenting ? 0 : 1
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            controller.view.transform = self.isPresenting ? CGAffineTransform.identity :
                CGAffineTransform(scaleX: 0.3, y: 0.3)
            controller.view.alpha = self.isPresenting ? 1 : 0
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
