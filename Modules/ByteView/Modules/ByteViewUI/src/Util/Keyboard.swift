//
//  Keyboard.swift
//  ByteViewUI
//
//  Created by kiri on 2023/5/10.
//

import Foundation
import ByteViewCommon

public final class Keyboard {
    public static func initialize() {
        _ = Keyboard.shared
    }

    public static func reset() {
        Keyboard.shared.currentInfo = nil
    }

    fileprivate static let shared = Keyboard()
    fileprivate static var isShowing: Bool = false

    @RwAtomic fileprivate var currentInfo: KeyboardInfo?
    fileprivate let listeners = Listeners<KeyboardHelper>()

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(willChangeKeyboardFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeKeyboardFrame(_:)), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willShowKeyboard(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willHiddenKeyboard(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func willChangeKeyboardFrame(_ notification: Notification) {
        guard Self.isShowing else { return }
        self.handleNotification(notification)
    }

    @objc private func didChangeKeyboardFrame(_ notification: Notification) {
        guard Self.isShowing else { return }
        self.handleNotification(notification)
    }

    @objc private func willShowKeyboard(_ notification: Notification) {
        Self.isShowing = true
        self.handleNotification(notification)
    }

    @objc private func willHiddenKeyboard(_ notification: Notification) {
        Self.isShowing = false
        self.handleNotification(notification)
    }

    private func handleNotification(_ notification: Notification) {
        // 过滤iPad键盘切换时的无效值
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, frame.size != .zero else { return }
        var options: UIView.AnimationOptions = []
        var duration: TimeInterval = 0
        var isLocal = true
        if let obj = userInfo[UIResponder.keyboardIsLocalUserInfoKey] as? Bool {
            isLocal = obj
        }
        if let obj = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            duration = obj
        }
        if let obj = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
            options = UIView.AnimationOptions(rawValue: obj << 16)
        }
        var screenId: ObjectIdentifier?
        if let obj = notification.object as? UIScreen {
            screenId = ObjectIdentifier(obj)
        }
        let info = KeyboardInfo(frame: frame, animationDuration: duration, animationOptions: options, isLocal: isLocal, screenId: screenId)
        if self.currentInfo != info {
            self.currentInfo = info
            self.listeners.forEach { $0.didChangeKeyboardInfo(info) }
        }
    }
}

private struct KeyboardInfo: Equatable {
    let frame: CGRect
    let animationDuration: TimeInterval
    let animationOptions: UIView.AnimationOptions
    let isLocal: Bool
    let screenId: ObjectIdentifier?
}

private extension Keyboard {
    static var keyboardHelper: UInt8 = 0
}

private final class KeyboardHelper {
    let layoutGuide = UILayoutGuide()
    weak var ownerView: UIView?
    var heightConstraint: NSLayoutConstraint?
    let debounce: Bool

    init(owner: UIView, debounce: Bool) {
        self.debounce = debounce
        self.ownerView = owner
        layoutGuide.identifier = "Keyboard"
        owner.addLayoutGuide(layoutGuide)
        layoutGuide.leftAnchor.constraint(equalTo: owner.leftAnchor).isActive = true
        layoutGuide.rightAnchor.constraint(equalTo: owner.rightAnchor).isActive = true
        layoutGuide.bottomAnchor.constraint(equalTo: owner.bottomAnchor).isActive = true
        // NOTE: 需要设置当前准确值，否则会出现不必要的动画
        let keyboardHeight = keyboardHeightInOwner(by: Keyboard.shared.currentInfo)
        heightConstraint = layoutGuide.heightAnchor.constraint(equalToConstant: keyboardHeight)
        heightConstraint?.isActive = true
        Keyboard.shared.listeners.addListener(self)
    }

    private func keyboardHeightInOwner(by info: KeyboardInfo?) -> CGFloat {
        guard Keyboard.isShowing else { return 0 }
        guard let info = info, info.frame.height > 0 else { return 0 }
        guard let owner = self.ownerView, let w = owner.window else {
            // 处理页面还未显示时的情况
            return 0
        }

        let screen = w.screen
        if let id = info.screenId, id != ObjectIdentifier(screen) {
            // 如果有screen，但是和当前的screen不一样，返回0
            return 0
        }

        let keyboardFrame = owner.convert(info.frame, from: screen.coordinateSpace)
        return max(owner.frame.height - keyboardFrame.minY, 0)
    }

    private func keyboardFrameChanged(info: KeyboardInfo) {
        let constant = self.keyboardHeightInOwner(by: info)
        guard self.heightConstraint?.constant != constant else { return }
        self.heightConstraint?.constant = constant
        UIView.animate(withDuration: info.animationDuration, delay: 0.0, options: info.animationOptions, animations: {
            self.ownerView?.layoutIfNeeded()
        }, completion: nil)
    }

    func didChangeKeyboardInfo(_ info: KeyboardInfo) {
        if ownerView == nil { return }
        Logger.ui.info("Keyboard frameChange info: \(info)")
        if self.debounce {
            DispatchQueue.main.asyncAfter(deadline: .now() + .nanoseconds(1)) { [weak self] in
                self?.keyboardFrameChanged(info: info)
            }
        } else {
            self.keyboardFrameChanged(info: info)
        }
    }

    func updateKeyboardLayout() {
        let constant = self.keyboardHeightInOwner(by: Keyboard.shared.currentInfo)
        guard self.heightConstraint?.constant != constant else { return }
        self.heightConstraint?.constant = constant
    }
}

extension VCExtension where BaseType: UIView {
    /// 无缝实时跟随键盘
    public var keyboardLayoutGuide: UILayoutGuide {
        if #available(iOS 15.0, *) {
            return base.keyboardLayoutGuide
        }
        return getKeyboardLayoutGuide(debounce: false)
    }

    /// 键盘更新太频繁导致相对于它的布局会跳动，目前只有共享面板页面用到
    public var debounceKeyboardLayoutGuide: UILayoutGuide {
        if #available(iOS 15.0, *) {
            return base.keyboardLayoutGuide
        }
        return getKeyboardLayoutGuide(debounce: true)
    }

    public func updateKeyboardLayout() {
        keyboardHelper?.updateKeyboardLayout()
    }

    private func getKeyboardLayoutGuide(debounce: Bool) -> UILayoutGuide {
        if let helper = self.keyboardHelper {
            return helper.layoutGuide
        } else {
            let helper = KeyboardHelper(owner: self.base, debounce: debounce)
            self.keyboardHelper = helper
            return helper.layoutGuide
        }
    }

    private var keyboardHelper: KeyboardHelper? {
        get { objc_getAssociatedObject(base, &Keyboard.keyboardHelper) as? KeyboardHelper }
        set { objc_setAssociatedObject(self.base, &Keyboard.keyboardHelper, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
