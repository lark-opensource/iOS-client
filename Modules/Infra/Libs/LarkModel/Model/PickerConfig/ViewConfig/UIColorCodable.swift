//
//  UIColorCodable.swift
//  LarkModel
//
//  Created by Yuri on 2023/5/24.
//

import UIKit

extension UIColor {
    convenience init?(hexString: String) {
        let r, g, b, a: CGFloat
        let rgbValue: CGFloat = 255

        if hexString.hasPrefix("#") {
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            let hexColor = String(hexString[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / rgbValue
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / rgbValue
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / rgbValue
                    a = CGFloat(hexNumber & 0x000000ff) / rgbValue

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }

    func toHexString() -> String {
        let rgbValue: CGFloat = 255
        let rOffset = 24
        let gOffset = 16
        let bOffset = 8
        let components = self.cgColor.components
        let r = components?[0] ?? 0
        let g = components?[1] ?? 0
        let b = (components?.count ?? 0) >= 3 ? components?[2] ?? 0 : g
        let a = (components?.count ?? 0) >= 4 ? components?[3] ?? 0 : 1

        let rgba = (Int(r * rgbValue) << rOffset)
                    + (Int(g * rgbValue) << gOffset)
                    + (Int(b * rgbValue) << bOffset)
                    + Int(a * rgbValue)
        return String(format: "#%08x", rgba)
    }
}
