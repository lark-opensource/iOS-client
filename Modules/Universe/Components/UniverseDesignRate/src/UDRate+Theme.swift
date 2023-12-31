//
//  UDRate+Theme.swift
//  UniverseDesignRate
//
//  Created by 姚启灏 on 2021/2/28.
//

import UIKit
import Foundation
import UniverseDesignColor

/// UDColor Name Extension
public extension UDColor.Name {
    /// Rate Star Unselected Color, Value: "rate-star-unselected-color"
    static let rateStarUnselectedColor = UDColor.Name("rate-star-unselected-color")

    /// Rate Star Selected Color, Value: "rate-star-selected-color"
    static let rateStarSelectedColor = UDColor.Name("rate-star-selected-color")

    /// Rate Label Color, Value: "rate-label-color"
    static let rateLabelColor = UDColor.Name("rate-label-color")
}

/// UDRate Color Theme
public struct UDRateColorTheme {

    /// Rate Star Unselected Color,  Default Color: UDColor.neutralColor1
    public static var rateStarUnselectedColor: UIColor {
        return UDColor.getValueByKey(.rateStarUnselectedColor) ?? UDColor.N900.withAlphaComponent(0.15)
    }

    /// Rate Star Selected Color, Default Color: UDColor.neutralColor1
    public static var rateStarSelectedColor: UIColor {
        return UDColor.getValueByKey(.rateStarSelectedColor) ?? UDColor.colorfulYellow
    }

    /// Rate Label Color, Default Color: UDColor.neutralColor1
    public static var rateLabelColor: UIColor {
        return UDColor.getValueByKey(.rateLabelColor) ?? UDColor.textCaption
    }
}
