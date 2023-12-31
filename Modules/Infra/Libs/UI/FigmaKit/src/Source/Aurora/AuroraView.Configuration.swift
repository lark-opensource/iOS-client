//
//  AuroraView.Configuration.swift
//  FigmaKit
//
//  Created by Hayden on 14/7/2023.
//

import Foundation

public struct AuroraViewConfiguration {

    /// ‘main’ 色块的配置
    public var mainBlob: BlobStyle
    /// ‘sub’ 色块的配置
    public var subBlob: BlobStyle
    /// ‘reflection’ 色块的配置
    public var reflectionBlob: BlobStyle

    public init(mainBlob: BlobStyle,
                subBlob: BlobStyle,
                reflectionBlob: BlobStyle) {
        self.mainBlob = mainBlob
        self.subBlob = subBlob
        self.reflectionBlob = reflectionBlob
    }
    
    /// 默认蓝色极光参数
    public static var `default`: AuroraViewConfiguration {
        return AuroraViewConfiguration(
            mainBlob: BlobStyle(
                color: .dynamic(light: "#1456F0", lightAlpha: 0.2, dark: "#1099CC", darkAlpha: 0.2),
                position: .init(absoluteLeft: -80, top: -59, width: 150, height: 150),
                opacity: 1.0,
                blurRadius: 100),
            subBlob: BlobStyle(
                color: .dynamic(light: "#336DF4", lightAlpha: 0.2, dark: "#1099CC", darkAlpha: 0.2),
                position: .init(absoluteLeft: -17, top: -126, width: 228, height: 220),
                opacity: 1.0,
                blurRadius: 80),
            reflectionBlob: BlobStyle(
                color: .dynamic(light: "#2DBEAB", lightAlpha: 0.1, dark: "#A575FA", darkAlpha: 0.15),
                position: .init(absoluteLeft: 150, top: -65, width: 145, height: 140),
                opacity: 1.0,
                blurRadius: 80)
        )
    }

    public var colors: (UIColor, UIColor, UIColor) {
        (mainBlob.color, subBlob.color, reflectionBlob.color)
    }

    public struct BlobStyle {
        /// 色块的颜色，要考虑 DarkMode，尽量使用动态颜色
        public var color: UIColor
        /// 色块在画布中的相对位置，对应标准 Figma 设计稿中边长 375 的画布
        public var position: Position
        /// 色块的透明度，对应 Figma 设计稿中 Layer - Pass through 数值，取值转换为 [0 - 1.0]
        public var opacity: CGFloat
        /// 色块的模糊半径，对应 Figma 设计稿中 Effects - Layer blur 数值
        public var blurRadius: CGFloat

        /// 一个色块的样式（在极光设计中，色块有三个：main、sub、reflection）
        /// - Parameters:
        ///   - color: 色块的颜色，要考虑 DarkMode，尽量使用动态颜色
        ///   - position: 色块在画布中的相对位置，数值需要除以 Figma 极光视图的宽度，如 `145 / 375.0`
        ///   - opacity: 色块的透明度，对应 Figma 设计稿中 Layer - Pass through 数值，取值转换为 [0, 1.0]
        ///   - blurRadius: 色块的模糊半径，对应 Figma 设计稿中 Effects - Layer blur 数值，默认为 80
        public init(color: UIColor, position: Position, opacity: CGFloat, blurRadius: CGFloat = 80) {
            self.color = color
            self.position = position
            self.opacity = opacity
            self.blurRadius = blurRadius
        }

        /// 一个色块的样式（在极光设计中，色块有三个：main、sub、reflection）
        /// - Parameters:
        ///   - color: 色块的颜色，要考虑 DarkMode，尽量使用动态颜色
        ///   - frame: 色块在画布中的相对位置，对应标准 Figma 设计稿中边长 375 的画布
        ///   - opacity: 色块的透明度，对应 Figma 设计稿中 Layer - Pass through 数值，取值转换为 [0, 1.0]
        ///   - blurRadius: 色块的模糊半径，对应 Figma 设计稿中 Effects - Layer blur 数值，默认为 80
        @available(*, deprecated, message:"'frame' does not describe blob position accurately, please use 'position' instead.")
        public init(color: UIColor, frame: CGRect, opacity: CGFloat, blurRadius: CGFloat = 80) {
            self.color = color
            self.opacity = opacity
            self.blurRadius = blurRadius
            self.position = Position(absoluteLeft: frame.minX,
                                     top: frame.minY,
                                     width: frame.width,
                                     height: frame.height,
                                     boundWidth: 375)
        }

        public struct Position {
            public var top: CGFloat
            public var left: CGFloat
            public var width: CGFloat
            public var height: CGFloat
            
            /// 使用 Blob 在 Figma 中的相对位置描述，需要用 Figma 中的数值除以画布宽度
            public init(top: CGFloat, left: CGFloat, width: CGFloat, height: CGFloat) {
                self.top = top
                self.left = left
                self.width = width
                self.height = height
            }
            
            /// 使用 Blob 在 Figma 画布中的绝对位置描述，默认画布宽度为 375
            /// - Parameters:
            ///   - boundWidth: Figma 中 AuroraView 所在画布的宽度，用于计算 Blob 相对位置
            public init(absoluteLeft left: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat, boundWidth: CGFloat = 375) {
                self.top = top / boundWidth
                self.left = left / boundWidth
                self.width = width / boundWidth
                self.height = height / boundWidth
            }
        }

        /* 暂不开放。后期考虑支持 Blob 层级自定义
        public struct Level: Hashable, RawRepresentable {

            public var rawValue: CGFloat

            public init(rawValue: CGFloat) {
                self.rawValue = rawValue
            }
            
            public static let main: Level = .init(rawValue: 500)
            public static let sub: Level = .init(rawValue: 0)
            public static let reflection: Level = .init(rawValue: 1000)
        }
         */
    }
}

fileprivate extension UIColor {

    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        var hexFormatted: String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }
        assert(hexFormatted.count == 6, "无效的颜色代码")
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    func toHexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb: Int = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255) << 0
        return String(format: "#%06x", rgb)
    }

    /// define dynamic color with both light and dark mode.
    /// - Parameters:
    ///   - light: The color to use in light mode.
    ///   - dark: The color to use in dark mode.
    /// - Returns: A dynamic color that uses both given colors respectively for the given user interface style.
    static func dynamic(light: String, lightAlpha: CGFloat = 1.0, 
                        dark: String, darkAlpha: CGFloat = 1.0) -> UIColor {
        guard #available(iOS 13.0, *) else {
            return UIColor(hexString: light, alpha: lightAlpha)
        }
        return UIColor(dynamicProvider: { trait -> UIColor in
            switch trait.userInterfaceStyle {
            case .dark:
                return UIColor(hexString: dark, alpha: darkAlpha)
            default:
                return UIColor(hexString: light, alpha: lightAlpha)
            }
        })
    }
}
