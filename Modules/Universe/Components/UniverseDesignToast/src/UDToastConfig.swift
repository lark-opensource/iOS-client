//
//  UDToastConfig.swift
//  UniverseDesignToast
//
//  Created by 潘灶烽 on 2020/10/15.
//

import UIKit
import UniverseDesignColor
import UniverseDesignTheme

/// 提供通用样式配置
public enum UDToastType: Equatable {
    /// 展示info类型Toast
    case info
    /// 展示loading类型Toast
    case loading
    /// 展示success类型Toast
    case success
    /// 展示warning类型Toast
    case warning
    /// 展示error类型Toast
    case error
    /// 展示自定义图标的 Toast
    case custom(icon: UIImage, color: UIColor? = UIColor.ud.primaryOnPrimaryFill)
}

/// 操作显示类型
public enum UDOperationDisplayType {
    /// 水平类型操作按钮
    case horizontal
    /// 垂直类型操作按钮
    case vertical
    /// 自动换行
    case auto
}

public struct UDToastOperationConfig: Equatable {
    /// 右侧文字按钮文案（可选，默认为空）
    public var text: String
    /// 右侧文字显示方式， 横排还是竖排显示
    public var displayType: UDOperationDisplayType?

    public var textAlignment: NSTextAlignment = .left

    public init(text: String, displayType: UDOperationDisplayType? = nil) {
        self.text = text
        self.displayType = displayType
    }

    public static func == (left: UDToastOperationConfig, right: UDToastOperationConfig) -> Bool {
        return left.text == right.text
        && left.displayType == right.displayType
    }
}

public struct UDToastConfig: Equatable {

    /// Notice文本内容 （必选）
    public var text: String

    /// 左侧图标（可选，默认为空）
    public var toastType: UDToastType

    /// 右侧文字按钮文案（可选，默认为空）
    public var operation: UDToastOperationConfig?

    /// 消失时间
    public var delay: TimeInterval

    /// 提供的默认样式的构造方法，包含了type， 中间文字和操作文字
    /// - NOTE: `delay` 字段已从 `UDToastConfig` 中移出，请从 `show` 方法上设置，此处设置无效
    public init(toastType: UDToastType, text: String, operation: UDToastOperationConfig?, delay: TimeInterval = 3.0) {
        self.toastType = toastType
        self.text = text
        self.operation = operation
        self.delay = delay
    }

    public static func == (left: UDToastConfig, right: UDToastConfig) -> Bool {
        return left.text == right.text
        && left.toastType == right.toastType
        && left.operation == right.operation
    }
}
