//
//  Color+Definition.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/4/8.
//

import UIKit
import Foundation
import SwiftUI

@available(iOS 13.0, *)
enum WidgetColor {

    /// 小组件的统一背景颜色
    static var background: Color { Color(UIColor.systemBackground) }

    static var secondaryBackground: Color { Color(UIColor.secondarySystemBackground) }

    static var text: Color { Color.primary }

    static var secondaryText: Color { Color.secondary }

    static var placeholder: Color { Color.secondary }
}

@available(iOS 13.0, *)
extension WidgetColor {

    enum Icon {
        static var orange: Color {
            Color("orange")
        }
        static var yellow: Color {
            Color("yellow")
        }
        static var green: Color {
            Color("green")
        }
        static var turquoise: Color {
            Color("turquoise")
        }
        static var wathet: Color {
            Color("wathet")
        }
        static var blue: Color {
            Color("blue")
        }
        static var purple: Color {
            Color("purple")
        }
        static var carmine: Color {
            Color("carmine")
        }
        static var allColors: [Color] {
            [Self.orange, Self.yellow, Self.green, Self.turquoise, Self.wathet, Self.blue, Self.purple, Self.carmine]
        }
    }
}

// MARK: - UDColor

@available(iOS 13.0, *)
extension WidgetColor {

    enum UD {
        static var N200: Color { Color(UIColor.rgb(0xEFF0F1) & UIColor.rgb(0x373737)) }
        static var N400: Color { Color(UIColor.rgb(0xBBBFC4) & UIColor.rgb(0x5F5F5F)) }
        static var B600: Color { Color(UIColor.rgb(0x245BDB) & UIColor.rgb(0x70A0FF)) }
        static var R600: Color { Color(UIColor.rgb(0xD83931) & UIColor.rgb(0xFA7873)) }
    }
}

@available(iOS 13.0, *)
enum UDColor {

    static var N200: Color = Color(UIColor.rgb(0xEFF0F1) & UIColor.rgb(0x373737))
    static var N400: Color = Color(UIColor.rgb(0xBBBFC4) & UIColor.rgb(0x5F5F5F))
    static var N500: Color = Color(UIColor.rgb(0x8F959E) & UIColor.rgb(0x757575))
    static var N600: Color = Color(UIColor.rgb(0x646A73) & UIColor.rgb(0xA6A6A6))
    static var N900: Color = Color(UIColor.rgb(0x1F2329) & UIColor.rgb(0xEBEBEB))
    static var B600: Color = Color(UIColor.rgb(0x245BDB) & UIColor.rgb(0x70A0FF))
    static var R600: Color = Color(UIColor.rgb(0xD83931) & UIColor.rgb(0xFA7873))

    static var R100: Color = Color(UIColor.rgb(0xFDE2E2) & UIColor.rgb(0x4A1D1B))
    static var G100: Color = Color(UIColor.rgb(0xD9F5D6) & UIColor.rgb(0x20471B))
    static var B100: Color = Color(UIColor.rgb(0xE1EAFF) & UIColor.rgb(0x192A4C))
    static var O100: Color = Color(UIColor.rgb(0xFEEAD2) & UIColor.rgb(0x57330A))
    static var P100: Color = Color(UIColor.rgb(0xECE2FE) & UIColor.rgb(0x361D61))
    static var W100: Color = Color(UIColor.rgb(0xD9F3FD) & UIColor.rgb(0x173742))
    static var Y100: Color = Color(UIColor.rgb(0xFAF1D1) & UIColor.rgb(0x574711))

    static var textTitle: Color { N900 }
    static var textPlaceholder: Color { N500 }
    static var textCaption: Color { N600 }
}

// MARK: - Helper

extension UIColor {

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
                    return dark.resolvedColor(with: .init(userInterfaceStyle: .dark))
                default:
                    return light.resolvedColor(with: .init(userInterfaceStyle: .light))
                }
            }
        } else {
            return light
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

    /// 格式：0xRRGGBB
    static func rgb(_ rgb: UInt32) -> UIColor {
        return color(
            CGFloat((rgb & 0xFF0000) >> 16),
            CGFloat((rgb & 0x00FF00) >> 8),
            CGFloat((rgb & 0x0000FF))
        )
    }

    /// rgba转换对应 UIColor
    static func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }
}

@available(iOS 14.0, *)
extension View {
    
    @ViewBuilder
    /// 使 Widget 支持 StandBy 模式，替换原来的 `background()`
    func widgetBackground(_ backgroundView: some View) -> some View {
        if Bundle.main.bundlePath.hasSuffix(".appex"){
            if #available(iOS 17.0, *) {
                containerBackground(for: .widget) {
                    backgroundView
                }
            } else {
                background(backgroundView)
            }
        } else {
            background(backgroundView)
        }
    }
}

/*
@available(iOS 14.0, *)
extension View {

    @available(iOSApplicationExtension 15.0, *)
    public func widgetBackground<S>(_ style: S) -> some View where S : ShapeStyle {
        if #available(iOSApplicationExtension 17, *) {
            return containerBackground(style, for: .widget)
        } else {
            return background(style)
        }
    }
}
*/
