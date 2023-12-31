//
//  SKWebViewInputInterceptor.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/7/27.
//

import UIKit
import Foundation

protocol RTWebViewInputInterceptorDelegate: AnyObject {
    func shouldContentViewReloadInputViews(_ interceptor: RTWebViewInputInterceptor)
    func shouldWebViewReloadInputViews(_ interceptor: RTWebViewInputInterceptor)
}

/// 用于保证WebView输入状态正确辅助工具
final class RTWebViewInputInterceptor: NSObject {
    /*
     * 当前职责
     * - 控制键盘不同状态刷新时机
     * - 控制工具栏刷新时机
     * - 监控第一响应者状态是否正常
     */
    weak var delegate: RTWebViewInputInterceptorDelegate?
    // MARK: state
    private var _keyboardState: KeyboardStateSM = .hide
    private var _shouldReloadInputViews: Bool = false

    override init() {
        super.init()
        commonInit()
    }

    private func commonInit() {
        _enableKeyboardObservation()
    }

    lazy var keyboard: Keyboard = Keyboard()
}

// MARK: InputView Action Handler
extension RTWebViewInputInterceptor {
    private var reloadableState: Set<KeyboardStateSM> {
        return [.show]
    }
    private var shouldClearState: Set<KeyboardStateSM> {
        return [.show]
    }

    private func _reloadInputViewsIfNeeded() {
        if _shouldReloadInputViews {
            _shouldReloadInputViews = false
            delegate?.shouldContentViewReloadInputViews(self)
        }
    }
}

// MARK: - Keyboard Action Handler
extension RTWebViewInputInterceptor {
    /// 键盘状态机
    private enum KeyboardStateSM: Int {
        case hide
        // 对于iPadOS无虚拟键盘情况，需要额外适配，考虑是否开启此枚举
        // case invisible
        case presenting
        case show
        case dismissing
    }
    private func keyboardWillShow(_ opt: Keyboard.KeyboardOptions) {
        _handleKeyboardStateChange(from: _keyboardState, to: .presenting)
        _keyboardState = .presenting
//        print("🐴will show")
    }

    private func keyboardDidShow(_ opt: Keyboard.KeyboardOptions) {
        _handleKeyboardStateChange(from: _keyboardState, to: .show)
        _keyboardState = .show
//        print("🐴did show")
    }

    private func keyboardWillHide(_ opt: Keyboard.KeyboardOptions) {
        _handleKeyboardStateChange(from: _keyboardState, to: .dismissing)
        _keyboardState = .dismissing
//        print("🐴will hide")
    }

    private func keyboardDidHide(_ opt: Keyboard.KeyboardOptions) {
        _handleKeyboardStateChange(from: _keyboardState, to: .hide)
        _keyboardState = .hide
//        print("🐴did hide")
    }

    private func _handleKeyboardStateChange(from oldValue: KeyboardStateSM, to newValue: KeyboardStateSM) {
        // Deal with logic
        if reloadableState.contains(newValue) {
            _reloadInputViewsIfNeeded()
        }
        if shouldClearState.contains(newValue) {
            _shouldReloadInputViews = false
        }
    }
}

// MARK: - Util
extension RTWebViewInputInterceptor {
    private func _enableKeyboardObservation() {
        keyboard.on(event: .willShow) { [weak self] opt in self?.keyboardWillShow(opt) }
        keyboard.on(event: .didShow) { [weak self] opt in self?.keyboardDidShow(opt) }
        keyboard.on(event: .willHide) { [weak self] opt in self?.keyboardWillHide(opt) }
        keyboard.on(event: .didHide) { [weak self] opt in self?.keyboardDidHide(opt) }
        keyboard.start()
    }

}
