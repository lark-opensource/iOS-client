//
//  UDTextField+UIConfig.swift
//  Pods-UniverseDesignInputDev
//
//  Created by 姚启灏 on 2020/9/22.
//

import UIKit
import Foundation
import UniverseDesignFont
import UniverseDesignColor

/// UDTextField UIConfig
public struct UDTextFieldUIConfig {
    /// 是否展示Border
    public var isShowBorder: Bool

    /// 是否展示标题
    public var isShowTitle: Bool

    /// 是否展示清除按钮
    public var clearButtonMode: UITextField.ViewMode

    /// 背景色
    public var backgroundColor: UIColor?

    /// Border颜色
    public var borderColor: UIColor?

    /// Border 活跃状态颜色
    public var borderActivatedColor: UIColor?

    /// 文本颜色
    public var textColor: UIColor?

    /// 占位符颜色
    public var placeholderColor: UIColor?

    /// 字体
    public var font: UIFont?

    /// 文本边距
    public var textMargins: UIEdgeInsets

    /// image边距
    public var leftImageMargins: UIEdgeInsets?

    /// image边距
    public var rightImageMargins: UIEdgeInsets?
    
    /// 左图和输入框的间距, 默认值-12
    public var leftImageMargin: CGFloat?
    
    /// 右图和输入框的间距, 默认值12
    public var rightImageMargin: CGFloat?

    /// 全部内容的边距
    public var contentMargins: UIEdgeInsets

    /// 错误信息
    public var errorMessege: String?

    /// 最大字符数
    public var maximumTextLength: Int?

    /// 自定义字符计数方法（指定 Character 对应的长度）
    public var countingRule: (Character) -> Float = { _ in 1 }

    /// 文本对准
    public var textAlignment: NSTextAlignment

    /// 最小字体
    public var minimumFontSize: CGFloat

    /// 创建 UDTextFieldUIConfig 实例
    /// - Parameters:
    ///   - isShowBorder: 是否展示 Border
    ///   - isShowTitle: 是否展示标题
    ///   - clearButtonMode: 是否展示清除按钮
    ///   - backgroundColor: 背景色
    ///   - borderColor: Border颜色
    ///   - textColor: 文本颜色
    ///   - placeholderColor: 占位符颜色
    ///   - font: 字体
    ///   - textMargins: 文本边距
    ///   - contentMargins: 内容区域边距
    ///   - leftImageMargins: Icon 左侧边距
    ///   - rightImageMargins: Icon 右侧边距
    ///   - errorMessege: 错误信息
    ///   - maximumTextLength: 最大字符数
    ///   - textAlignment: 文本对准
    ///   - minimumFontSize: 最小字体
    public init(isShowBorder: Bool = false,
                isShowTitle: Bool = false,
                clearButtonMode: UITextField.ViewMode = .never,
                backgroundColor: UIColor? = nil,
                borderColor: UIColor? = UDInputColorTheme.inputNormalBorderColor,
                textColor: UIColor? = UDInputColorTheme.inputInputtingTextColor,
                placeholderColor: UIColor? = UDInputColorTheme.inputNormalPlaceholderTextColor,
                font: UIFont? = UDFont.body0,
                textMargins: UIEdgeInsets = UIEdgeInsets(top: 13, left: 12, bottom: 13, right: 12),
                contentMargins: UIEdgeInsets = UIEdgeInsets.zero,
                leftImageMargins: UIEdgeInsets? = nil,
                rightImageMargins: UIEdgeInsets? = nil,
                leftImageMargin: CGFloat? = nil,
                rightImageMargin: CGFloat? = nil,
                errorMessege: String? = nil,
                maximumTextLength: Int? = nil,
                textAlignment: NSTextAlignment = .left,
                minimumFontSize: CGFloat = 16) {
        self.isShowBorder = isShowBorder
        self.isShowTitle = isShowTitle
        self.clearButtonMode = clearButtonMode
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.textColor = textColor
        self.placeholderColor = placeholderColor
        self.font = font
        self.textMargins = textMargins
        self.contentMargins = contentMargins
        self.errorMessege = errorMessege
        self.maximumTextLength = maximumTextLength
        self.textAlignment = textAlignment
        self.minimumFontSize = minimumFontSize
        self.leftImageMargins = leftImageMargins
        self.rightImageMargins = rightImageMargins
       self.leftImageMargin = leftImageMargin
       self.rightImageMargin = rightImageMargin
    }
}
