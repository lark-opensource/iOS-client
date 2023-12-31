//
//  UDCheckBox+Theme.swift
//  UniverseDesignCheckBox
//
//  Created by 姚启灏 on 2020/11/18.
//

import UIKit
import Foundation
import UniverseDesignColor

/// UDColor Name Extension
public extension UDColor.Name {

    /// Checkbox Unselected Border Enabled Color Key, Value: "checkbox-unselected-border-enabled-color"
    static let checkboxUnselectedBorderEnabledColor = UDColor.Name("checkbox-unselected-border-enabled-color")

    /// Checkbox Unselected Background Enabled Color Key, Value: "checkbox-unselected-background-enabled-colorr"
    static let checkboxUnselectedBackgroundEnabledColor =
        UDColor.Name("checkbox-unselected-background-enabled-color")

    /// Checkbox Unselected Border Disabled Color Key, Value: "checkbox-unselected-border-disabled-color"
    static let checkboxUnselectedBorderDisabledColor = UDColor.Name("checkbox-unselected-border-disabled-color")

    /// Checkbox Selected Background Enabled Color Key, Value: "checkbox-selected-background-enabled-color"
    static let checkboxSelectedBackgroundEnabledColor = UDColor.Name("checkbox-selected-background-enabled-color")

    /// Checkbox Selected Background Disabled Color Key, Value: "checkbox-selected-background-disabled-color"
    static let checkboxSelectedBackgroundDisabledColor =
        UDColor.Name("checkbox-selected-background-disabled-color")
}

/// UDBreadcrumb Color Theme
public struct UDCheckBoxColorTheme {
    /// Default neutralColor7
    public static var borderEnabledColor: UIColor {
        return UDColor
            .getValueByKey(.checkboxUnselectedBorderEnabledColor) ?? UDColor.iconN3
    }

    /// Default neutralColor1
    public static var unselectedBackgroundEnabledColor: UIColor {
        return UDColor
            .getValueByKey(.checkboxUnselectedBackgroundEnabledColor) ?? UDColor.udtokenComponentOutlinedBg
    }

    /// Default neutralColor6
    public static var borderDisabledColor: UIColor {
        return UDColor
            .getValueByKey(.checkboxUnselectedBorderDisabledColor) ?? UDColor.N400
    }

    /// Default neutralColor4
    public static var unselectedBackgroundDisabledColor: UIColor {
        return UDColor
            .getValueByKey(.checkboxUnselectedBorderDisabledColor) ?? UDColor.N200
    }

    /// Default primaryColor6
    public static var selectedBackgroundEnabledColor: UIColor {
        return UDColor
            .getValueByKey(.checkboxSelectedBackgroundEnabledColor) ?? UDColor.primaryFillDefault
    }

    /// Default neutralColor6
    public static var selectedBackgroundDisabledColor: UIColor {
        return UDColor
            .getValueByKey(.checkboxSelectedBackgroundDisabledColor) ?? UDColor.fillDisabled
    }
}
