//
//  UDBadge+Style.swift
//  UniverseDesignBadge
//
//  Created by Meng on 2020/10/28.
//

import Foundation
import UIKit
import UniverseDesignColor

/// UDBadgeColorStyle
public enum UDBadgeColorStyle {
    /// dot background red Color, default color: alertColor6
    case dotBGRed
    /// dot background grey color, default color: neutralColor6
    case dotBGGrey
    /// dot background blue color, default color: primaryColor4
    case dotBGBlue
    /// dot background green color, default color: T600
    case dotBGGreen
    /// chatacter background red color, default color: alertColor6
    case characterBGRed
    /// character background grey color, default color: neutralColor6
    case characterBGGrey
    /// dot border white color, default color: neutralColor1
    case dotBorderWhite
    /// dot character text color, default color: neutralColor1
    case dotCharacterText
    /// dot character limit icon color, default color: neutralColor1
    case dotCharacterLimitIcon
    /// dot border darkgrey color, default color: neutralColor8
    case dotBorderDarkgrey
    /// custom color
    case custom(UIColor)

    /// theme color value
    public var color: UIColor {
        switch self {
        case .dotBGRed:
            return UDBadgeColorTheme.dotBGRed
        case .dotBGGrey:
            return UDBadgeColorTheme.dotBGGrey
        case .dotBGBlue:
            return UDBadgeColorTheme.dotBGBlue
        case .dotBGGreen:
            return UDBadgeColorTheme.dotBGGreen
        case .characterBGRed:
            return UDBadgeColorTheme.characterBGRed
        case .characterBGGrey:
            return UDBadgeColorTheme.characterBGGrey
        case .dotBorderWhite:
            return UDBadgeColorTheme.dotBorderWhite
        case .dotCharacterText:
            return UDBadgeColorTheme.dotCharacterText
        case .dotCharacterLimitIcon:
            return UDBadgeColorTheme.dotCharacterLimitIcon
        case .dotBorderDarkgrey:
            return UDBadgeColorTheme.dotBorderDarkgrey
        case let .custom(customColor):
            return customColor
        }
    }
}

extension UDBadgeColorStyle: Equatable {
    public static func == (lhs: UDBadgeColorStyle, rhs: UDBadgeColorStyle) -> Bool {
        switch (lhs, rhs) {
        case (.dotBGRed, .dotBGRed),
             (.dotBGGrey, .dotBGGrey),
             (.dotBGBlue, .dotBGBlue),
             (.dotBGGreen, .dotBGGreen),
             (.characterBGRed, .characterBGRed),
             (.characterBGGrey, .characterBGGrey),
             (.dotBorderWhite, .dotBorderWhite),
             (.dotCharacterText, .dotCharacterText),
             (.dotCharacterLimitIcon, .dotCharacterLimitIcon),
             (.dotBorderDarkgrey, .dotBorderDarkgrey):
            return true
        case let (.custom(color1), .custom(color2)):
            return color1.hashValue == color2.hashValue
        default:
            return false
        }
    }
}

/// UDBadgeBorder
public enum UDBadgeBorder {
    /// no border
    case none
    /// border with 2px
    case outer
    /// border with 1px
    case inner

    /// border width
    var width: CGFloat {
        switch self {
        case .none:
            return 0.0
        case .outer:
            return 2.0
        case .inner:
            return 1.0
        }
    }

    /// border layout padding for badge
    var padding: CGFloat {
        switch self {
        case .none, .inner:
            return 0.0
        case .outer:
            return 2 * 2.0
        }
    }
}
