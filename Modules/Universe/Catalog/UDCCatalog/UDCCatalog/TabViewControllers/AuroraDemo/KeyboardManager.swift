//
//  KeyboardManager.swift
//  UDCCatalog
//
//  Created by Hayden on 14/7/2023.
//  Copyright © 2023 姚启灏. All rights reserved.
//

import UIKit

// swiftlint:disable all

public class KeyboardManager: NSObject {
    @objc public static let defaultManager: KeyboardManager = {
        let manager = KeyboardManager ()
        manager.setup()
        return manager
    } ()
    /// 键盘是否已弹出
    @objc public var isKeyboardVisible = false
    /// 上一次的键盘高度
    @objc public var lastKeyboardHeight: CGFloat = 0
    /// 上一次的键盘尺寸位置
    @objc public var lastKeyboardRect: CGRect = CGRect.zero
    // swiftlint:disable redundant_optional_initialization
    /// 键盘弹出回调：高度,尺寸位置,动画时间,动画参数
    @objc public var keyboardWillShowBlock: ((
        _ : CGFloat,
        _ : CGRect,
        _ : TimeInterval,
        _ : UIView.AnimationCurve,
        _ : UIView.AnimationOptions)
        -> Void)? = nil
    /// 键盘收起回调：动画时间,动画参数
    @objc public var keyboardWillHideBlock: ((
        _ : TimeInterval,
        _ : UIView.AnimationCurve,
        _ : UIView.AnimationOptions)
        -> Void)? = nil
    // swiftlint:enable redundant_optional_initialization
    /// 让键盘绝对不覆盖掉的View，如果将会覆盖就平移，不设置就不会有平移动作
    @objc public weak var preventCoverView: UIView?
    /// 和不遮挡的View的距离
    @objc public var spaceToPreventCoverView: CGFloat = 0
    /// 调用此方法后开始在内部监听事件，获取参数
    @objc public func setup() {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleKeyboardWillShow),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleKeyboardWillHide),
            name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(cancelAllObserve), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(setup), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    @objc func cancelAllObserve() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
    /// 全局隐藏键盘
    @objc public func hideKeyBoard() {
        let vc = UIApplication.visibleViewController
        vc?.view.endEditing(true)
    }
    /// 停止内部的监听，先关数据、行为不再更新
    @objc public func stopBehavior() {
        NotificationCenter.default.removeObserver(self)
    }
    @objc private func handleKeyboardWillShow(notification: Notification) {
        isKeyboardVisible = true
        lastKeyboardHeight = keyboardHeight(with: notification)
        lastKeyboardRect = keyboardRect(with: notification)
        if let block = keyboardWillShowBlock {
            block(
                lastKeyboardHeight,
                lastKeyboardRect,
                keyboardAnimationDuration(with: notification),
                keyboardAnimationCurve(with: notification),
                keyboardAnimationOptions(with: notification))
        }
    }
    @objc private func handleKeyboardWillHide(notification: Notification) {
        isKeyboardVisible = false
        if let block = keyboardWillHideBlock {
            block(
                keyboardAnimationDuration(with: notification),
                keyboardAnimationCurve(with: notification),
                keyboardAnimationOptions(with: notification))
        }
    }
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        guard let baseLineView = self.preventCoverView else { return }
        guard let userInfo = notification.userInfo else { return }
        guard let keyboardFrameEnd =
            userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let bounds = baseLineView.bounds
        let frameInWindow = baseLineView.convert(bounds, to: UIApplication.shared.keyWindow)
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let keyboardWillShow = keyboardFrameEnd.origin.y < UIScreen.main.bounds.height
        let baseLine: CGFloat = frameInWindow.origin.y +
            frameInWindow.size.height + spaceToPreventCoverView
        let keyboardTopEnd = keyboardFrameEnd.origin.y
        guard let spotViewController = UIApplication.visibleViewController else { return }
        guard let spotView = spotViewController.view else { return }
        if keyboardWillShow {
            // Keyboard covers first responder
            guard baseLine > keyboardTopEnd else { return }
            let translationY = keyboardTopEnd - baseLine
            var targetTransform = spotView.transform
            targetTransform.ty += translationY
            let animations = { spotView.transform = targetTransform }
            UIView.animate(withDuration: duration, animations: animations)
        } else {
            let animations = { spotView.transform = CGAffineTransform.identity }
            UIView.animate(withDuration: duration, animations: animations)
        }
    }
    override init() {
        super.init()
    }
    /**
     * 获取当前键盘frame
     * @warning 注意iOS8以下的系统在横屏时得到的rect，宽度和高度相反了，所以不建议直接通过这个方法获取高度，而是使用<code>keyboardHeightWithNotification:inView:</code>，因为在后者的实现里会将键盘的rect转换坐标系，转换过程就会处理横竖屏旋转问题。
     */
    private func keyboardRect(with notification: Notification) -> CGRect {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return .zero }
        return keyboardRect
    }
    /// 获取当前键盘的高度，注意高度可能为0（例如第三方键盘会发出两次notification，其中第一次的高度就为0
    private func keyboardHeight(with notification: Notification) -> CGFloat {
        return keyboardHeight(with: notification, in: nil)
    }
    /**
     * 获取当前键盘在屏幕上的可见高度，注意外接键盘（iPad那种）时，[AppHelper keyboardRectWithNotification]得到的键盘rect里有一部分是超出屏幕，不可见的，如果直接拿rect的高度来计算就会与意图相悖。
     * @param notification 接收到的键盘事件的UINotification对象
     * @param view 要得到的键盘高度是相对于哪个View的键盘高度，若为nil，则等同于调用AppHelper.keyboardHeight(with: notification)
     * @warning 如果view.window为空（当前View尚不可见），则会使用App默认的UIWindow来做坐标转换，可能会导致一些计算错误
     * @return 键盘在view里的可视高度
     */
    private func keyboardHeight(with notification: Notification, in view: UIView?) -> CGFloat {
        let rect = keyboardRect(with: notification)
        guard let view = view else {
            return rect.height
        }
        let keyboardRectInView = view.convert(rect, from: view.window)
        let keyboardVisibleRectInView = view.bounds.intersection(keyboardRectInView)
        let resultHeight = keyboardVisibleRectInView.isNull ? 0 : keyboardVisibleRectInView.height
        return resultHeight
    }
    private func keyboardAnimationDuration(with notification: Notification) -> TimeInterval {
        guard let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return 0 }
        return animationDuration
    }
    // swiftlint:disable force_unwrapping
    private func keyboardAnimationCurve(with notification: Notification) -> UIView.AnimationCurve {
        guard let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int else { return .easeIn }
        return UIView.AnimationCurve(rawValue: curve)!
    }
    // swiftlint:enable force_unwrapping
    private func keyboardAnimationOptions(with notification: Notification) -> UIView.AnimationOptions {
        let rawValue = UInt(keyboardAnimationCurve(with: notification).rawValue)
        return UIView.AnimationOptions(rawValue: rawValue)
    }
}

extension UIApplication {

    class var visibleViewController: UIViewController? {
        return UIApplication.getVisibleViewController(from: UIApplication.shared.keyWindow?.rootViewController)
    }
    
    class func getVisibleViewController(from vc: UIViewController?) -> UIViewController? {
        if let nav = vc as? UINavigationController {
            return getVisibleViewController(from: nav.visibleViewController)
        } else if let tab = vc as? UITabBarController {
            return getVisibleViewController(from: tab.selectedViewController)
        } else if let pvc = vc?.presentedViewController {
            return getVisibleViewController(from: pvc)
        }
        return vc
    }
}

// swiftlint:enable all
