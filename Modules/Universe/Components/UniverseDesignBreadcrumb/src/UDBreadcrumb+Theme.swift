//
//  UDBreadcrumb+Theme.swift
//  UniverseDesignBreadcrumb
//
//  Created by 姚启灏 on 2020/11/18.
//

import UIKit
import Foundation
import UniverseDesignColor

/// UDColor Name Extension
public extension UDColor.Name {

    /// Breadcrumb Navigation Text Color Key, Value: "breadcrumb-navigation-text-color"
    static let breadcrumbNavigationTextColor = UDColor.Name("breadcrumb-navigation-text-color")

    /// Breadcrumb Current Text Color Key, Value: "breadcrumb-current-text-color"
    static let breadcrumbCurrentTextColor = UDColor.Name("breadcrumb-current-text-color")

    /// Breadcrumb Icon Color Key, Value: "breadcrumb-icon-color"
    static let breadcrumbIconColor = UDColor.Name("breadcrumb-icon-color")

    /// BreadcrumbItem Highted Background Color Key, Value: "breadcrumb-item-backgroundColor-highted-color"
    static let breadcrumbItemHightedBackgroundColor = UDColor.Name("breadcrumb-item-backgroundColor-highted-color")
}

/// UDBreadcrumb Color Theme
public struct UDBreadcrumbColorTheme {
    /// Default N500
    public static var breadcrumbNavigationTextColor: UIColor {
        return UDColor
            .getValueByKey(.breadcrumbNavigationTextColor) ?? UDColor.textCaption
    }

    /// Default colorfulBlue
    public static var breadcrumbCurrentTextColor: UIColor {
        return UDColor
            .getValueByKey(.breadcrumbCurrentTextColor) ?? UDColor.primaryContentDefault
    }

    /// Default N500
    public static var breadcrumbIconColor: UIColor {
        return UDColor
            .getValueByKey(.breadcrumbIconColor) ?? UDColor.iconN3
    }

    /// Default colorfulBlue.withAlphaComponent(0.1)
    public static var breadcrumbItemHightedBackgroundColor: UIColor {
        return UDColor
            .getValueByKey(.breadcrumbItemHightedBackgroundColor) ?? UDColor.udtokenBtnSeBgPriPressed & UDColor.udtokenBtnSeBgPriPressed.withAlphaComponent(0.2)
    }
}
