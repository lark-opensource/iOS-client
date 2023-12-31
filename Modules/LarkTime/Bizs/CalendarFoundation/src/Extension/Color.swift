//
//  Color.swift
//  Calendar
//
//  Created by linlin on 2017/12/21.
//  Copyright © 2017年 EE. All rights reserved.
//

import UIKit

public func argb(argb: Int64) -> UIColor {
    return color(
        CGFloat((argb & 0x00FF0000) >> 16),
        CGFloat((argb & 0x0000FF00) >> 8),
        CGFloat((argb & 0x000000FF)),
        CGFloat((argb & 0xFF000000) >> 24) / 255.0
    )
}

public func rgb(rgb: Int32, alpha: CGFloat) -> UIColor {
    return color(
        CGFloat((rgb & 0x00FF0000) >> 16),
        CGFloat((rgb & 0x0000FF00) >> 8),
        CGFloat((rgb & 0x000000FF)),
        alpha
    )
}

public func UIColorRGB(
    _ red: CGFloat,
    _ green: CGFloat,
    _ blue: CGFloat) -> UIColor {
    return UIColorRGBA(red, green, blue, 1.0)
}

public func color(
    _ red: CGFloat,
    _ green: CGFloat,
    _ blue: CGFloat,
    _ alpha: CGFloat = 1) -> UIColor {
    return UIColorRGBA(red, green, blue, alpha)
}

public func UIColorRGBA(
    _ red: CGFloat,
    _ green: CGFloat,
    _ blue: CGFloat,
    _ alpha: CGFloat = 1) -> UIColor {
    return UIColor(
        red: red / 255.0,
        green: green / 255.0,
        blue: blue / 255.0,
        alpha: alpha)
}

public func colorToRGB(color: UIColor) -> Int32 {
    typealias RGBComponents = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
    var c: RGBComponents = (0, 0, 0, 0)

    if color.getRed(&c.red, green: &c.green, blue: &c.blue, alpha: &c.alpha) {
        let a = Int32(c.alpha * 255.0) << 24
        let r = Int32(c.red * 255.0) << 16
        let g = Int32(c.green * 255.0) << 8
        let b = Int32(c.blue * 255.0)
        return Int32(a | r | g | b)
    } else {
        return -1
    }
}

@available(*, deprecated, message: "Do not use this function")
public func UIColorRGBAToRGB(rgbBackground: UIColor, rgbaColor: UIColor) -> UIColor {
//    return rgbaColor
    typealias RGBComponents = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
    var rgba: RGBComponents = (0, 0, 0, 0)
    var rgb: RGBComponents = (0, 0, 0, 0)

    if !rgbaColor.getRed(&rgba.red, green: &rgba.green, blue: &rgba.blue, alpha: &rgba.alpha) {
        return UIColor.white
    }
    if !rgbBackground.getRed(&rgb.red, green: &rgb.green, blue: &rgb.blue, alpha: &rgb.alpha) {
        return UIColor.white
    }
    let alpha = rgba.alpha
    return UIColor(
        red: (1 - alpha) * rgb.red + alpha * rgba.red,
        green: (1 - alpha) * rgb.green + alpha * rgba.green,
        blue: (1 - alpha) * rgb.blue + alpha * rgba.blue,
        alpha: 1)
}
