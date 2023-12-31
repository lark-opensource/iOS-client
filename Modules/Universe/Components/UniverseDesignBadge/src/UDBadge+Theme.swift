//
//  UDBadge+Theme.swift
//  UniverseDesignBadge
//
//  Created by Meng on 2020/11/30.
//

import UIKit
import Foundation
import UniverseDesignTheme
import UniverseDesignColor

extension UDColor.Name {
    /// dot background red Color, Value: "badge-dot-bg-red-color"
    public static let dotBGRedColor = UDColor.Name("badge-dot-bg-red-color")

    /// dot background grey color, Value: "badge-dot-bg-grey-color"
    public static let dotBGGreyColor = UDColor.Name("badge-dot-bg-grey-color")

    /// dot background blue color, Value: "badge-dot-bg-blue-color"
    public static let dotBGBlueColor = UDColor.Name("badge-dot-bg-blue-color")

    /// dot background green color, Value: "badge-dot-bg-green-color"
    public static let dotBGGreenColor = UDColor.Name("badge-dot-bg-green-color")

    /// chatacter background red color, Value: "badge-character-bg-red-color"
    public static let characterBGRedColor = UDColor.Name("badge-character-bg-red-color")

    /// character background grey color, Value: "badge-character-bg-grey-color"
    public static let characterBGGreyColor = UDColor.Name("badge-character-bg-grey-color")

    /// dot border white color, Value: "badge-dot-border-white-color"
    public static let dotBorderWhiteColor = UDColor.Name("badge-dot-border-white-color")

    /// dot character text color, Value: "badge-dot-character-text-color"
    public static let dotCharacterTextColor = UDColor.Name("badge-dot-character-text-color")

    /// dot character limit icon color, Value: "badge-dot-characterlimit-icon-color"
    public static let dotCharacterLimitIconColor = UDColor.Name("badge-dot-characterlimit-icon-color")

    /// dot border darkgrey color, Value: "badge-dot-border-darkgrey-color"
    public static let dotBorderDarkgreyColor = UDColor.Name("badge-dot-border-darkgrey-color")
}

/// UDBadgeColorTheme
public struct UDBadgeColorTheme {
    /// dot background red Color, default color: alertColor6
    public static var dotBGRed: UIColor {
        return UDColor.getValueByKey(.dotBGRedColor) ?? UDColor.functionDangerContentDefault
    }
    /// dot background grey color, default color: neutralColor6
    public static var dotBGGrey: UIColor {
        return UDColor.getValueByKey(.dotBGGreyColor) ?? UDColor.iconDisabled
    }
    /// dot background blue color, default color: primaryColor4
    public static var dotBGBlue: UIColor {
        return UDColor.getValueByKey(.dotBGBlueColor) ?? UDColor.primaryFillDefault
    }
    /// dot background green color, default color: T600
    public static var dotBGGreen: UIColor {
        return UDColor.getValueByKey(.dotBGGreenColor) ?? UDColor.T600
    }
    /// chatacter background red color, default color: alertColor6
    public static var characterBGRed: UIColor {
        return UDColor.getValueByKey(.characterBGRedColor) ?? UDColor.functionDangerContentDefault
    }
    /// character background grey color, default color: neutralColor6
    public static var characterBGGrey: UIColor {
        return UDColor.getValueByKey(.characterBGGreyColor) ?? UDColor.iconDisabled
    }
    /// dot border white color, default color: neutralColor1
    public static var dotBorderWhite: UIColor {
        return UDColor.getValueByKey(.dotBorderWhiteColor) ?? UDColor.neutralColor1
    }
    /// dot character text color, default color: neutralColor1
    public static var dotCharacterText: UIColor {
        return UDColor.getValueByKey(.dotCharacterTextColor) ?? UDColor.primaryOnPrimaryFill
    }
    /// dot character limit icon color, default color: neutralColor1
    public static var dotCharacterLimitIcon: UIColor {
        return UDColor.getValueByKey(.dotCharacterLimitIconColor) ?? UDColor.primaryOnPrimaryFill
    }
    /// dot border darkgrey color, default color: neutralColor8
    public static var dotBorderDarkgrey: UIColor {
        return UDColor.getValueByKey(.dotBorderDarkgreyColor) ?? UDColor.neutralColor8
    }
}
