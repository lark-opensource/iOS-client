//
//  UDMultilineTextField+UIConfig.swift
//  UniverseDesignInput
//
//  Created by 姚启灏 on 2020/9/23.
//

import UIKit
import Foundation
import UniverseDesignColor
import UniverseDesignTheme

/// UDMultilineTextField UI Config
public struct UDMultilineTextFieldUIConfig {
    /// 是否展示Border
    public var isShowBorder: Bool

    /// 是否展示输入字数
    public var isShowWordCount: Bool

    /// 背景色
    public var backgroundColor: UIColor?

    /// Border颜色
    public var borderColor: UIColor?

    /// 文本颜色
    public var textColor: UIColor?

    /// 占位符颜色
    public var placeholderColor: UIColor?

    /// 字体
    public var font: UIFont?

    /// 文本边距
    public var textMargins: UIEdgeInsets

    /// 错误信息
    public var errorMessege: String?

    /// 最大字符数
    public var maximumTextLength: Int?

    /// 文本对准
    public var textAlignment: NSTextAlignment

    public var minHeight: CGFloat

    /// init
    /// - Parameters:
    ///   - isShowBorder: 是否展示Border
    ///   - isShowWordCount: 是否展示输入字数
    ///   - backgroundColor: 背景色
    ///   - borderColor: Border颜色
    ///   - textColor: 文本颜色
    ///   - placeholderColor: 占位符颜色
    ///   - font: 字体
    ///   - textMargins: 文本边距
    ///   - errorMessege: 错误信息
    ///   - maximumTextLength: 最大字符数
    ///   - textAlignment: 文本对准
    public init(isShowBorder: Bool = false,
                isShowWordCount: Bool = false,
                backgroundColor: UIColor? = nil,
                borderColor: UIColor? = UDInputColorTheme.inputNormalBorderColor,
                textColor: UIColor? = UDInputColorTheme.inputInputtingTextColor,
                placeholderColor: UIColor? = UDInputColorTheme.inputNormalPlaceholderTextColor,
                font: UIFont? = UIFont.ud.body0,
                textMargins: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 0, right: 8),
                errorMessege: String? = nil,
                maximumTextLength: Int? = nil,
                textAlignment: NSTextAlignment = .left,
                minHeight: CGFloat = 108) {
        self.isShowBorder = isShowBorder
        self.isShowWordCount = isShowWordCount
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.textColor = textColor
        self.placeholderColor = placeholderColor
        self.font = font
        self.textMargins = textMargins
        self.errorMessege = errorMessege
        self.maximumTextLength = maximumTextLength
        self.textAlignment = textAlignment
        self.minHeight = minHeight
    }
}
