//
//  UIColor+Docs.swift
//  DocsCommon
//
//  Created by weidong fu on 25/11/2017.
//

import Foundation
import SKFoundation
import UIKit
import UniverseDesignTheme
import UniverseDesignColor
import FigmaKit

// nolint: magic_number
extension UIColor: DocsExtensionCompatible {}

public extension UIColor {
    
    /// 对于透明的颜色，给其垫一个背景色来计算最终的叠加计算颜色
    public func skOverlayColor(with background: UIColor) -> UIColor {
        return UIColor.dynamic(light: self.alwaysLight.overlayColor(with: background.alwaysLight),
                               dark: self.alwaysDark.overlayColor(with: background.alwaysDark))
    }
    
    func skOverlayColorAlwaysLight(with background: UIColor) -> UIColor {
        alwaysLight.overlayColor(with: background.alwaysLight)
    }
    
    private func overlayColor(with background: UIColor) -> UIColor {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard self.getRed(&r, green: &g, blue: &b, alpha: &a), fabs(1 - a) > CGFLOAT_EPSILON else {
            // a 不透明那就不需要计算
            return self
        }
        var bg_r: CGFloat = 0
        var bg_g: CGFloat = 0
        var bg_b: CGFloat = 0
        var bg_a: CGFloat = 0
        guard background.getRed(&bg_r, green: &bg_g, blue: &bg_b, alpha: &bg_a), fabs(bg_a - 1) < CGFLOAT_EPSILON else {
            // 只支持非透明的 background
            return self
        }
        // https://en.wikipedia.org/wiki/Alpha_compositing
        return UIColor(red: r * a + bg_r * (1 - a),
                       green: g * a + bg_g * (1 - a),
                       blue: b * a + bg_b * (1 - a),
                       alpha: 1)
    }
}


public extension DocsExtension where BaseType == UIColor {

    static var isCurrentDarkMode: Bool {
        if #available(iOS 13.0, *) {
            if UDThemeManager.getRealUserInterfaceStyle() == .dark {
                return true
            }
        }
        return false
    }

    enum AlphaInfoType {
        case auto // `.none` or `.last` based on string length
        case cgImageAlphaInfo(CGImageAlphaInfo)
    }

    class func rgb(_ rgb: String, alphaInfoType: AlphaInfoType = .auto) -> UIColor {
        var hexString: String
        if rgb.hasPrefix("#") {
            let index = rgb.index(after: rgb.startIndex)
            hexString = String(rgb[index...])
        } else {
            hexString = rgb
        }
        var rgbValue: UInt32 = 0
        Scanner(string: hexString).scanHexInt32(&rgbValue)

        var resolvedAlphaInfo: CGImageAlphaInfo = .none
        if case .cgImageAlphaInfo(let info) = alphaInfoType { // 首先使用外部指定的格式
            resolvedAlphaInfo = info
        } else { // 否则根据长度判断是 RRGGBB 还是 RRGGBBAA
            if hexString.count == 6 {
                resolvedAlphaInfo = .none
            } else if hexString.count == 8 {
                resolvedAlphaInfo = .last // 目前前端那面传过来的都是 A 在最末位，不会出现 ARGB 的情况。如果后面改了的话，可以选择显式地入参目标格式
            }
        }
        switch resolvedAlphaInfo {
        // 六位
        case .none: // RRGGBB
            return UIColor.docs.color(
                CGFloat((rgbValue & 0xFF0000) >> 16), // RR
                CGFloat((rgbValue & 0x00FF00) >> 08), // GG
                CGFloat((rgbValue & 0x0000FF))        // BB
                // AA 默认是 FF，即 alpha == 1
            )
        // 八位且需要考虑 alpha 通道
        case .last: // RRGGBBAA
            return UIColor.docs.color(
                CGFloat((rgbValue & 0xFF000000) >> 24), // RR
                CGFloat((rgbValue & 0x00FF0000) >> 16), // GG
                CGFloat((rgbValue & 0x0000FF00) >> 08), // BB
                CGFloat((rgbValue & 0x000000FF)) / 255  // AA
            )
        case .first: // AARRGGBB
            return UIColor.docs.color(
                CGFloat((rgbValue & 0xFF000000) >> 24) / 255, // AA
                CGFloat((rgbValue & 0x00FF0000) >> 16),       // RR
                CGFloat((rgbValue & 0x0000FF00) >> 08),       // GG
                CGFloat((rgbValue & 0x000000FF))              // BB
            )
        // 八位但无需考虑 alpha 通道
        case .premultipliedLast, .noneSkipLast: // RRGGBBXX
            return UIColor.docs.color(
                CGFloat((rgbValue & 0xFF000000) >> 24), // RR
                CGFloat((rgbValue & 0x00FF0000) >> 16), // GG
                CGFloat((rgbValue & 0x0000FF00) >> 08)  // BB
            )
        case .premultipliedFirst, .noneSkipFirst: // XXRRGGBB
            return UIColor.docs.color(
                CGFloat((rgbValue & 0x00FF0000) >> 16), // RR
                CGFloat((rgbValue & 0x0000FF00) >> 08), // GG
                CGFloat((rgbValue & 0x000000FF))        // BB
            )
        // 不可能的情况
        case .alphaOnly:
            assertionFailure("兄弟醒一醒，都是 rgb 字符串了，怎么可能只包含 alpha 通道的信息？")
            return .clear
        }
    }

    private class func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }

    /// 判断给定颜色是否属于深色
    /// - Parameters:
    ///   - rgb: 目标颜色 (16进制) || (r, g, b)
    ///   - threshold: 对比度 (minimal recommended contrast ratio is 4.5 or 3)
    ///   https://stackoverflow.com/questions/9733288/how-to-programmatically-calculate-the-contrast-ratio-between-two-colors
    /// - Returns: 是否属于深色
    class func isColorDark(_ rgb: String, threshold: CGFloat = 3) -> Bool {
        var hexString: String
        if rgb.hasPrefix("#") {
            let index = rgb.index(after: rgb.startIndex)
            hexString = String(rgb[index...])
        } else {
            hexString = rgb
        }
        var rgbValue: UInt32 = 0
        Scanner(string: hexString).scanHexInt32(&rgbValue)
        let r: CGFloat = CGFloat((rgbValue & 0xFF0000) >> 16)
        let g: CGFloat = CGFloat((rgbValue & 0x00FF00) >> 8)
        let b: CGFloat = CGFloat((rgbValue & 0x0000FF))
        return UIColor.docs.isColorDark(r: r, g: g, b: b, threshold: threshold)
    }

    class func isColorDark(r: CGFloat, g: CGFloat, b: CGFloat, threshold: CGFloat = 3) -> Bool {
        let contrastRgb: [CGFloat] = [255.0, 255.0, 255.0]
        let targetRgb: [CGFloat] = [r, g, b]
        let contrastLuminanace = luminance(rgb: contrastRgb)
        let targetLuminanace = luminance(rgb: targetRgb)
        let brightest = max(contrastLuminanace, targetLuminanace)
        let darkest = min(contrastLuminanace, targetLuminanace)
        let contrast = (brightest + 0.05) / (darkest + 0.05)
        // 颜色和白色的对比度越大说明颜色越深
        return (contrast > threshold)
    }

    private class func luminance(rgb: [CGFloat]) -> CGFloat {
        let curRGB = rgb.map { (value) -> CGFloat in
            let curValue = value / 255
            return curValue <= 0.03928 ? curValue / 12.92 : pow((curValue + 0.055) / 1.055, 2.4)
        }
        return curRGB[0] * 0.2126 + curRGB[1] * 0.7152 + curRGB[2] * 0.0722
    }

    /// 对特殊的黑白颜色进行反色，用于显示在输入框上
    @available(iOS 13.0, *)
    static func convertToShowColor(colorString: String) -> UIColor? {
        guard let average = Self.monochromeScale(for: colorString) else { return nil }
        /// 黑色 RGB 低于 115 做反色；白色 RGB 高于 188 做反色，自定义带色彩的黑白都归于彩色不做处理
        let currentTheme = UDThemeManager.getRealUserInterfaceStyle()
        if currentTheme == .light || currentTheme == .unspecified, average > 188 {
            return UIColor.ud.staticBlack
        } else if currentTheme == .dark, average < 115 {
            return UIColor.ud.primaryOnPrimaryFill
        }

        return nil
    }

    /// This function only applies to monochrome colors. Use `UIColor.docs.isColorDark` for a wider range.
    /// - Parameter string: The color's rgb string representation.
    /// - Returns: Whether the color is dark. If the color string is invalid, `nil` is returned.
    static func shouldBorderMonochromeColor(_ colorString: String) -> Bool? {
        guard let average = Self.monochromeScale(for: colorString) else { return nil }
        if #available(iOS 13.0, *) {
            let currentTheme = UDThemeManager.getRealUserInterfaceStyle()
            return (average > 188 && currentTheme != .dark) // white color in light mode
                || (average < 115 && currentTheme == .dark) // black color in dark mode
        } else {
            return average > 188
        }
    }

    private static func monochromeScale(for colorString: String) -> CGFloat? {
        let color = UIColor.docs.rgb(colorString)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        red *= 255.0
        green *= 255.0
        blue *= 255.0
        let colors = [red, green, blue]
        let max = colors.max() ?? 0
        let min = colors.min() ?? 0
        // 只判断单色
        guard max - min < 15 else {
            return nil
        }
        return (red + green + blue) / 3.0
    }
    
    // 渐变色
    static func gradientColor(begin: UIColor, end: UIColor, percent: Float) -> UIColor {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard begin.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return begin
        }
        var e_r: CGFloat = 0
        var e_g: CGFloat = 0
        var e_b: CGFloat = 0
        var e_a: CGFloat = 0
        guard end.getRed(&e_r, green: &e_g, blue: &e_b, alpha: &e_a) else {
            return begin
        }
        return UIColor(red: r + CGFloat(percent) * (e_r - r),
                       green: g + CGFloat(percent) * (e_g - g),
                       blue: b + CGFloat(percent) * (e_b - b),
                       alpha: a + CGFloat(percent) * (e_a - a)
        )
    }
    
    static func gradientColor(direction: GradientDirection,
                              size: CGSize,
                              colors: [UIColor],
                              type: GradientType = .linear) -> UIColor? {
        return UIColor.fromGradientWithType(type, direction: direction, frame:  CGRect(origin: .zero, size: size), colors: colors)
    }
}
