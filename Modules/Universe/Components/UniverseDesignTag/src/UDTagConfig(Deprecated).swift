//
//  UDTagConfig.swift
//  UniverseDesignTag
//
//  Created by 王元洵 on 2020/10/14.
//

import UIKit
import Foundation
import UniverseDesignColor
import UniverseDesignStyle


@available(*, deprecated, message:"Use UDTag.Configuration")
public enum UDTagConfig {

    ///文本类型
    case text(TextConfig)
    ///图片类型
    case icon(IconConfig)
}

extension UDTagConfig {

    var height: Int {
        switch self {
        case .text(let textConfig):         return textConfig.height
        case .icon(let iconConfig):         return iconConfig.height
        }
    }

    var isIconHidden: Bool {
        switch self {
        case .text:         return true
        case .icon:         return false
        }
    }

    var isTextHidden: Bool {
        switch self {
        case .text:         return false
        case .icon:         return true
        }
    }

    var padding: UIEdgeInsets {
        switch self {
        case .text(let textConfig):
            return textConfig.padding
        case .icon(let iconConfig):
            let inset = (CGFloat(iconConfig.height) - iconConfig.iconSize.height) / 2
            return UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .text(let textConfig):         return textConfig.backgroundColor
        case .icon(let iconConfig):         return iconConfig.backgroundColor
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .text(let textConfig):         return textConfig.cornerRadius
        case .icon(let iconConfig):         return iconConfig.cornerRadius
        }
    }
}

public extension UDTagConfig {

    // MARK: - TextConfig

    ///文本tag配置
    struct TextConfig {
        ///边界间隙
        public var padding: UIEdgeInsets
        ///字体
        public var font: UIFont
        ///圆角
        public var cornerRadius: CGFloat
        ///字体对齐
        public var textAlignment: NSTextAlignment
        ///字体颜色
        public var textColor: UIColor
        ///背景颜色
        public var backgroundColor: UIColor
        ///高度
        public var height: Int
        ///最大宽度
        public var maxLenth: Int?
        ///初始化方法
        public init (padding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4),
                     font: UIFont = .systemFont(ofSize: 12, weight: .medium),
                     cornerRadius: CGFloat = UDStyle.smallRadius,
                     textAlignment: NSTextAlignment = .center,
                     textColor: UIColor = UDTagColorTheme.tagForegroundColor,
                     backgroundColor: UIColor = UDTagColorTheme.tagBackgroundColor,
                     height: Int = 18,
                     maxLenth: Int? = nil) {
            self.padding = padding
            self.font = font
            self.cornerRadius = cornerRadius
            self.textAlignment = textAlignment
            self.textColor = textColor
            self.backgroundColor = backgroundColor
            self.height = height
            self.maxLenth = maxLenth
        }
    }

    // MARK: - IconConfig

    ///图片tag配置
    struct IconConfig {
        ///圆角
        public var cornerRadius: CGFloat
        ///icon颜色
        public var iconColor: UIColor?
        ///背景颜色
        public var backgroundColor: UIColor
        ///高度
        public var height: Int
        ///图片尺寸
        public var iconSize: CGSize
        ///初始化函数
        public init(cornerRadius: CGFloat = UDStyle.smallRadius,
                    iconColor: UIColor? = nil,
                    backgroundColor: UIColor = UDTagColorTheme.tagBackgroundColor,
                    height: Int = 18,
                    iconSize: CGSize = CGSize(width: 12, height: 12)) {
            self.cornerRadius = cornerRadius
            self.iconColor = iconColor
            self.backgroundColor = backgroundColor
            self.height = height
            self.iconSize = iconSize
        }
    }
}

/// UDColor Name Extension
public extension UDColor.Name {
    /// tag foreground color key
    static let tagForegroundColor = UDColor.Name("tag-fg-color")
    /// tag background color key
    static let tagBackgroundColor = UDColor.Name("tag-bg-color")
}

/// UDTag Color Theme
public struct UDTagColorTheme {
    /// Tag Foreground Color, Default Color: neutralColor8
    public static var tagForegroundColor: UIColor {
        return UDColor.getValueByKey(.tagForegroundColor) ?? UDColor.N600
    }

    /// Tag Background Color, Default Color: neutralColor12.withAlphaComponent(0.1)
    public static var tagBackgroundColor: UIColor {
        return UDColor.getValueByKey(.tagBackgroundColor) ?? UDColor.N900.withAlphaComponent(0.1)
    }
}

extension UDTagConfig {
    
    func toNewConfiguration(icon: UIImage? = nil, text: String? = nil) -> UDTag.Configuration {
        switch self {
        case .text(let textConfig):
            return .init(
                icon: nil,
                text: text,
                height: CGFloat(textConfig.height),
                backgroundColor: textConfig.backgroundColor,
                cornerRadius: textConfig.cornerRadius,
                horizontalMargin: textConfig.padding.left,
                iconTextSpacing: 0,
                textAlignment: textConfig.textAlignment,
                textColor: textConfig.textColor,
                iconSize: CGSize(width: 0, height: 0),
                iconColor: nil,
                font: textConfig.font
            )
        case .icon(let iconConfig):
            return .init(
                icon: icon,
                text: nil,
                height: CGFloat(iconConfig.height),
                backgroundColor: iconConfig.backgroundColor,
                cornerRadius: iconConfig.cornerRadius,
                horizontalMargin: 3,
                iconTextSpacing: 0,
                textAlignment: .center,
                textColor: nil,
                iconSize: iconConfig.iconSize,
                iconColor: iconConfig.iconColor,
                font: UIFont.systemFont(ofSize: 0)
            )
        }
    }
}
