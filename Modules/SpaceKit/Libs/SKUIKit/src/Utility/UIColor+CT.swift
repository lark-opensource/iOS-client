//
//  UIColor+CT.swift
//  Bitable
//
//  Created by vvlong on 2018/9/16.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import UIKit
import SKFoundation

extension UIColor: CTExtensionCompatible {}

public extension CTExtension where BaseType == UIColor {
    
    static let btBlue = UIColor.ud.colorfulBlue
    
//    class func rgb(_ rgb: String) -> UIColor {
//        var hexString: String
//        if rgb.hasPrefix("#") {
//            let index = rgb.index(after: rgb.startIndex)
//            hexString = String(rgb[index...])
//        } else {
//            hexString = rgb
//        }
//        var rgbValue: UInt32 = 0
//        Scanner(string: hexString).scanHexInt32(&rgbValue)
//        return UIColor.ct.color(
//            CGFloat((rgbValue & 0xFF0000) >> 16),
//            CGFloat((rgbValue & 0x00FF00) >> 8),
//            CGFloat((rgbValue & 0x0000FF))
//        )
//    }
//
//    class func argb(_ argb: String) -> UIColor {
//        var hexString: String
//        if argb.hasPrefix("#") {
//            let index = argb.index(after: argb.startIndex)
//            hexString = String(argb[index...])
//        } else {
//            hexString = argb
//        }
//        var rgbaValue: UInt32 = 0
//        Scanner(string: hexString).scanHexInt32(&rgbaValue)
//        return UIColor.ct.color(
//            CGFloat((rgbaValue & 0x00FF0000) >> 16),
//            CGFloat((rgbaValue & 0x0000FF00) >> 8),
//            CGFloat((rgbaValue & 0x000000FF)),
//            CGFloat((rgbaValue & 0xFF000000) >> 24) / 255.0
//        )
//    }
    
//    class func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> UIColor {
//        return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
//    }
}
