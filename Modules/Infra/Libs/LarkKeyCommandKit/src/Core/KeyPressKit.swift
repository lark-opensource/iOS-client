//
//  KeyPressKit.swift
//  LarkKeyCommandKit
//
//  Created by Saafo on 2021/3/28.
//

import UIKit
import Foundation

/// 管理 Press 事件辅助类
@available(iOS 13.4, *)
public final class KeyPressKit: NSObject {
    /// 全局单例
    public static let shared = KeyPressKit()

    var globalHandler: [PressHandler] = []
    private static var hadSwizzledResponderMethod: Bool = false

    /// 置换 UIApplication 的 press 系列方法，传递到 UIApplication 层的 press 事件都会被处理
    @objc
    public static func swizzledIfNeeded() {
        /// 只在 pad 版本生效
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        if !KeyPressKit.hadSwizzledResponderMethod {
            kck_swizzling(
                forClass: UIApplication.self,
                originalSelector: #selector(UIResponder.pressesBegan(_:with:)),
                swizzledSelector: #selector(UIApplication.kck_pressesBegan(_:with:))
            )
            kck_swizzling(
                forClass: UIApplication.self,
                originalSelector: #selector(UIResponder.pressesEnded(_:with:)),
                swizzledSelector: #selector(UIApplication.kck_pressesEnded(_:with:))
            )
            kck_swizzling(
                forClass: UIApplication.self,
                originalSelector: #selector(UIResponder.pressesChanged(_:with:)),
                swizzledSelector: #selector(UIApplication.kck_pressesChanged(_:with:))
            )
            kck_swizzling(
                forClass: UIApplication.self,
                originalSelector: #selector(UIResponder.pressesCancelled(_:with:)),
                swizzledSelector: #selector(UIApplication.kck_pressesCancelled(_:with:))
            )
            KeyPressKit.hadSwizzledResponderMethod = true
        }

    }

    /// Press 事件种类
    public enum PressStatus {
        /// 按下按键
        case began
        /// 抬起按键
        case ended
        /// 按键变更
        case changed
        /// 按键取消
        case cancelled
    }

    /// 注册全局 PressHandler，能响应所有传递到 UIApplication 层的 Press 事件
    public func register(pressHandler: PressHandler) {
        globalHandler.append(pressHandler)
    }
    public func unregister(pressHandler: PressHandler) {
        if let index = globalHandler.firstIndex(where: { $0 === pressHandler }) {
            globalHandler.remove(at: index)
        }
    }
    func press(status: PressStatus, presses: Set<UIPress>, with event: UIPressesEvent?) {
        globalHandler.filter {
            $0.handleStatus == status &&
                $0.canHandle($0) && {
                    guard let keyCode = presses.first?.key?.keyCode else { return false }
                    return $0.handleKeys.isEmpty || $0.handleKeys.contains(keyCode)
                }($0)
        }
            .forEach { handler in
                handler.handle(presses, event)
        }
    }
}

/// 响应 Press 事件的 Handler
@available(iOS 13.4, *)
public final class PressHandler {
    var handleKeys: [UIKeyboardHIDUsage]
    var handleStatus: KeyPressKit.PressStatus
    var canHandle: ((PressHandler) -> Bool)
    var handle: (Set<UIPress>, UIPressesEvent?) -> Void
    /// 处理 Press 事件的 Handler
    /// - Parameters:
    ///   - handleKeys: 指定要响应的 keys。如果为空，则响应所有事件
    ///   - status: 指定要响应的 key press 状态
    ///   - canHandle: 是否需要处理事件闭包
    ///   - handle: 处理事件闭包
    public init(handleKeys: [UIKeyboardHIDUsage] = [],
                status: KeyPressKit.PressStatus,
                canHandle: ((PressHandler) -> Bool)? = nil,
                handle: @escaping (Set<UIPress>, UIPressesEvent?) -> Void) {
        self.handleKeys = handleKeys
        self.handleStatus = status
        self.canHandle = canHandle ?? { _ in true }
        self.handle = handle
    }
}

@available(iOS 13.4, *)
extension UIApplication {
    @objc
    func kck_pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        kck_pressesBegan(presses, with: event)
        KeyPressKit.shared.press(status: .began, presses: presses, with: event)
    }

    @objc
    func kck_pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        kck_pressesEnded(presses, with: event)
        KeyPressKit.shared.press(status: .ended, presses: presses, with: event)
    }

    @objc
    func kck_pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        kck_pressesChanged(presses, with: event)
        KeyPressKit.shared.press(status: .changed, presses: presses, with: event)
    }

    @objc
    func kck_pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        kck_pressesCancelled(presses, with: event)
        KeyPressKit.shared.press(status: .cancelled, presses: presses, with: event)
    }
}
