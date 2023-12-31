//
//  UDPopover.swift
//  UniverseDesignPopover
//
//  Created by 姚启灏 on 2020/11/23.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignColor

public final class UDPopoverTransition: NSObject,
                                  UIViewControllerTransitioningDelegate,
                                  UIPopoverPresentationControllerDelegate {

    /// vc 在 compact 模式下的显示样式
    public enum PresentStypeInCompact {
        case fullScreen         // 全屏
        case overFullScreen     // 悬浮全屏
        case none               // Popover

        var style: UIModalPresentationStyle {
            switch self {
            /// full Screen
            case .fullScreen:
                return .fullScreen
            /// over Full Screen
            case .overFullScreen:
                return .overFullScreen
            /// none
            case .none:
                return .none
            }
        }
    }

    /// 是否显示 Dimming 黑色背景
    public var showDimmingView: Bool = true

    public var dismissCompletion: (() -> Void)?

    /// 视图在 C 视图中的显示样式
    public var presentStypeInCompact: PresentStypeInCompact = .overFullScreen

    public lazy var dimmingView: UIView = {
        let dimmingView = UIView()
        dimmingView.backgroundColor = UDColor.bgMask
        return dimmingView
    }()

    weak var sourceView: UIView?
    weak var barButtonItem: UIBarButtonItem?
    var sourceRect: CGRect?
    var permittedArrowDirections: UIPopoverArrowDirection?

    public init(
        sourceView: UIView?,
        sourceRect: CGRect? = nil,
        permittedArrowDirections: UIPopoverArrowDirection? = nil,
        dismissCompletion: (() -> Void)? = nil
    ) {
        super.init()
        self.sourceView = sourceView
        self.sourceRect = sourceRect
        self.permittedArrowDirections = permittedArrowDirections
        self.dismissCompletion = dismissCompletion
    }

    public init(
        barButtonItem: UIBarButtonItem,
        sourceRect: CGRect? = nil,
        permittedArrowDirections: UIPopoverArrowDirection? = nil,
        dismissCompletion: (() -> Void)? = nil
    ) {
        super.init()
        self.barButtonItem = barButtonItem
        self.sourceRect = sourceRect
        self.permittedArrowDirections = permittedArrowDirections
        self.dismissCompletion = dismissCompletion
    }

    public func presentationController(forPresented presented: UIViewController,
                                       presenting: UIViewController?,
                                       source: UIViewController) -> UIPresentationController? {
        let vc = UDPopoverPresentationController(presentedViewController: presented,
                                                 presenting: presenting,
                                                 dismissCompletion: dismissCompletion)
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
        vc.delegate = self
        return vc
    }

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        UDPanelStylePresentationTransitioning(dimmingView: showDimmingView ? dimmingView : nil)
    }

    public func animationController(forDismissed dismissed: UIViewController) ->
    UIViewControllerAnimatedTransitioning? {
        UDPanelStyleDismissalTransitioning(dimmingView: showDimmingView ? dimmingView : nil)
    }

    public func adaptivePresentationStyle(for controller: UIPresentationController,
                                          traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if traitCollection.horizontalSizeClass == .regular, UIDevice.current.userInterfaceIdiom == .pad {
            return .popover
        } else {
            return self.presentStypeInCompact.style
        }
    }
}

private class UDPopoverPresentationController: UIPopoverPresentationController {

    weak var dimmingView: UIView?
    var dismissCompletion: (() -> Void)?

    init(presentedViewController: UIViewController,
         presenting presentingViewController: UIViewController?,
         dismissCompletion: (() -> Void)? = nil) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.dismissCompletion = dismissCompletion
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

    public override func dismissalTransitionDidEnd(_ completed: Bool) {
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
        dismissCompletion?()
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
    }

    override func adaptivePresentationStyle(for traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        let superStyle = super.adaptivePresentationStyle(for: traitCollection)
        return self.delegate?.adaptivePresentationStyle?(for: self, traitCollection: traitCollection) ?? superStyle
    }
}
