//
//  UDTagUIConfig.swift
//  UniverseDesignTag
//
//  Created by Hayden Wang on 2022/6/6.
//

import UIKit
import Foundation
import UniverseDesignStyle
import UniverseDesignColor
import UniverseDesignFont

extension UDTag {

    public struct Configuration: Equatable {

        // Common
        public var icon: UIImage?
        public var text: String?
        public var height: CGFloat

        public var backgroundColor: UIColor
        public var cornerRadius: CGFloat
        public var horizontalMargin: CGFloat

        // For text only
        public var textAlignment: NSTextAlignment
        public var textColor: UIColor?
        public var font: UIFont

        // For icon only
        public var iconColor: UIColor?
        public var iconSize: CGSize = CGSize(width: 0, height: 0)
        public var iconTextSpacing: CGFloat = 0

        public init(icon: UIImage?,
                    text: String?,
                    height: CGFloat,
                    backgroundColor: UIColor,
                    cornerRadius: CGFloat,
                    horizontalMargin: CGFloat,
                    iconTextSpacing: CGFloat,
                    textAlignment: NSTextAlignment,
                    textColor: UIColor?,
                    iconSize: CGSize,
                    iconColor: UIColor?,
                    font: UIFont
        ) {
            self.icon = icon
            self.text = text
            self.height = height
            self.backgroundColor = backgroundColor
            self.cornerRadius = cornerRadius
            self.horizontalMargin = horizontalMargin
            self.iconTextSpacing = iconTextSpacing
            self.textAlignment = textAlignment
            self.textColor = textColor
            self.iconSize = iconSize
            self.iconColor = iconColor
            self.font = font
        }
        
        enum TagType {
            case icon, text, iconText
        }
        
        var tagType: TagType {
            switch (icon != nil, text != nil) {
            case (true, false): return .icon
            case (false, true): return .text
            default:            return .iconText
            }
        }
    }
}

// MARK: - Factory methods

extension UDTag.Configuration {

    /// icon init
    /// - Parameters:
    ///   - icon: 图片标签图片
    ///   - tagSize: tag 大小
    ///   - colorScheme: 颜色方案
    ///   - isOpaque: 背景颜色是否不透明
    public static func icon(_ icon: UIImage,
                            tagSize: Size = .medium,
                            colorScheme: ColorScheme = .normal,
                            isOpaque: Bool = false) -> UDTag.Configuration {
        return self.init(
            icon: icon,
            text: nil,
            height: tagSize.height,
            backgroundColor: isOpaque ? colorScheme.opaqueBgColor : colorScheme.transparentBgColor,
            cornerRadius: tagSize.cornerRadius,
            horizontalMargin: tagSize.horizontalMarginIconOnly,
            iconTextSpacing: tagSize.iconTextSpacing,
            textAlignment: .center,
            textColor: colorScheme.textColor,
            iconSize: tagSize.iconSize,
            iconColor: colorScheme.iconColor,
            font: tagSize.font
        )
    }

    /// text init
    /// - Parameters:
    ///   - text: 文本标签文案
    ///   - tagSize: tag 大小
    ///   - colorScheme: 颜色方案
    ///   - isOpaque: 背景颜色是否不透明
    public static func text(_ text: String,
                            tagSize: Size = .medium,
                            colorScheme: ColorScheme = .normal,
                            isOpaque: Bool = false) -> UDTag.Configuration {
        return self.init(
            icon: nil,
            text: text,
            height: tagSize.height,
            backgroundColor: isOpaque ? colorScheme.opaqueBgColor : colorScheme.transparentBgColor,
            cornerRadius: tagSize.cornerRadius,
            horizontalMargin: tagSize.horizontalMarginIconOnly,
            iconTextSpacing: tagSize.iconTextSpacing,
            textAlignment: .center,
            textColor: colorScheme.textColor,
            iconSize: tagSize.iconSize,
            iconColor: colorScheme.iconColor,
            font: tagSize.font
        )
    }
    /// iconText init
    /// - Parameters:
    ///   - icon: 图片标签图片
    ///   - text: 文本标签文案
    ///   - tagSize: tag 大小
    ///   - colorScheme: 颜色方案
    ///   - isOpaque: 背景颜色是否不透明
    public static func iconText(_ icon: UIImage,
                                text: String,
                                tagSize: Size = .medium,
                                colorScheme: ColorScheme = .normal,
                                isOpaque: Bool = false) -> UDTag.Configuration {
        return self.init(
            icon: icon,
            text: text,
            height: tagSize.height,
            backgroundColor: isOpaque ? colorScheme.opaqueBgColor : colorScheme.transparentBgColor,
            cornerRadius: tagSize.cornerRadius,
            horizontalMargin: tagSize.horizontalMarginIconOnly,
            iconTextSpacing: tagSize.iconTextSpacing,
            textAlignment: .center,
            textColor: colorScheme.textColor,
            iconSize: tagSize.iconSize,
            iconColor: colorScheme.iconColor,
            font: tagSize.font
        )
    }
}

extension UDTag.Configuration {
    ///提供四种尺寸
    public enum Size {

        case mini
        case small
        case medium
        case large

        var font: UIFont {
            switch self{
            case .mini:     return UDFont.caption0(.fixed)
            case .small:    return UDFont.body2(.fixed)
            case .medium:   return UDFont.body0(.fixed)
            case .large:    return UDFont.title4(.fixed)
            }
        }

        var height: CGFloat {
            switch self{
            case .mini:     return 18
            case .small:    return 24
            case .medium:   return 28
            case .large:    return 32
            }
        }

        var iconSize: CGSize {
            switch self{
            case .mini:     return CGSize(width: 12, height: 12)
            case .small:    return CGSize(width: 14, height: 14)
            case .medium:   return CGSize(width: 16, height: 16)
            case .large:    return CGSize(width: 18, height: 18)
            }
        }

        var iconTextSpacing: CGFloat {
            switch self {
            case .mini:     return 2
            case .small:    return 4
            case .medium:   return 4
            case .large:    return 6
            }
        }

        var horizontalMarginNormal: CGFloat {
            switch self {
            case .mini:     return 4
            case .small:    return 6
            case .medium:   return 6
            case .large:    return 8
            }
        }

        var horizontalMarginIconOnly: CGFloat {
            switch self {
            case .mini:     return 3
            case .small:    return 5
            case .medium:   return 6
            case .large:    return 7
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .mini:     return UDStyle.smallRadius
            case .small:    return UDStyle.smallRadius
            case .medium:   return UDStyle.smallRadius
            case .large:    return UDStyle.smallRadius
            }
        }
    }

    ///12种颜色
    public enum ColorScheme: Equatable {

        case normal
        case blue
        case red
        case green
        case yellow
        case orange
        case wathet
        case indigo
        case turquoise
        case lime
        case purple
        case carmine
        case custom(iconColor: UIColor?)

        public var textColor: UIColor {
            switch self {
            case .normal:   	return UIColor.ud.udtokenTagNeutralTextNormal
            case .blue:     	return UIColor.ud.udtokenTagTextSBlue
            case .red:          return UIColor.ud.udtokenTagTextSRed
            case .green:        return UIColor.ud.udtokenTagTextSGreen
            case .yellow:   	return UIColor.ud.udtokenTagTextSYellow
            case .orange:       return UIColor.ud.udtokenTagTextSOrange
            case .wathet:       return UIColor.ud.udtokenTagTextSWathet
            case .indigo:       return UIColor.ud.udtokenTagTextSIndigo
            case .turquoise:    return UIColor.ud.udtokenTagTextSTurquoise
            case .lime:         return UIColor.ud.udtokenTagTextSLime
            case .purple:       return UIColor.ud.udtokenTagTextSPurple
            case .carmine:      return UIColor.ud.udtokenTagTextSCarmine
            case .custom(_):    return UIColor.ud.udtokenTagNeutralTextNormal
            }
        }

        public var iconColor: UIColor? {
            switch self {
            case .normal:       return UIColor.ud.udtokenTagNeutralTextNormal
            case .blue:         return UIColor.ud.udtokenTagTextSBlue
            case .red:          return UIColor.ud.udtokenTagTextSRed
            case .green:        return UIColor.ud.udtokenTagTextSGreen
            case .yellow:       return UIColor.ud.udtokenTagTextSYellow
            case .orange:       return UIColor.ud.udtokenTagTextSOrange
            case .wathet:       return UIColor.ud.udtokenTagTextSWathet
            case .indigo:       return UIColor.ud.udtokenTagTextSIndigo
            case .turquoise:    return UIColor.ud.udtokenTagTextSTurquoise
            case .lime:         return UIColor.ud.udtokenTagTextSLime
            case .purple:       return UIColor.ud.udtokenTagTextSPurple
            case .carmine:      return UIColor.ud.udtokenTagTextSCarmine
            case .custom(let iconColor):    return iconColor
            }
        }
        
        public var opaqueBgColor: UIColor {
            switch self {
            case .normal:       return UIColor.ud.udtokenTagNeutralBgSolid
            case .blue:         return UIColor.ud.udtokenTagBgBlueSolid
            case .red:          return UIColor.ud.udtokenTagBgRedSolid
            case .green:        return UIColor.ud.udtokenTagBgGreenSolid
            case .yellow:       return UIColor.ud.udtokenTagBgYellowSolid
            case .orange:       return UIColor.ud.udtokenTagBgOrangeSolid
            case .wathet:       return UIColor.ud.udtokenTagBgWathetSolid
            case .indigo:       return UIColor.ud.udtokenTagBgIndigoSolid
            case .turquoise:    return UIColor.ud.udtokenTagBgTurquoiseSolid
            case .lime:         return UIColor.ud.udtokenTagBgLimeSolid
            case .purple:       return UIColor.ud.udtokenTagBgPurpleSolid
            case .carmine:      return UIColor.ud.udtokenTagBgCarmineSolid
            case .custom:       return UIColor.ud.udtokenTagNeutralBgSolid
            }
        }

        public var transparentBgColor: UIColor {
            switch self {
            case .normal:       return UIColor.ud.udtokenTagNeutralBgNormal.withAlphaComponent(0.1)
            case .blue:         return UIColor.ud.udtokenTagBgBlue.withAlphaComponent(0.2)
            case .red:          return UIColor.ud.udtokenTagBgRed.withAlphaComponent(0.2)
            case .green:        return UIColor.ud.udtokenTagBgGreen.withAlphaComponent(0.2)
            case .yellow:       return UIColor.ud.udtokenTagBgYellow.withAlphaComponent(0.2)
            case .orange:       return UIColor.ud.udtokenTagBgOrange.withAlphaComponent(0.2)
            case .wathet:       return UIColor.ud.udtokenTagBgWathet.withAlphaComponent(0.2)
            case .indigo:       return UIColor.ud.udtokenTagBgIndigo.withAlphaComponent(0.2)
            case .turquoise:    return UIColor.ud.udtokenTagBgTurquoise.withAlphaComponent(0.2)
            case .lime:         return UIColor.ud.udtokenTagBgLime.withAlphaComponent(0.2)
            case .purple:       return UIColor.ud.udtokenTagBgPurple.withAlphaComponent(0.2)
            case .carmine:      return UIColor.ud.udtokenTagBgCarmine.withAlphaComponent(0.2)
            case .custom:       return UIColor.ud.udtokenTagNeutralBgNormal.withAlphaComponent(0.1)
            }
        }
    }
}
