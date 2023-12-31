//
//  UIColor+Utils.swift
//  DarkModeTest
//
//  Created by bytedance on 2021/3/26.
//

import Foundation
import UIKit

public extension UIColor {

    /// Returns the version of the current color that results from the specified traits.
    /// (Compatible with iOS versions lower than 13.0)
    /// - Parameter traitCollection: The traits to use when resolving the color information.
    /// - Returns: The version of the color to display for the specified traits.
    func resolvedCompatibleColor(with traitCollection: UITraitCollection) -> UIColor {
        if #available(iOS 13.0, *) {
            return resolvedColor(with: traitCollection)
        } else {
            return self
        }
    }

    /// define dynamic color with both light and dark mode.
    /// - Parameters:
    ///   - light: The color to use in light mode.
    ///   - dark: The color to use in dark mode.
    /// - Returns: A dynamic color that uses both given colors respectively for the given user interface style.
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { trait -> UIColor in
                switch trait.userInterfaceStyle {
                case .dark:
                    return dark.resolvedColor(with: .dark)
                default:
                    return light.resolvedColor(with: .light)
                }
            }
        } else {
            var newColor = light
            newColor.associatedDarkColor = dark
            return newColor
        }
    }

    /// Easily define dynamic color with both light and dark mode.
    /// - Parameters:
    ///   - lightColor: The color to use in light mode.
    ///   - darkColor: The color to use in dark mode.
    /// - Returns: A dynamic color that uses both given colors respectively for the given user interface style.
    static func & (lightColor: UIColor, darkColor: UIColor) -> UIColor {
        guard #available(iOS 13.0, *) else { return lightColor }
        return UIColor.dynamic(light: lightColor, dark: darkColor)
    }

    /// Easily define the opposite color of the dynamic color (reverse colors in light and dark mode).
    /// - Parameter color: The origin color.
    /// - Returns: Dynamic color The opposite color of light mode and dark mode.
    static prefix func - (color: UIColor) -> UIColor {
        guard #available(iOS 13.0, *) else { return color }
        return UIColor.dynamic(light: color.alwaysDark, dark: color.alwaysLight)
    }

    /// Returns a Boolean value indicating whether the color is dynamic.
    var isDynamic: Bool {
        guard #available(iOS 13, *) else { return false }
        /* 去除私有 API
        if let dynamicType = NSClassFromString("UIDynamicProviderColor") {
            return isMember(of: dynamicType)
        } else if let dynamicType = NSClassFromString("UIDynamicModifiedColor") {
            return isMember(of: dynamicType)
        } else {
            return alwaysLight != alwaysDark
        }
         */
        let lightColor = self.resolvedColor(with: .light)
        let darkColor = self.resolvedColor(with: .dark)
        return lightColor.hex8 != darkColor.hex8
    }

    /// Return a non-dynamic color (always in light mode) from input.
    var nonDynamic: UIColor {
        return alwaysLight
    }

    /// Return a non-dynamic color always in light mode.
    var alwaysLight: UIColor {
        if #available(iOS 13.0, *) {
            return self.resolvedColor(with: .light)
        } else {
            return self
        }
    }

    /// Return a non-dynamic color always in dark mode.
    var alwaysDark: UIColor {
        if #available(iOS 13.0, *) {
            return self.resolvedColor(with: .dark)
        } else {
            return self.associatedDarkColor ?? self
        }
    }
}

extension UIColor {

    private struct AssociatedKeys {
        static var darkColorKey = "UDColorDarkKey"
    }

    // swiftlint:disable all
    var associatedDarkColor: UIColor? {
        get {
            objc_getAssociatedObject(
                self,
                &AssociatedKeys.darkColorKey
            ) as? UIColor
        }
        set {
            guard newValue != associatedDarkColor else { return }
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.darkColorKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN
            )
        }
    }
    // swiftlint:enable all
}
