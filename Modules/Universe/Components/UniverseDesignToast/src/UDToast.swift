//
//  UDToast.swift
//  UDKit
//
//  Created by zfpan on 2020/10/15.
//  Copyright © 2020年 潘灶烽. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignShadow
import UniverseDesignTheme

///UDToast文档
open class UDToast {

    /// common toast shown method
    /// - Parameters:
    ///   - toastConfig: toast config
    ///   - view: the view toast shown
    ///   - delay: the time interval toast dismiss
    ///   - disableUserInteraction: whether the view can interact with user input
    ///   - operationCallBack: the callback after user click the operaion
    @discardableResult
    public class func showToast(with toastConfig: UDToastConfig,
                                on view: UIView,
                                delay: TimeInterval = Cons.defaultToastDelay,
                                disableUserInteraction: Bool? = false,
                                operationCallBack: ((String?) -> Void)? = nil,
                                dismissCallBack: (() -> Void)? = nil) -> UDToast {
        let hud = existingHUD(on: view)
        hud.showToast(with: toastConfig,
                      on: view,
                      delay: delay,
                      disableUserInteraction: disableUserInteraction,
                      operationCallBack: operationCallBack,
                      dismissCallBack: dismissCallBack)
        return hud
    }

    /// loading toast shown method
    /// - Parameters:
    ///   - text: toast text
    ///   - operationText: toast operation text
    ///   - view: the view toast shown
    ///   - disableUserInteraction: whether the view can interact with user input
    ///   - operationCallBack: the callback after user click the operaion
    @discardableResult
    public class func showLoading(with text: String,
                                  operationText: String? = nil,
                                  on view: UIView,
                                  disableUserInteraction: Bool? = false,
                                  operationCallBack: ((String?) -> Void)? = nil,
                                  dismissCallBack: (() -> Void)? = nil) -> UDToast {
        let hud = existingHUD(on: view)
        var operationConfig: UDToastOperationConfig?
        if let operationText = operationText {
            operationConfig = UDToastOperationConfig(text: operationText)
        }
        hud.showLoading(with: text,
                        operation: operationConfig,
                        on: view,
                        disableUserInteraction: disableUserInteraction,
                        operationCallBack: operationCallBack,
                        dismissCallBack: dismissCallBack)
        return hud
    }

    @discardableResult
    public class func showTipsOnScreenCenter(with text: String,
                                             on view: UIView,
                                             delay: TimeInterval = Cons.defaultToastDelay) -> UDToast {
        let hud = UDToast.showTips(with: text, on: view, delay: delay)
        hud.roundView.isRoundedViewInCenter = true
        hud.roundView.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
        }
        return hud
    }

    /// common text toast shown method
    /// - Parameters:
    ///   - text: toast text
    ///   - operationText: toast operation text
    ///   - view: the view toast shown
    ///   - delay: the time interval toast dismiss
    ///   - operationCallBack: the callback after user click the operaion
    @discardableResult
    public class func showTips(with text: String,
                               operationText: String? = nil,
                               on view: UIView,
                               delay: TimeInterval = Cons.defaultToastDelay,
                               operationCallBack: ((String?) -> Void)? = nil,
                               dismissCallBack: (() -> Void)? = nil) -> UDToast {
        let hud = existingHUD(on: view)
        var operationConfig: UDToastOperationConfig?
        if let operationText = operationText {
            operationConfig = UDToastOperationConfig(text: operationText)
        }
        hud.showTips(with: text,
                     operation: operationConfig,
                     on: view, delay: delay,
                     operationCallBack: operationCallBack,
                     dismissCallBack: dismissCallBack)
        return hud
    }

    /// failure toast  shown method
    /// - Parameters:
    ///   - text: toast text
    ///   - operationText: toast operation text
    ///   - view: the view toast shown
    ///   - delay: the time interval toast dismiss
    ///   - operationCallBack: the callback after user click the operaion
    @discardableResult
    public class func showFailure(with text: String,
                                  operationText: String? = nil,
                                  on view: UIView,
                                  delay: TimeInterval = Cons.defaultToastDelay,
                                  operationCallBack: ((String?) -> Void)? = nil,
                                  dismissCallBack: (() -> Void)? = nil) -> UDToast {
        let hud = existingHUD(on: view)
        var operationConfig: UDToastOperationConfig?
        if let operationText = operationText {
            operationConfig = UDToastOperationConfig(text: operationText)
        }
        hud.showFailure(with: text,
                        operation: operationConfig,
                        on: view, delay: delay,
                        operationCallBack: operationCallBack,
                        dismissCallBack: dismissCallBack)
        return hud
    }

    /// success toast  shown method
    /// - Parameters:
    ///   - text: toast text
    ///   - operationText: toast operation text
    ///   - view: the view toast shown
    ///   - delay: the time interval toast dismiss
    ///   - operationCallBack: the callback after user click the operaion
    @discardableResult
    public class func showSuccess(with text: String,
                                  operationText: String? = nil,
                                  on view: UIView,
                                  delay: TimeInterval = Cons.defaultToastDelay,
                                  operationCallBack: ((String?) -> Void)? = nil,
                                  dismissCallBack: (() -> Void)? = nil) -> UDToast {
        let hud = existingHUD(on: view)
        var operationConfig: UDToastOperationConfig?
        if let operationText = operationText {
            operationConfig = UDToastOperationConfig(text: operationText)
        }
        hud.showSuccess(with: text,
                        operation: operationConfig,
                        on: view,
                        delay: delay,
                        operationCallBack: operationCallBack,
                        dismissCallBack: dismissCallBack)
        return hud
    }

    /// warning toast  shown method
    /// - Parameters:
    ///   - text: toast text
    ///   - operationText: toast operation text
    ///   - view: the view toast shown
    ///   - delay: the time interval toast dismiss
    ///   - operationCallBack: the callback after user click the operaion
    @discardableResult
    public class func showWarning(with text: String,
                                  operationText: String? = nil,
                                  on view: UIView,
                                  delay: TimeInterval = Cons.defaultToastDelay,
                                  operationCallBack: ((String?) -> Void)? = nil,
                                  dismissCallBack: (() -> Void)? = nil) -> UDToast {
        let hud = existingHUD(on: view)
        var operationConfig: UDToastOperationConfig?
        if let operationText = operationText {
            operationConfig = UDToastOperationConfig(text: operationText)
        }
        hud.showWarning(with: text,
                        operation: operationConfig,
                        on: view,
                        delay: delay,
                        operationCallBack: operationCallBack,
                        dismissCallBack: dismissCallBack)
        return hud
    }

    /// custom toast  shown method
    /// - Parameters:
    ///   - text: toast text
    ///   - icon: toast icon
    ///   - operationText: toast operation text
    ///   - view: the view toast shown
    ///   - delay: the time interval toast dismiss
    ///   - operationCallBack: the callback after user click the operaion
    @discardableResult
    public class func showCustom(with text: String,
                                 icon: UIImage,
                                 iconColor: UIColor? = UIColor.ud.primaryOnPrimaryFill,
                                 operationText: String? = nil,
                                 on view: UIView,
                                 delay: TimeInterval = Cons.defaultToastDelay,
                                 operationCallBack: ((String?) -> Void)? = nil,
                                 dismissCallBack: (() -> Void)? = nil) -> UDToast {
        let hud = existingHUD(on: view)
        var operationConfig: UDToastOperationConfig?
        if let operationText = operationText {
            operationConfig = UDToastOperationConfig(text: operationText)
        }
        hud.showCustom(with: text,
                       icon: icon,
                       iconColor: iconColor,
                       operation: operationConfig,
                       on: view,
                       delay: delay,
                       operationCallBack: operationCallBack,
                       dismissCallBack: dismissCallBack)
        return hud
    }

    /// remove toast  shown method
    /// - Parameters:
    ///   - view: the view toast removed
    public class func removeToast(on view: UIView) {
        for hud in view.subviews {
            if let roundHud = hud as? RoundedView {
                roundHud.host?.dismissRoundView()
            }
        }
    }

    /// set custom bottom margin for toast
    /// - Parameters:
    ///   - margin: the bottom margin set for toast
    public class func setCustomBottomMargin(_ margin: CGFloat, view: UIView) {
        if let existingHUD = (view.subviews.last(where: { $0 is RoundedView }) as? RoundedView)?.host {
            existingHUD.bottomConstraint?.activate()
            existingHUD.bottomConstraint?.update(offset: -margin)
        }
    }

    public class func existingHUD(on view: UIView) -> UDToast {
        if let existingHUD = (view.subviews.last(where: { $0 is RoundedView }) as? RoundedView)?.host {
            if existingHUD.roundView.isRemoving {
                existingHUD.remove()
                return UDToast()
            }
            existingHUD.dimissWorkItem?.cancel()
            existingHUD.removeBgMask()
            existingHUD.roundView.tapCallBack = nil
            return existingHUD
        }
        return UDToast()
    }

    public var observeKeyboard: Bool = true {
        didSet {
            guard observeKeyboard != oldValue else {
                return
            }

            if observeKeyboard {
                self.addKeyboardObserver()
            } else {
                self.removeKeyboardObserver()
            }
        }
    }

    ///UDToast init方法
    public init() {
        self.addKeyboardObserver()
        self.addObserver()
    }

    deinit {
        self.removeKeyboardObserver()
        self.remove()
    }

    private var dimissWorkItem: DispatchWorkItem?

    public var keyboardMargin: CGFloat = 20 {
        didSet {
            self.updateRoundView()
        }
    }

    public func remove() {
        self.dimissWorkItem?.cancel()
        self.roundView.tapCallBack = nil
        self.removeSafity(view: bgMask)
        self.removeSafity(view: roundView)
    }

    private func removeBgMask() {
        self.removeSafity(view: bgMask)
    }

    public func setCustomBottomMargin(_ margin: CGFloat) {
        self.bottomConstraint?.activate()
        self.bottomConstraint?.update(offset: -margin)
    }

    public func showLoading(with text: String,
                            operation: UDToastOperationConfig? = nil,
                            on view: UIView,
                            disableUserInteraction: Bool?,
                            operationCallBack: ((String?) -> Void)? = nil,
                            dismissCallBack: (() -> Void)? = nil) {
        self.roundView.iconWrapper.isHidden = false
        self.roundView.iconView.isHidden = true
        self.roundView.indicator.isHidden = false
        self.roundView.indicator.startAnimating()

        self.roundView.textLabel.isHidden = text.isEmpty

        self.roundView.update(tips: text, superView: view, with: operation)

        self.roundView.tapCallBack = operationCallBack
        self.roundView.adjustRoundView(with: text, superView: view, operation: operation)

        if let disableUserInteraction = disableUserInteraction {
            self.displayRoundView(on: view, disableUserInteraction: disableUserInteraction)
        } else {
            self.displayRoundView(on: view, disableUserInteraction: false)
        }

        self.dimissWorkItem = DispatchWorkItem {
            dismissCallBack?()
        }
    }

    private func showLoading(with text: String,
                             operation: UDToastOperationConfig? = nil,
                             on view: UIView,
                             delay: TimeInterval = Cons.maximumToastDelay,
                             disableUserInteraction: Bool?,
                             operationCallBack: ((String?) -> Void)? = nil,
                             dismissCallBack: (() -> Void)? = nil) {
        self.showLoading(with: text,
                         operation: operation,
                         on: view,
                         disableUserInteraction: disableUserInteraction,
                         operationCallBack: operationCallBack,
                         dismissCallBack: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.dismissRoundView()
            dismissCallBack?()
        }
    }

    public func showTips(with text: String,
                         operation: UDToastOperationConfig? = nil,
                         on view: UIView,
                         delay: TimeInterval = Cons.defaultToastDelay,
                         disableUserInteraction: Bool = false,
                         operationCallBack: ((String?) -> Void)? = nil,
                         dismissCallBack: (() -> Void)? = nil) {
        self.roundView.iconWrapper.isHidden = true
        self.roundView.textLabel.isHidden = false
        self.roundView.indicator.isHidden = true

        if #available(iOS 13, *) {
            self.roundView.overrideUserInterfaceStyle = view.overrideUserInterfaceStyle
        }

        self.roundView.update(tips: text, superView: view, with: operation)

        self.roundView.tapCallBack = operationCallBack
        self.roundView.adjustRoundView(with: text, superView: view, operation: operation)
        self.displayRoundView(on: view, disableUserInteraction: disableUserInteraction)

        self.dimissWorkItem = DispatchWorkItem {[weak self] in
            self?.dismissRoundView()
            dismissCallBack?()
        }

        guard let item = self.dimissWorkItem else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    public func showFailure(with text: String,
                            operation: UDToastOperationConfig? = nil,
                            on view: UIView,
                            delay: TimeInterval = Cons.defaultToastDelay,
                            operationCallBack: ((String?) -> Void)? = nil,
                            dismissCallBack: (() -> Void)? = nil) {
        self.showResult(with: text,
                        operation: operation,
                        image: failureIcon(),
                        on: view,
                        delay: delay,
                        disableUserInteraction: false,
                        operationCallBack: operationCallBack,
                        dismissCallBack: dismissCallBack)
    }

    public func showSuccess(with text: String,
                            operation: UDToastOperationConfig? = nil,
                            on view: UIView,
                            delay: TimeInterval = Cons.defaultToastDelay,
                            operationCallBack: ((String?) -> Void)? = nil,
                            dismissCallBack: (() -> Void)? = nil) {
        self.showResult(with: text,
                        operation: operation,
                        image: successIcon(),
                        on: view,
                        delay: delay,
                        disableUserInteraction: false,
                        operationCallBack: operationCallBack,
                        dismissCallBack: dismissCallBack)
    }

    public func showCustom(with text: String,
                           icon: UIImage,
                           iconColor: UIColor? = UIColor.ud.primaryOnPrimaryFill,
                           operation: UDToastOperationConfig? = nil,
                           on view: UIView,
                           delay: TimeInterval = Cons.defaultToastDelay,
                           operationCallBack: ((String?) -> Void)? = nil,
                           dismissCallBack: (() -> Void)? = nil) {
        var toastIcon = icon
        if let iconColor = iconColor {
            toastIcon = icon.ud.withTintColor(iconColor)
        }
        self.showResult(with: text,
                        operation: operation,
                        image: toastIcon,
                        on: view,
                        delay: delay,
                        disableUserInteraction: false,
                        operationCallBack: operationCallBack,
                        dismissCallBack: dismissCallBack)
    }

    public func updateToast(with text: String, superView: UIView, operation: UDToastOperationConfig? = nil) {
        self.roundView.textLabel.isHidden = text.isEmpty
        self.roundView.update(tips: text, superView: superView, with: operation)
        self.roundView.adjustRoundView(with: text, superView: superView, operation: operation)
    }

    private func addKeyboardObserver() {
        willShowObserver =
        UDToast.handleKeyboard(name: UIResponder.keyboardWillShowNotification,
                               action: { [weak self] (keyBoardRect, _) in
            guard let `self` = self else {
                return
            }
            if self.roundView.superview != nil {
                if self.roundView.isRoundedViewInCenter {
                    if keyBoardRect.height < Cons.externalKeyboardToolBarHeight {
                        self.bottomConstraint?.deactivate()
                    } else {
                        self.updateRoundView()
                    }
                } else {
                    self.bottomConstraint?.activate()
                    self.bottomConstraint?.update(offset: -keyBoardRect.height - self.keyboardMargin)
                }
            }
        })

        willHideObserver =
        UDToast.handleKeyboard(name: UIResponder.keyboardWillHideNotification,
                               action: { [weak self] (_, _) in
            if #available(iOS 17.0, *), UIDevice.current.userInterfaceIdiom == .phone {
                // iOS 17 监听键盘的行为有问题，会发出两次 keyboardWillHideNotification，因此暂时不处理 iOS 17 下 Toast 随键盘收起的行为
                // iPad 目前不存在这种问题，因为 iPad 维持原状
            } else {
                if self?.roundView.superview != nil {
                    self?.bottomConstraint?.deactivate()
                }
            }
        })
    }

    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateRoundView),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateRoundView),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)

    }

    private func removeKeyboardObserver() {
        if let willShow = willShowObserver, let willHide = willHideObserver {
            self.bottomConstraint?.deactivate()
            NotificationCenter.default.removeObserver(willShow)
            NotificationCenter.default.removeObserver(willHide)
        }
    }

    private func removeSafity(view: UIView?) {
        let task = {
            guard let view = view else { return }
            if view.superview == nil { return }
            view.removeFromSuperview()
        }

        if Thread.isMainThread {
            task()
            return
        }
        DispatchQueue.main.async {
            task()
        }
    }

    private func showToast(with toastConfig: UDToastConfig,
                           on view: UIView,
                           delay: TimeInterval = Cons.defaultToastDelay,
                           disableUserInteraction: Bool?,
                           operationCallBack: ((String?) -> Void)? = nil,
                           dismissCallBack: (() -> Void)? = nil) {
        switch toastConfig.toastType {
        case .info:
            self.showTips(with: toastConfig.text,
                          operation: toastConfig.operation,
                          on: view,
                          delay: delay,
                          operationCallBack: operationCallBack,
                          dismissCallBack: dismissCallBack)
        case .loading:
            self.showLoading(with: toastConfig.text,
                             operation: toastConfig.operation,
                             on: view,
                             delay: delay,
                             disableUserInteraction: disableUserInteraction,
                             operationCallBack: operationCallBack,
                             dismissCallBack: dismissCallBack)
        case .error:
            self.showFailure(with: toastConfig.text,
                             operation: toastConfig.operation,
                             on: view,
                             delay: delay,
                             operationCallBack: operationCallBack,
                             dismissCallBack: dismissCallBack)
        case .success:
            self.showSuccess(with: toastConfig.text,
                             operation: toastConfig.operation,
                             on: view,
                             delay: delay,
                             operationCallBack: operationCallBack,
                             dismissCallBack: dismissCallBack)
        case .warning:
            self.showWarning(with: toastConfig.text,
                             operation: toastConfig.operation,
                             on: view,
                             delay: delay,
                             operationCallBack: operationCallBack,
                             dismissCallBack: dismissCallBack)
        case .custom(let icon, let color):
            self.showCustom(with: toastConfig.text,
                            icon: icon,
                            iconColor: color,
                            operation: toastConfig.operation,
                            on: view,
                            delay: delay,
                            operationCallBack: operationCallBack,
                            dismissCallBack: dismissCallBack)
        }
    }

    private func showWarning(with text: String,
                             operation: UDToastOperationConfig? = nil,
                             on view: UIView,
                             delay: TimeInterval = Cons.defaultToastDelay,
                             operationCallBack: ((String?) -> Void)? = nil,
                             dismissCallBack: (() -> Void)? = nil) {
        self.showResult(with: text,
                        operation: operation,
                        image: warningIcon(),
                        on: view,
                        delay: delay,
                        disableUserInteraction: false,
                        operationCallBack: operationCallBack,
                        dismissCallBack: dismissCallBack)
    }

    private func showResult(with text: String,
                            operation: UDToastOperationConfig? = nil,
                            image: UIImage,
                            on view: UIView,
                            delay: TimeInterval = Cons.defaultToastDelay,
                            disableUserInteraction: Bool,
                            operationCallBack: ((String?) -> Void)? = nil,
                            dismissCallBack: (() -> Void)? = nil) {
        self.roundView.iconWrapper.isHidden = false
        self.roundView.iconView.isHidden = false
        self.roundView.indicator.isHidden = true
        self.roundView.textLabel.isHidden = false
        self.roundView.indicator.stopAnimating()

        self.roundView.update(tips: text, superView: view, with: operation)

        self.roundView.tapCallBack = operationCallBack
        self.roundView.iconView.image = image
        self.roundView.adjustRoundView(with: text, superView: view, operation: operation)
        self.displayRoundView(on: view, disableUserInteraction: disableUserInteraction)

        self.dimissWorkItem = DispatchWorkItem {[weak self] in
            self?.dismissRoundView()
            dismissCallBack?()
        }

        guard let item = self.dimissWorkItem else {
            assertionFailure()
            return
        }

        guard delay >= 0.0 else {
            assertionFailure()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func failureIcon() -> UIImage {
        return BundleResources.image(named: "failure")
    }

    private func successIcon() -> UIImage {
        return BundleResources.image(named: "success")
    }

    private func warningIcon() -> UIImage {
        return BundleResources.image(named: "warning")
    }

    private var bgMask: UIView?
    private var bottomConstraint: Constraint?
    private func displayRoundView(on view: UIView, disableUserInteraction: Bool) {
        guard let current = UIWindow.current else {
            return
        }

        let isReuse: Bool = self.roundView.superview != nil
        if !isReuse {
            self.roundView.alpha = 0.0
        }
        view.addSubview(self.roundView)
        self.roundView.host = self
        self.updateRoundView()

        if disableUserInteraction {
            //挡住用户的操作
            let bg = UIView()
            view.insertSubview(bg, belowSubview: self.roundView)
            bg.frame = view.bounds
            self.bgMask = bg
        } else {
            self.removeBgMask()
        }

        if !isReuse {
            UIView.animate(withDuration: Cons.animateDuration, delay: 0, options: .curveLinear, animations: {
                self.roundView.alpha = 1.0
            }, completion: nil)
        }
    }

    @objc
    private func updateRoundView() {
        guard let current = UIWindow.current else { return }
        guard self.roundView.superview != nil else { return }

        let bottomMargin = current.bounds.size.height * Cons.bottomMarginRatio
        let keyboardHeight = self.observeKeyboard ? self.keyboardHeight() : 0
        let bottomOffset: CGFloat = keyboardHeight > 0 ? (-keyboardHeight - self.keyboardMargin) : 0
        self.roundView.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-bottomMargin).priority(.high)
            make.width.lessThanOrEqualToSuperview().offset(-Cons.screenMargin * 2)
            self.bottomConstraint = make.bottom.equalTo(bottomOffset).constraint
        }
        if keyboardHeight == 0 {
            self.bottomConstraint?.deactivate()
        }
        self.roundView.superview?.layoutIfNeeded()
    }

    internal func dismissRoundView() {
        self.roundView.isRemoving = true
        UIView.animate(withDuration: Cons.animateDuration, delay: 0, options: .curveLinear, animations: {
            self.roundView.alpha = 0.0
        }, completion: { _ in
            self.remove()
        })
    }

    private let roundView: RoundedView = RoundedView()

    private var willShowObserver: NSObjectProtocol?
    private var willHideObserver: NSObjectProtocol?
    private static func handleKeyboard(name: NSNotification.Name,
                                       action: @escaping (CGRect, TimeInterval) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { (notification) in
            guard let userinfo = notification.userInfo else {
                assertionFailure()
                return
            }
            let duration = userinfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            guard let toFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                assertionFailure()
                return
            }
            action(toFrame, duration ?? 0)
        }
    }

    func keyboardHeight() -> CGFloat {
        var keyboardHeight: CGFloat = 0

        guard let current = UIWindow.current else {
            return 0
        }

        // 用于判断 keyboard 是否在屏幕内
        let keyboardHeightBlock = { (view: UIView) -> CGFloat in
            if view.frame.origin.y >= current.bounds.height {
                return 0
            }

            var height = view.bounds.height
            if view.frame.origin.y + height > current.bounds.height {
                height = current.bounds.height - view.frame.origin.y
            }

            return height
        }

        UIApplication.shared.windows.forEach { (window) in
            // 只判断 UIWindow 的子类
            if String("\(type(of: window))") == "UIWindow" {
                return
            }
            window.subviews.forEach({ (view) in
                if !view.isHidden {
                    if view.description.hasPrefix("<UIPeripheralHostView") {
                        keyboardHeight = keyboardHeightBlock(view)
                    } else if view.description.hasPrefix("<UIInputSetContainerView") {
                        view.subviews.forEach({ (subView) in
                            if subView.description.hasPrefix("<UIInputSetHost") {
                                subView.subviews.forEach({ (sub) in
                                    /// 键盘真正弹出时候有此view，有该view时候获取 UIInputSetHost 的高度
                                    /// 备注：键盘没弹出时候，window上也能获取到 UIInputSetHostView，所以直接获取高度是不对的
                                    if sub.description.hasPrefix("<<_UIRemoteKeyboardPlaceholderView") {
                                        keyboardHeight = keyboardHeightBlock(subView)
                                    }
                                })
                            }
                        })
                    }
                }
            })
        }
        return keyboardHeight
    }
}

extension UDToast {

    // nolint: magic_number
    public enum Cons {
        internal static var screenMargin: CGFloat { 40.0 }
        internal static var bottomMarginRatio: CGFloat { 0.2 }
        internal static var externalKeyboardToolBarHeight: CGFloat { 70 }
        internal static var animateDuration: TimeInterval { 0.2 }
        public static var defaultToastDelay: TimeInterval { 3 }
        public static var maximumToastDelay: TimeInterval { 1500 }
    }
    // enable-lint: magic_number
}

extension UIWindow {
    ///获取当前的window
    class var current: UIWindow? {
        var current: UIWindow?
        let windows = UIApplication.shared.windows
        for window: UIWindow in windows {
            let windowOnMainScreen: Bool = window.screen == UIScreen.main
            let windowIsVisible: Bool = !window.isHidden && window.alpha > 0
            let windowLevelNormal: Bool = window.windowLevel == .normal
            if windowOnMainScreen && windowIsVisible && windowLevelNormal {
                current = window
                break
            }
        }
        return current
    }
}
