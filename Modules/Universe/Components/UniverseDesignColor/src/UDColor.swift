//
//  UDColor.swift
//  Color
//
//  Created by 姚启灏 on 2020/8/3.
//

import UIKit
import Foundation
import UniverseDesignTheme

public protocol UDBizColor {
    func getValueByToken(_ token: String) -> UIColor?
}

/// UniverseDesign Theme
public struct UDColor: UDResource {

    public static var tracker: UDTrackerDependency?

    public struct Name: UDKey, ExpressibleByStringLiteral {

        public let key: String

        public init(_ key: String) {
            self.key = key
        }

        public init(stringLiteral value: String) {
            self = Name(value)
        }
    }

    /// Current Color Theme
    public static var current: Self = Self()

    public static var bizColors: SafeArray<UDBizColor> = SafeArray()

    public var store: SafeDictionary<UDColor.Name, UIColor> = SafeDictionary()

    /// Color Theme Init
    /// - Parameter colorMap: Color Resource
    public init(store: [UDColor.Name: UIColor] = [:]) {
        self.store = UniverseDesignTheme.SafeDictionary(store)
    }

    public static func registerUDBizColor(_ color: UDBizColor) {
        Self.bizColors.append(color)
    }

    public static func registerToken() {
        let tokens = UDColor.getToken()
        UDColor.current.store.safeWrite { data in
            for (key, value) in tokens {
                data[key] = value
            }
        }
    }

    public static func registerBizTokens(_ tokens: [UDColor.Name: UIColor]) {
        UDColor.current.store.safeWrite { data in
            for (key, value) in tokens {
                data[key] = value
            }
        }
    }

    public static func registerBizTokenBy(name: UDColor.Name, default color: UIColor) -> UIColor {

        guard let currentColor = UDColor.getValueByKey(name) else {
            UDColor.current.store.safeWrite { data in
                data[name] = color
            }
            return color
        }

        return currentColor
    }

    /// Get Value By Key
    /// - Parameter key:
    public func getValueByBizToken(token: String) -> UIColor? {
        // UD优先
        if self.store.isEmpty {
            UDColor.registerToken()
        }
        var color = self.getValueByKey(UDColor.Name(token))
        if color == nil {
            // for each cannot abort loop, need for..in
            let bizColors = Self.bizColors.getImmutableCopy()
            for biz in bizColors {
                if let bizColor = biz.getValueByToken(token) {
                    // 找不到则找Biz Color，找到为止
                    color = bizColor
                    break
                }
            }
        }
        return color
    }

    public static func getValueByBizToken(token: String) -> UIColor? {
        return UDColor.current.getValueByBizToken(token: token)
    }
}

extension UDColor {
    /// rgba转换对应 UIColor
    public static func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }

    /// 将(A)RGB string前缀“#”（如果有）去掉，并转化成为UInt32
    private static func formartRGBString(_ string: String ) -> UInt32 {
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
    public static func rgba(_ rgba: UInt32) -> UIColor {
        return color(
            CGFloat((rgba & 0x00FF0000) >> 16),
            CGFloat((rgba & 0x0000FF00) >> 8),
            CGFloat((rgba & 0x000000FF)),
            CGFloat((rgba & 0xFF000000) >> 24) / 255.0
        )
    }

    /// 格式：AARRGGBB
    public static func rgba(_ rgbString: String) -> UIColor {
        return rgba(formartRGBString(rgbString))
    }

    /// 格式：0xRRGGBB
    public static func rgb(_ rgb: UInt32) -> UIColor {
        return color(
            CGFloat((rgb & 0xFF0000) >> 16),
            CGFloat((rgb & 0x00FF00) >> 8),
            CGFloat((rgb & 0x0000FF))
        )
    }

    /// 格式：RRGGBB
    public static func rgb(_ rgbString: String) -> UIColor {
        return rgb(formartRGBString(rgbString))
    }
}
