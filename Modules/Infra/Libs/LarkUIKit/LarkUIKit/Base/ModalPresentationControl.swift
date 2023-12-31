//
//  ModalPresentationControl.swift
//  LarkUIKit
//
//  Created by 李晨 on 2020/1/19.
//

import UIKit
import Foundation

extension UIViewController {
    private struct AssociatedKeys {
        static var modalPresentationControl = "ModalPresentationControl"
    }

    public var modalPresentationControl: ModalPresentationControl {
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.modalPresentationControl,
                newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            if let control = objc_getAssociatedObject(
                self, &AssociatedKeys.modalPresentationControl
                ) as? ModalPresentationControl {
                return control
            }
            let control = ModalPresentationControl(vc: self)
            self.modalPresentationControl = control
            return control
        }
    }
}

/// 在 iPad 设备中, 当 ModalPresentationStyle 为 formSheet 或者 pageSheet 的时候
/// ModalPresentationControl 提供添加点击空白区域自动 dismiss 的能力
public final class ModalPresentationControl: NSObject, UIGestureRecognizerDelegate {

    /// dismiss tap 手势在一下 ModalPresentationStyle 时可以被响应
    let handleStyle: [UIModalPresentationStyle] = [.pageSheet, .formSheet]

    weak var viewController: UIViewController?

    lazy var dismissTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissIfNeeded)
        )
        tap.delegate = self
        tap.isEnabled = false
        return tap
    }()

    /// 是否支持点击外部自动 dismiss， 默认为关闭
    public var dismissEnable: Bool = false {
        didSet {
            self.updateDismissTapEnable()
            if readyToControl {
                self.addTapGestureIfNeeded()
            }
        }
    }

    /// dismiss 是否使用动画，默认为 true
    public var dismissAnimation: Bool = true

    /// dismiss 之后 callback 回调
    public var dismissCallback: (() -> Void)?

    /// 动态判断是否响应点击 dismiss, 默认实现为始终响应
    public var handleDismiss: () -> Bool = { return true }

    private var readyToControl: Bool = false

    public init(vc: UIViewController) {
        self.viewController = vc
        super.init()
    }

    /// 设置好 ready 状态之后，才可以开启点击空白自动 dismiss
    /// 这里必须在 vc.view window 不为空的时候调用ModalPresentation
    public func readyToControlIfNeeded() {
        /// 检测是否需要开启控制
        guard !readyToControl,
            self.needPresentationControl() else {
            return
        }
        /// 检测方法调用时机是否正确
        guard let vc = self.viewController,
            vc.isViewLoaded,
            vc.view.window != nil else {
            assertionFailure("目前的设计必须保证在 vc.view window 不为 nil 时调用")
            return
        }
        readyToControl = true
        /// 更新手势 enable
        self.updateDismissTapEnable()
        /// 判断是否可以添加手势
        self.addTapGestureIfNeeded()
    }

    @objc
    func dismissIfNeeded() {
        let dismissCallback = self.dismissCallback
        viewController?.dismiss(
            animated: self.dismissAnimation,
            completion: {
                dismissCallback?()
            }
        )
    }

    private func addTapGestureIfNeeded() {
        if self.dismissTap.view == nil,
            let vc = self.viewController {
            /// 找出当前 presented vc 最外层动画容器
            var lastView: UIView = vc.view
            while let superview = lastView.superview,
                !(superview is UIWindow) {
                lastView = superview
            }
            if lastView != vc.view {
                lastView.addGestureRecognizer(self.dismissTap)
            }
        }
    }

    private func updateDismissTapEnable() {
        /// 容器 vc 默认开启手势
        if self.isContainerVC() {
            self.dismissTap.isEnabled = true
        } else {
            self.dismissTap.isEnabled = dismissTapEnable()
        }
    }

    /// 判断是否是容器 vc, 目前只判断 navigation
    private func isContainerVC() -> Bool {
        if let vc = self.viewController,
            vc is UINavigationController {
            return true
        }
        return false
    }

    /// 容器 vc subvc
    private func subViewController() -> UIViewController? {
        if let vc = (self.viewController as? UINavigationController)?.topViewController {
           return vc
        }
        return nil
    }

    /// 是否需要开启控制
    private func needPresentationControl() -> Bool {
        guard Display.pad,
            let vc = self.viewController,
            vc.parent == nil,
            vc.presentingViewController != nil,
            self.handleStyle.contains(vc.modalPresentationStyle) else {
               return false
        }
        return true
    }

    /// 点击手势是否可以生效
    private func dismissTapEnable() -> Bool {
        guard self.needPresentationControl() else {
            return false
        }
        /// 如果 dismissEnable 为 true，直接开启
        if self.dismissEnable {
            return true
        }
        /// 如果存在 subvc， 判断 subvc dismissEnable
        else if let subVC = self.subViewController() {
            return subVC.modalPresentationControl.dismissEnable
        }
        return false
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let vc = self.viewController,
            dismissTapEnable() else {
            return false
        }
        let location = gestureRecognizer.location(in: vc.view)
        return !vc.view.bounds.contains(location) && self.handleDismiss()
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}
