//
//  UDColor+Extension.swift
//  UniverseDesignColor
//
//  Created by 姚启灏 on 2020/11/12.
//

import UIKit
import Foundation
import UniverseDesignTheme

// swiftlint:enable identifier_name
extension UIColor: UDComponentsExtensible {}
extension UIImage: UDComponentsExtensible {}
extension UIImageView: UDComponentsExtensible {}

extension UDComponentsExtension where BaseType == UIColor {
    typealias RGBA = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)

    public class var commonBackgroundColor: UIColor {
        return UIColor.ud.N100
    }

    // 默认列表分割线颜色
    public static var commonTableSeparatorColor = UIColor.ud.N300

    /// rgba转换对应 UIColor
    public class func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }

    public func lighter(by percentage: CGFloat = 30.0) -> UIColor {
        return self.adjust(by: abs(percentage))
    }

    public func darker(by percentage: CGFloat = 30.0) -> UIColor {
        return self.adjust(by: -1 * abs(percentage))
    }

    public func adjust(by percentage: CGFloat = 30.0) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0

        if self.base.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(
                red: min(red + percentage / 100, 1.0),
                green: min(green + percentage / 100, 1.0),
                blue: min(blue + percentage / 100, 1.0),
                alpha: alpha
            )
        }

        return self.base
    }

    /// 将(A)RGB string前缀“#”（如果有）去掉，并转化成为UInt32
    private class func formartRGBString(_ string: String ) -> UInt32 {
        let hexString: String
        if string.hasPrefix("#") {
            let index = string.index(after: string.startIndex)
            hexString = String(string[index...])
        } else {
            hexString = string
        }

        var uint32Value: UInt32 = 0
        Scanner(string: hexString).scanHexInt32(&uint32Value)
        return uint32Value
    }

    /// 格式：0xAARRGGBB
    public class func rgba(_ rgba: UInt32) -> UIColor {
        return color(
            CGFloat((rgba & 0x00FF0000) >> 16),
            CGFloat((rgba & 0x0000FF00) >> 8),
            CGFloat((rgba & 0x000000FF)),
            CGFloat((rgba & 0xFF000000) >> 24) / 255.0
        )
    }

    /// 格式：AARRGGBB
    public class func rgba(_ rgbString: String) -> UIColor {
        return rgba(formartRGBString(rgbString))
    }

    /// 格式：0xRRGGBB
    public class func rgb(_ rgb: UInt32) -> UIColor {
        return color(
            CGFloat((rgb & 0xFF0000) >> 16),
            CGFloat((rgb & 0x00FF00) >> 8),
            CGFloat((rgb & 0x0000FF))
        )
    }

    /// 格式：RRGGBB
    public class func rgb(_ rgbString: String) -> UIColor {
        return rgb(formartRGBString(rgbString))
    }

    /// 动态计算叠加颜色
    public func withOver(_ color: UIColor) -> UIColor {
        if #available(iOS 13, *) {
            let lightColor = base.alwaysLight.ud.withOverNonDynamic(color.alwaysLight)
            let darkColor = base.alwaysDark.ud.withOverNonDynamic(color.alwaysDark)
            return lightColor & darkColor
        } else {
            return withOverNonDynamic(color)
        }
    }

    private func withOverNonDynamic(_ color: UIColor) -> UIColor {
        var rgba1: RGBA = (0, 0, 0, 0)
        var rgba2: RGBA = (0, 0, 0, 0)

        // 读取原有颜色
        guard base.getRed(&rgba1.red, green: &rgba1.green, blue: &rgba1.blue, alpha: &rgba1.alpha),
            color.getRed(&rgba2.red, green: &rgba2.green, blue: &rgba2.blue, alpha: &rgba2.alpha) else {
            return UIColor.white
        }
        // 按照公式计算新的透明度，两个Color各占比例
        let newAlpha = rgba1.alpha + rgba2.alpha - rgba1.alpha * rgba2.alpha
        let color1Rate = rgba1.alpha * (1.0 - rgba2.alpha)
        let color2Rate = rgba2.alpha

        // 新的颜色值计算闭包
        let calculateBlend: (_ colorValue1: CGFloat,
            _ colorValue2: CGFloat) -> CGFloat = { ($0 * color1Rate + $1 * color2Rate) / newAlpha }

        return UIColor(red: calculateBlend(rgba1.red, rgba2.red),
                       green: calculateBlend(rgba1.green, rgba2.green),
                       blue: calculateBlend(rgba1.blue, rgba2.blue),
                       alpha: newAlpha)
    }

    /// Create a image with given color.
    public class func image(with color: UIColor, size: CGSize, scale: CGFloat) -> UIImage? {
        if #available(iOS 13, *) {
            if let lightImg = colorImage(with: color.alwaysLight, size: size, scale: scale),
               let darkImg = colorImage(with: color.alwaysDark, size: size, scale: scale) {
                return UIImage.dynamic(light: lightImg, dark: darkImg)
            } else {
                return nil
            }
        } else {
            return colorImage(with: color, size: size, scale: scale)
        }
    }

    class func colorImage(with color: UIColor, size: CGSize, scale: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        color.setFill()

        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)

        let rect = CGRect(origin: .zero, size: size)
        context?.fill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

    /// Create a color by token.
    /// - Parameter token: token from common ud token list.
    public class func named(_ token: String) -> UIColor? {
        return UDColor.getValueByKey(UDColor.Name(token))
    }
}

extension UDComponentsExtension where BaseType == UIColor {
    private static var cssColorMap: [String: UIColor] = [
        "black": .black,
        "darkgray": .darkGray,
        "gray": .gray,
        "lightgray": .lightGray,
        "white": .white,
        "red": .red,
        "green": .green,
        "blue": .blue,
        "yellow": .yellow,
        "cyan": .cyan,
        "magenta": .magenta,
        "aqua": rgba(0xFF00FFFF),
        "fuchsia": rgba(0xFFFF00FF),
        "darkgrey": .darkGray,
        "grey": .gray,
        "lightgrey": .lightGray,
        "lime": rgba(0xFF00FF00),
        "maroon": rgba(0xFF800000),
        "navy": rgba(0xFF000080),
        "olive": rgba(0xFF808000),
        "purple": rgba(0xFF800080),
        "silver": rgba(0xFFC0C0C0),
        "teal": rgba(0xFF008080)
        ]

    /// 根据 CSS 颜色名返回颜色(不完整)
    public class func css(_ cssString: String) -> UIColor {
        return cssColorMap[cssString.lowercased()] ?? rgb(cssString.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

extension UIColor {
    /// 十六进制色值，如有alpha通道将丢失
    public var hex6: String? {
        return UIColor.ud.hex(self, withAlphaPrefix: false)
    }

    /// 十六进制色值，保留alpha值
    public var hex8: String? {
        return UIColor.ud.hex(self, withAlphaPrefix: true)
    }
}

extension UDComponentsExtension where BaseType == UIColor {
    /// 根据当前颜色返回对应hex，当前支持RGB、单色，withPrefix表示带有#前缀
    public class func hex(_ color: UIColor, withAlphaPrefix: Bool = true, withPrefix: Bool = true) -> String? {
        let cgColor = color.cgColor
        guard let model = cgColor.colorSpace?.model,
            let comp = cgColor.components else { return nil }
        var colors: (CGFloat, CGFloat, CGFloat, CGFloat)

        switch model {
        case .rgb:
            colors = (comp[0], comp[1], comp[2], comp[3])
        case .monochrome:
            colors = (comp[0], comp[0], comp[0], comp[1])
        default:
            return nil
        }
        colors = (colors.0 * 255.0, colors.1 * 255.0, colors.2 * 255.0, colors.3 * 255.0)
        let prefix = withPrefix ? "#" : ""
        let result: String
        if withAlphaPrefix {
            result = String(format: "\(prefix)%02lX%02lX%02lX%02lX", Int(colors.3), Int(colors.0), Int(colors.1), Int(colors.2))
        } else {
            result = String(format: "\(prefix)%02lX%02lX%02lX", Int(colors.0), Int(colors.1), Int(colors.2))
        }
        return result
    }
}

extension UIImage {

    /// Colorize an image with dynamic color.
    @available(*, deprecated, renamed: "ud.colorize(color:)")
    public func withColor(_ newColor: UIColor) -> UIImage? {
        return withDynamicColor(newColor)
    }

    /// Colorize an image with dynamic color.
    @available(*, deprecated, renamed: "ud.colorize(color:)")
    public func withDynamicColor(_ newColor: UIColor) -> UIImage? {
        if #available(iOS 13.0, *) {
            if let lightImg = colorImage(newColor.alwaysLight),
               let darkImg = colorImage(newColor.alwaysDark) {
                return UIImage.dynamic(light: lightImg, dark: darkImg)
            } else {
                return nil
            }
        } else {
            return colorImage(newColor)
        }
    }

    public func colorImage(_ newColor: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        newColor.setFill()

        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)

        let rect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
        context?.clip(to: rect, mask: self.cgImage!)
        context?.fill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

extension UDComponentsExtension where BaseType == UIImage {

    /// Colorize an image with **non-dynamic** color.
    private func _colorize(color: UIColor, resizingMode: UIImage.ResizingMode = .stretch) -> UIImage {
        let img = self.base
        let rect = CGRect(origin: CGPoint.zero, size: img.size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, img.scale)
        defer { UIGraphicsEndImageContext() }
        let context = UIGraphicsGetCurrentContext()
        img.draw(in: rect)
        context?.setFillColor(color.cgColor)
        context?.setBlendMode(.sourceAtop)
        context?.fill(rect)
        let result = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        return result.resizableImage(withCapInsets: img.capInsets, resizingMode: resizingMode)
    }

    /// Colorize an image with specified color.
    /// - Parameters:
    ///   - color: the color to colorize the image (dynamic color supported).
    ///   - resizingMode: resizing modes for an image.
    /// - Returns: The colorized image.
    public func colorize(color: UIColor, resizingMode: UIImage.ResizingMode = .stretch) -> UIImage {
        if #available(iOS 13.0, *) {
            guard color.isDynamic else {
                return _colorize(color: color, resizingMode: resizingMode)
            }
            return UIImage.dynamic(
                light: _colorize(color: color.alwaysLight, resizingMode: resizingMode),
                dark: _colorize(color: color.alwaysDark, resizingMode: resizingMode)
            )
        } else {
            return _colorize(color: color, resizingMode: resizingMode)
        }
    }

    /// Make a image with pure color.
    private class func _fromPureColor(_ color: UIColor, opaque: Bool = true) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContextWithOptions(rect.size, opaque, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img ?? UIImage()
    }

    /// Make a image with pure color.
    public class func fromPureColor(_ color: UIColor, opaque: Bool = true) -> UIImage {
        let image = _fromPureColor(.white)
        return image.ud.withTintColor(color)
    }

    /// Make a image with gradient colors.
    private class func _fromGradientColors(_ colors: [UIColor],
                                           startPoint: CGPoint,
                                           endPoint: CGPoint,
                                           size: CGSize) -> UIImage {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: size)
        gradientLayer.colors = colors.map({ (color) -> CGColor in
            return color.cgColor
        })
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
        gradientLayer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }

    /// Make a image with gradient colors.
    public class func fromGradientColors(_ colors: [UIColor],
                                         startPoint: CGPoint,
                                         endPoint: CGPoint,
                                         size: CGSize) -> UIImage {
        if #available(iOS 13.0, *) {
            let lightImage = _fromGradientColors(
                colors.map { $0.alwaysLight },
                startPoint: startPoint,
                endPoint: endPoint,
                size: size
            )
            let darkImage = _fromGradientColors(
                colors.map { $0.alwaysDark },
                startPoint: startPoint,
                endPoint: endPoint,
                size: size
            )
            return UIImage.dynamic(light: lightImage, dark: darkImage)
        } else {
            return _fromGradientColors(
                colors,
                startPoint: startPoint,
                endPoint: endPoint,
                size: size
            )
        }
    }
}

extension UDComponentsExtension where BaseType: UIImageView {
    /// 根据TintColor以及renderingMode转换UIImage
    /// - Parameters:
    ///   - color: TintColor
    ///   - renderingMode: renderingMode
    ///   - backgroundColor: UIImageView backgroundColor
    public func withTintColor(_ color: UIColor,
                              renderingMode: UIImage.RenderingMode = .automatic,
                              backgroundColor: UIColor? = nil) {
        self.base.image = self.base.image?.ud.withTintColor(color,
                                                            renderingMode: renderingMode)
        self.base.backgroundColor = backgroundColor
    }
}

extension UDComponentsExtension where BaseType: UIImage {
    /// 根据TintColor以及renderingMode转换UIImage
    /// - Parameters:
    ///   - color: TintColor
    ///   - renderingMode: renderingMode
    public func withTintColor(_ color: UIColor,
                              renderingMode: UIImage.RenderingMode = .automatic) -> UIImage {
        if #available(iOS 13.0, *) {
            return self.base.withTintColor(color, renderingMode: renderingMode)
        } else {
            /// 解决iOS12不能使用withTintColor函数
            UIGraphicsBeginImageContextWithOptions(self.base.size, false, self.base.scale)
            color.setFill()

            let context = UIGraphicsGetCurrentContext()
            context?.translateBy(x: 0, y: self.base.size.height)
            context?.scaleBy(x: 1.0, y: -1.0)
            context?.setBlendMode(CGBlendMode.normal)

            let rect = CGRect(origin: .zero, size: CGSize(width: self.base.size.width, height: self.base.size.height))
            guard let cgImage = self.base.cgImage else {
                return UIImage()
            }
            context?.clip(to: rect, mask: self.base.cgImage!)
            context?.fill(rect)

            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return newImage?.withRenderingMode(renderingMode) ?? UIImage()
        }
    }

    /// 重设图片大小
    public func resized(to newSize: CGSize) -> UIImage {
        if base.size == newSize { return base }
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        base.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if resizedImage == nil {
            let msg: String = "UIImage resized resizedImage nil. newSize: \(newSize)"
            UDColor.tracker?.logger(component: .UDColor, loggerType: .error, msg: msg)
        }
        return resizedImage ?? UIImage()
    }

    /// 等比率缩放
    public func scaled(by ratio: CGFloat) -> UIImage {
        let reSize = CGSize(
            width: base.size.width * ratio,
            height: base.size.height * ratio
        )
        return resized(to: reSize)
    }
}
