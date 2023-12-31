//
//  UDEmpty+Theme.swift
//  UniverseDesignEmpty
//
//  Created by 王元洵 on 2020/11/18.
//

import UIKit
import Foundation
import UniverseDesignColor

/// UDColor Name Extension
public extension UDColor.Name {
    /// initial empty title color key
    static let emptyTitleColor = UDColor.Name("empty-title-text-normal-color")
    /// initial empty description color key
    static let emptyDescriptionColor = UDColor.Name("empty-body-text-normal-color")

    /// ngetive empty operable color key
    static let emptyNegtiveOperableColor = UDColor.Name("empty-negativebody-text-operability-color")

    /// primary button border color key
    static let primaryButtonBorderColor = UDColor.Name("empty-primary_btn-border-color")
    /// primary button background color key
    static let primaryButtonBackgroundColor = UDColor.Name("empty-primary_btn-background-color")
    /// primary button text color key
    static let primaryButtoTextColor = UDColor.Name("empty-primary_btn-text-color")

    /// secondary button border color key
    static let secondaryButtonBorderColor = UDColor.Name("empty-secondary_btn-border-color")
    /// secondary button background color key
    static let secondaryButtonBackgroundColor = UDColor.Name("empty-secondary_btn-background-color")
    /// secondary button text color key
    static let secondaryButtonTextColor = UDColor.Name("empty-secondary_btn-text-color")
}

/// UDTag Color Theme
public struct UDEmptyColorTheme {
    /// initial empty title color, Default Color: neutralColor12
    public static var emptyTitleColor: UIColor {
        return UDColor.getValueByKey(.emptyTitleColor) ?? UDColor.textTitle
    }
    /// initial empty description color, Default Color: neutralColor8
    public static var emptyDescriptionColor: UIColor {
        return UDColor.getValueByKey(.emptyDescriptionColor) ?? UDColor.textCaption
    }

    /// ngetive empty operable color, Default Color: primaryColor6
    public static var emptyNegtiveOperableColor: UIColor {
        return UDColor.getValueByKey(.emptyNegtiveOperableColor) ?? UDColor.primaryContentDefault
    }

    /// primary button border color, Default Color: clear
    public static var primaryButtonBorderColor: UIColor {
        return UDColor.getValueByKey(.primaryButtonBorderColor) ?? UIColor.clear
    }
    /// primary button background color key
    public static var primaryButtonBackgroundColor: UIColor {
        return UDColor.getValueByKey(.primaryButtonBackgroundColor) ?? UDColor.primaryFillDefault
    }
    /// primary button text color key
    public static var primaryButtonTextColor: UIColor {
        return UDColor.getValueByKey(.primaryButtoTextColor) ?? UDColor.primaryOnPrimaryFill
    }

    /// secondary button border color, Default Color: clear
    public static var secondaryButtonBorderColor: UIColor {
        return UDColor.getValueByKey(.secondaryButtonBorderColor) ?? UDColor.lineBorderComponent
    }
    /// secondary button background color key
    public static var secondaryButtonBackgroundColor: UIColor {
        return UDColor.getValueByKey(.secondaryButtonBackgroundColor) ?? UIColor.clear
    }
    /// secondary button text color key
    public static var secondaryButtonTextColor: UIColor {
        return UDColor.getValueByKey(.secondaryButtonTextColor) ?? UDColor.textTitle
    }
}
