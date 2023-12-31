//
//  UDMenuStyleConfig+Theme.swift
//  UniverseDesignMenu
//
//  Created by qsc on 2020/11/22.
//

import UIKit
import Foundation
import UniverseDesignColor

// swiftlint:disable all
/// UDColor Name Extension
public extension UDColor.Name {
    static let menuMaskColor = UDColor.Name("menu-mask-color")

    static let menuBackgroundColor = UDColor.Name("menu-background-color")

    static let menuTitleColor = UDColor.Name("menu-title-color")

    static let menuIconTintColor = UDColor.Name("menu-item-tint-color")

    static let menuItemBackgroundColor = UDColor.Name("menu-item-background-color")

    static let menuItemSelectedBackgroundColor = UDColor.Name("menu-item-selected-background-color")
    
    static let menuItemSeperatorColor = UDColor.Name("menu-item-seperator-color")

    static let menuTextDisableColor = UDColor.Name("menu-text-disable-color")

    static let menuIconDisableColor = UDColor.Name("menu-icon-Disable-color")

    static let menuDescriptionColor = UDColor.Name("menu-descrption-color")
}

/// UDMenu Color Theme
public struct UDMenuColorTheme {

    /// Menu mask background  color, default color: N1000.withAlphaComponent(0.3)
    public static var menuMaskColor: UIColor {
        return UDColor.getValueByKey(.menuMaskColor) ?? UDColor.N1000.withAlphaComponent(0.3) & .clear
    }

    /// Menu background  color, default color: bgFloat
    public static var menuBackgroundColor: UIColor {
        return UDColor.getValueByKey(.menuBackgroundColor) ?? UDColor.bgFloat
    }

    /// Menu title color, default color: neutralColor12
    public static var menuItemTitleColor: UIColor {
        return UDColor.getValueByKey(.menuTitleColor) ?? UDColor.textTitle
    }

    /// Menu item icon tint color, default color: neutralColor11
    public static var menuItemIconTintColor: UIColor {
        return UDColor.getValueByKey(.menuIconTintColor) ?? UDColor.iconN1
    }

    /// Menu title color, default color:.neutralColor1
    public static var menuItemBackgroundColor: UIColor {
        return UDColor.getValueByKey(.menuItemBackgroundColor) ?? UDColor.bgFloat
    }

    /// Menu select color, default color: fillPressed
    public static var menuItemSelectedBackgroundColor: UIColor {
        return UDColor.getValueByKey(.menuItemSelectedBackgroundColor) ?? UDColor.fillPressed
    }
    
    public static var menuItemSeperatorColor: UIColor {
        return UDColor.getValueByKey(.menuItemSeperatorColor) ?? UDColor.neutralColor5
    }

    /// Menu title disabled color, default color: textDisabled
    public static var menuTextDisableColor: UIColor {
        return UDColor.getValueByKey(.menuTextDisableColor) ?? UDColor.textDisabled
    }

    /// Menu icon disabled color, default color: iconDisabled
    public static var menuIconDisableColor: UIColor {
        return UDColor.getValueByKey(.menuIconDisableColor) ?? UDColor.iconDisabled
    }

    public static var menuSubTitleColor: UIColor {
        return UDColor.getValueByKey(.menuDescriptionColor) ?? UDColor.textPlaceholder
    }
}
// swiftlint:enable all
