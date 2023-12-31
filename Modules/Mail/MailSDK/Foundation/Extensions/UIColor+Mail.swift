////
////  UIColor+ Mail.swift
////  MailCommon
////
////  Created by weidong fu on 25/11/2017.
////
//
import Foundation
import UniverseDesignColor
import UniverseDesignTheme

extension UIColor: MailExtensionCompatible {}
let shiftRed: Int = 16
let shiftGreen: Int = 8
let shiftAlpha: Int = 24
let rbgMaxVal: Double = 255.0

extension MailExtension where BaseType == UIColor {

    class func rgb(_ rgb: String) -> UIColor {
        var hexString: String
        if rgb.hasPrefix("#") {
            let index = rgb.index(after: rgb.startIndex)
            hexString = String(rgb[index...])
        } else {
            hexString = rgb
        }
        var rgbValue: UInt32 = 0
        
        Scanner(string: hexString).scanHexInt32(&rgbValue)
        return UIColor.mail.color(
            CGFloat((rgbValue & 0xFF0000) >> shiftRed),
            CGFloat((rgbValue & 0x00FF00) >> shiftGreen),
            CGFloat((rgbValue & 0x0000FF))
        )
    }

    class func argb(_ argb: String) -> UIColor {
        var hexString: String
        if argb.hasPrefix("#") {
            let index = argb.index(after: argb.startIndex)
            hexString = String(argb[index...])
        } else {
            hexString = argb
        }
        var rgbaValue: UInt32 = 0
        Scanner(string: hexString).scanHexInt32(&rgbaValue)
        return UIColor.mail.color(
            CGFloat((rgbaValue & 0x00FF0000) >> shiftRed),
            CGFloat((rgbaValue & 0x0000FF00) >> shiftGreen),
            CGFloat((rgbaValue & 0x000000FF)),
            CGFloat((rgbaValue & 0xFF000000) >> shiftAlpha) / rbgMaxVal
        )
    }

    class func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: red / rbgMaxVal, green: green / rbgMaxVal, blue: blue / rbgMaxVal, alpha: alpha)
    }

    // UIColor -> Hex String
    var cssHexString: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let multiplier = CGFloat(255.999999)

        guard self.base.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        if alpha == 1.0 {
            return String(
                format: "#%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier)
            )
        } else {
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier),
                Int(alpha * multiplier)
            )
        }
    }
}

extension UIColor {
    var compatibleColor: UIColor {
        if #available(iOS 13.0, *),
           UDThemeManager.getSettingUserInterfaceStyle() != .unspecified
        {
            return resolvedCompatibleColor(with: UITraitCollection(userInterfaceStyle: UDThemeManager.getSettingUserInterfaceStyle()))
        } else {
            return self
        }
    }
}
