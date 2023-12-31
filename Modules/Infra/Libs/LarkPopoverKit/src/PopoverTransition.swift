//
//  PopoverTransition.swift
//  LarkLocalizations
//
//  Created by 李晨 on 2020/3/19.
//

import Foundation
import UIKit
import SnapKit

/*
 PopoverTransition 适用于
 在 R 视图中显示为 popover
 可以配置在 C 视图中显示 Style
 可以配置在 C 视图中是否存在黑色渐变背景

 Demo：
    let transitioningDelegate = PopoverTransition(sourceView: sender)
    var vc = UIViewController()
    vc.modalPresentationStyle = .custom
    vc.transitioningDelegate = transitioningDelegate
    self.present(vc, animated: true, completion: nil)
 */

public final class PopoverTransition: NSObject, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate {

    /// vc 在 compact 模式下的显示样式
    public enum PresentStypeInCompact {
        case fullScreen         // 全屏
        case overFullScreen     // 悬浮全屏
        case none               // Popover

        var style: UIModalPresentationStyle {
            switch self {
                case .fullScreen:
                    return .fullScreen
                case .overFullScreen:
                    return .overFullScreen
                case .none:
                    return .none
            }
        }
    }

    /// 是否显示 Dimming 黑色背景
    public var showDimmingView: Bool = true

    /// 视图在 C 视图中的显示样式
    public var presentStypeInCompact: PresentStypeInCompact = .overFullScreen

    lazy var dimmingView: UIView = {
        let dimmingView = UIView()
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        return dimmingView
    }()

    lazy var presentAnimatedTransition: PopoverPresentAnimatedTransitioning = {
        var transition = PopoverPresentAnimatedTransitioning()
        if self.showDimmingView {
            transition.dimmingView = self.dimmingView
        }
        return transition
    }()
    lazy var dismissAnimatedTransition: PopoverDismissAnimatedTransitioning = {
        var transition = PopoverDismissAnimatedTransitioning()
        if self.showDimmingView {
            transition.dimmingView = self.dimmingView
        }
        return transition
    }()

    weak var sourceView: UIView?
    weak var barButtonItem: UIBarButtonItem?
    var sourceRect: CGRect?
    var permittedArrowDirections: UIPopoverArrowDirection?
    /// 用于配置popover箭头背景色
    var backgroundColor: UIColor?

    public init(
        sourceView: UIView,
        sourceRect: CGRect? = nil,
        permittedArrowDirections: UIPopoverArrowDirection? = nil,
        backgroundColor: UIColor? = nil
    ) {
        super.init()
        self.sourceView = sourceView
        self.sourceRect = sourceRect
        self.permittedArrowDirections = permittedArrowDirections
        self.backgroundColor = backgroundColor
    }

    public init(
        barButtonItem: UIBarButtonItem,
        sourceRect: CGRect? = nil,
        permittedArrowDirections: UIPopoverArrowDirection? = nil,
        backgroundColor: UIColor? = nil
    ) {
        super.init()
        self.barButtonItem = barButtonItem
        self.sourceRect = sourceRect
        self.permittedArrowDirections = permittedArrowDirections
        self.backgroundColor = backgroundColor
    }

    public func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController) -> UIPresentationController?
    {
        let vc = PopoverController(presentedViewController: presented, presenting: presenting)
        vc.dimmingView = self.dimmingView
        if let sourceView = self.sourceView {
            vc.sourceView = sourceView
        }
        if let barButtonItem = self.barButtonItem {
            vc.barButtonItem = barButtonItem
        }
        if let sourceRect = self.sourceRect {
            vc.sourceRect = sourceRect
        }
        if let permittedArrowDirections = self.permittedArrowDirections {
            vc.permittedArrowDirections = permittedArrowDirections
        }
        if let backgroundColor = self.backgroundColor {
            vc.backgroundColor = backgroundColor
        }
        vc.delegate = self
        return vc
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController)-> UIViewControllerAnimatedTransitioning?
    {
        return presentAnimatedTransition
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissAnimatedTransition
    }

    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if traitCollection.horizontalSizeClass == .regular {
            return .popover
        } else {
            return self.presentStypeInCompact.style
        }
    }
}

final class PopoverPresentAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {

    weak var dimmingView: UIView?

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = UITransitionContextViewControllerKey.to
        guard let controller = transitionContext.viewController(forKey: key) else {
            return
        }

        if let dimmingView = dimmingView {
            transitionContext.containerView.addSubview(dimmingView)
            dimmingView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            dimmingView.layoutIfNeeded()
        }

        transitionContext.containerView.addSubview(controller.view)
        controller.view.frame = transitionContext.containerView.bounds

        controller.view.transform = CGAffineTransform(
            translationX: 0,
            y: controller.view.bounds.height)
        controller.view.alpha = 0
        self.dimmingView?.alpha = 0

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: { [weak self] in
            controller.view.transform =  CGAffineTransform.identity
            controller.view.alpha = 1
            self?.dimmingView?.alpha = 1
        }, completion: { transitionContext.completeTransition($0) })
    }
}

final class PopoverDismissAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {

    weak var dimmingView: UIView?

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key =  UITransitionContextViewControllerKey.from
        guard let controller = transitionContext.viewController(forKey: key) else { return }

        controller.view.transform = CGAffineTransform.identity
        controller.view.alpha = 1
        self.dimmingView?.alpha = 1

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: { [weak self] in
            controller.view.transform = CGAffineTransform(
                translationX: 0,
                y: controller.view.bounds.height
            )
            controller.view.alpha = 0
            self?.dimmingView?.alpha = 0
        }, completion: { [weak self] in
            transitionContext.completeTransition($0)
            self?.dimmingView?.removeFromSuperview()
        })
    }
}

private final class PopoverController: UIPopoverPresentationController {

    weak var dimmingView: UIView?

    override init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .dimmed
        if let dimmingView = self.dimmingView {
            dimmingView.removeFromSuperview()
        }
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .automatic
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        let vc = self.presentedViewController
        if !vc.isBeingDismissed {
            if let containerView = self.presentedViewController.view.superview,
                let dimmingView = self.dimmingView {
                containerView.insertSubview(dimmingView, at: 0)
                dimmingView.snp.makeConstraints { (maker) in
                    maker.edges.equalToSuperview()
                }
                dimmingView.layoutIfNeeded()
            }
        }
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
    }
}
