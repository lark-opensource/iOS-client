//
//  WhiteboardShape+Color.swift
//
//
//  Created by 阮明哲 on 2022/3/25.
//

import Foundation
import UIKit

// disable-lint: magic number
private extension UIColor {
    var hexRGBA: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "0x%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
    }

    convenience init(hexRGBA: String) {
        let str: String.SubSequence
        if hexRGBA.starts(with: "0x") {
            str = hexRGBA.dropFirst(2)
        } else if hexRGBA.starts(with: "#") {
            str = hexRGBA.dropFirst(1)
        } else {
            str = hexRGBA.dropFirst(0)
        }
        let hexVal = Int(str, radix: 16) ?? 0
        let r = hexVal & 0xFF000000 >> 24
        let g = hexVal & 0x00FF0000 >> 16
        let b = hexVal & 0x0000FF00 >> 8
        let a = hexVal & 0x000000FF >> 0
        self.init(red: CGFloat(r) / 255,
                  green: CGFloat(g) / 255,
                  blue: CGFloat(b) / 255,
                  alpha: CGFloat(a) / 255)
    }
}

extension UIColor {
    var rgbaInt64: Int64 {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let uintVal = (Int64(255 * r) << 24)
            + (Int64(255 * g) << 16)
            + (Int64(255 * b) << 8)
            + Int64(255 * a)
        return uintVal
    }
    var rgbaUInt32: UInt32 {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let uintVal = (UInt32(255 * r) << 24)
            + (UInt32(255 * g) << 16)
            + (UInt32(255 * b) << 8)
            + UInt32(255 * a)
        return uintVal
    }
}

extension CGColor {
    var rgbaInt64: Int64 {
        return UIColor(cgColor: self).rgbaInt64
    }
}
