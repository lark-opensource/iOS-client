//
//  ChatInputItem.swift
//  Lark
//
//  Created by 刘晚林 on 2017/6/14.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit

public enum KeyboardItemKey: String {
    case unknown
    case at
    case voice
    case emotion
    case picture
    case file
    case send
    case more
    case log
    case burnTime
    case cryptoBurnTime
    case canvas
    case compose
    case todo
    case hashTag
    case font
}


/// 键盘图标 Badge 类型
public enum KeyboardIconBadgeType {
    case redPoint
    case none
}

public struct KeyboardInfo {
    /// 根据屏幕高度动态调整键盘的高度
    public var height: Float = Display.height >= 812 ? 302 : 260
    public var icon: UIImage?
    public var selectedIcon: UIImage?
    public var unenableIcon: UIImage?

    public init(
        icon: UIImage? = nil,
        selectedIcon: UIImage? = nil,
        unenableIcon: UIImage? = nil,
        tintColor: UIColor? = nil,
        selectedTintColor: UIColor? = nil,
        unenableTintColor: UIColor? = nil
    ) {
        let transformBlock = { (image: UIImage?, color: UIColor?) -> UIImage? in
            if let color = color {
                return image?.ud.withTintColor(color)
            }
            return image
        }
        self.icon = transformBlock(icon, tintColor)
        self.selectedIcon = transformBlock(selectedIcon, selectedTintColor)
        self.unenableIcon = transformBlock(unenableIcon, unenableTintColor)
    }

    public init(
        height: Float,
        icon: UIImage? = nil,
        selectedIcon: UIImage? = nil,
        unenableIcon: UIImage? = nil,
        tintColor: UIColor? = nil,
        selectedTintColor: UIColor? = nil,
        unenableTintColor: UIColor? = nil
    ) {
        self.init(
            icon: icon,
            selectedIcon: selectedIcon,
            unenableIcon: unenableIcon,
            tintColor: tintColor,
            selectedTintColor: selectedTintColor,
            unenableTintColor: unenableTintColor
        )
        self.height = height
    }

    public var icons: (UIImage?, UIImage?, UIImage?) {
        return (icon, selectedIcon, unenableIcon)
    }
}

public struct InputKeyboardItem {
    public static let defaultTapHandler: (KeyboardPanelEvent) -> Void = { event in
        switch event.type {
        case .tap:
            event.keyboardSelect()
        default:
            break
        }
    }

    /// item 唯一 key
    public let key: String

    /// 返回键盘 View
    public var keyboardViewBlock: () -> UIView

    /// 返回键盘高度
    public var keyboardHeightBlock: () -> Float

    /// 键盘是否要覆盖 safeArea
    public var coverSafeArea: Bool

    /// 返回 键盘图标 normal/selected/disable
    public var keyboardIcon: (UIImage?, UIImage?, UIImage?)

    /// 点击键盘效果 返回 true 则 调用 keyboardViewBlock keyboardHeight 之后展示键盘
    public var selectedAction: (() -> Bool)?

    public var onTapped: (KeyboardPanelEvent) -> Void

    public var badgeTypeBlock: () -> KeyboardIconBadgeType

    public var keyboardStatusChange: ((UIView, Bool) -> Void)?

    public init(
        key: String,
        keyboardViewBlock: @escaping () -> UIView,
        keyboardHeightBlock: @escaping () -> Float,
        coverSafeArea: Bool = false,
        keyboardIcon: (UIImage?, UIImage?, UIImage?),
        onTapped: @escaping (KeyboardPanelEvent) -> Void = InputKeyboardItem.defaultTapHandler,
        keyboardStatusChange: ((UIView, Bool) -> Void)? = nil,
        badgeTypeBlock: @escaping () -> KeyboardIconBadgeType = { return .none },
        selectedAction: (() -> Bool)?) {
        self.key = key
        self.keyboardViewBlock = keyboardViewBlock
        self.keyboardHeightBlock = keyboardHeightBlock
        self.keyboardIcon = keyboardIcon
        self.coverSafeArea = coverSafeArea
        self.onTapped = onTapped
        self.badgeTypeBlock = badgeTypeBlock
        self.selectedAction = selectedAction
        self.keyboardStatusChange = keyboardStatusChange
    }
}
