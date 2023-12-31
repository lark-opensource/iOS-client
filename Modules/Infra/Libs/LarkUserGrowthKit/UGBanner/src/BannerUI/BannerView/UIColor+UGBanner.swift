//
//  UIColor+UGBanner.swift
//  UGBanner
//
//  Created by mochangxing on 2021/3/17.
//

import UIKit
import Foundation

extension UIColor {
    private class func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }

    // 将(A)RGB string前缀“#”（如果有）去掉，并转化成为UInt32
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

    /// 格式：RRGGBBAA
    public class func rgba(_ rgbString: String) -> UIColor {
        return rgba(formartRGBString(rgbString))
    }

    /// 格式：0xRRGGBBAA
    public class func rgba(_ rgba: UInt32) -> UIColor {
        return color(
            CGFloat((rgba & 0xFF000000) >> 24),
            CGFloat((rgba & 0x00FF0000) >> 16),
            CGFloat((rgba & 0x0000FF00) >> 8),
            CGFloat((rgba & 0x000000FF)) / 255.0
        )
    }
}
