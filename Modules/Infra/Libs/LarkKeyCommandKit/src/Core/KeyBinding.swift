//
//  KeyBinding.swift
//  LarkKeyCommandKit
//
//  Created by 李晨 on 2020/2/5.
//

import UIKit
import Foundation
import LarkKeyboardKit

public final class KeyBindingWraper: NSObject {
    var binder: KeyBinding

    public init(binder: KeyBinding) {
        self.binder = binder
        super.init()
    }
}

/// KeyBinding 包含快捷键基本信息和实现方法
public class KeyBinding {

    /// 默认 tryHandle 方法
    public static let defaultTryHanlde: (KeyBinding) -> Bool = { (key) -> Bool in
        // 第一响应者为 UIKeyInput 时
        // 没有 modifierFlags 的快捷键不进行响应
        if KeyboardKit.shared.firstResponder is UIKeyInput,
           key.info.modifierFlags.isEmpty {
            return false
        }
        return true
    }

    /// 描述信息，影响 hash 逻辑
    public var description: String

    /// 基本快捷键信息
    public var info: KeyCommandBaseInfo

    /// 当前快捷键是否需要响应
    public var tryHandle: (KeyBinding) -> Bool

    /// 快捷键响应方法
    public func handle() {
        assertionFailure("use subclass of KeyBaseBinding")
    }

    init(
        description: String = "",
        info: KeyCommandBaseInfo,
        tryHandle: @escaping (KeyBinding) -> Bool
    ) {
        self.description = description
        self.info = info
        self.tryHandle = tryHandle
    }

    /// 返回 binding wraper
    public var wraper: KeyBindingWraper {
        return KeyBindingWraper(binder: self)
    }
}

//swiftlint:disable missing_docs

/// KeyCommandInfo 链式生成 binding 方法
extension KeyCommandBaseInfo {
    public func binding(
        description: String = "",
        tryHandle:  @escaping (KeyBinding) -> Bool = KeyBinding.defaultTryHanlde,
        handler: @escaping () -> Void
    ) -> KeyBinding {
        return KeyBlockBinding(
            description: description,
            info: self,
            tryHandle: tryHandle,
            handler: handler
        )
    }

    public func binding(
        description: String = "",
        tryHandle:  @escaping (KeyBinding) -> Bool = KeyBinding.defaultTryHanlde,
        target: NSObject,
        selector: Selector
    ) -> KeyBinding {
        return KeyTargetBinding(
            description: description,
            info: self,
            tryHandle: tryHandle,
            target: target,
            selector: selector
        )
    }
}

extension KeyBinding: Hashable {
    public static func == (lhs: KeyBinding, rhs: KeyBinding) -> Bool {
        return lhs.info == rhs.info &&
            lhs.description == rhs.description
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(info)
        hasher.combine(description)
    }
}

/// Block 风格 binding
public final class KeyBlockBinding: KeyBinding {

    public var handler: () -> Void

    public override func handle() {
        handler()
    }

    public init(
        description: String = "",
        info: KeyCommandBaseInfo,
        tryHandle: @escaping (KeyBinding) -> Bool,
        handler: @escaping () -> Void
    ) {
        self.handler = handler
        super.init(
            description: description,
            info: info,
            tryHandle: tryHandle
        )
    }
}

/// target action 风格 binding
public final class KeyTargetBinding: KeyBinding {
    weak var target: NSObject?
    var selector: Selector

    public override func handle() {
        target?.perform(selector)
    }

    public init(
        description: String = "",
        info: KeyCommandBaseInfo,
        tryHandle: @escaping (KeyBinding) -> Bool,
        target: NSObject,
        selector: Selector
    ) {
        self.target = target
        self.selector = selector
        super.init(
            description: description,
            info: info,
            tryHandle: tryHandle
        )
    }
}
//swiftlint:enable missing_docs
