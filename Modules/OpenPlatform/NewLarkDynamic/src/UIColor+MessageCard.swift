//
//  UIColor+MessageCard.swift
//  NewLarkDynamic
//
//  Created by lilun.ios on 2021/6/15.
//

import Foundation

extension UIColor {
    func currentColor() -> UIColor {
        if #available(iOS 13.0, *) {
            return self.resolvedColor(with: UITraitCollection.current)
        } else {
            // Fallback on earlier versions
            return self
        }
    }
    func withContext(context: LDContext?) -> UIColor {
        guard let ctx = context else {
            return self
        }
        if ctx.cardVersion >= 2 {
            return self
        }
        return self.alwaysLight
    }
    convenience init?(hexaRGBA: String) {
        var chars = Array(hexaRGBA.hasPrefix("#") ? hexaRGBA.dropFirst() : hexaRGBA[...])
        switch chars.count {
        case 3:
            chars = chars.flatMap { [$0, $0] };
            fallthrough
        case 6:
            chars.append(contentsOf: ["F","F"])
        case 8: break
        default:
            return nil
        }
        self.init(red: .init(strtoul(String(chars[0...1]), nil, 16)) / 255.0,
                  green: .init(strtoul(String(chars[2...3]), nil, 16)) / 255.0,
                  blue: .init(strtoul(String(chars[4...5]), nil, 16)) / 255.0,
                  alpha: .init(strtoul(String(chars[6...7]), nil, 16)) / 255.0)
    }
    convenience init?(hexaARGB: String) {
        var chars = Array(hexaARGB.hasPrefix("#") ? hexaARGB.dropFirst() : hexaARGB[...])
        switch chars.count {
        case 3:
            chars = chars.flatMap { [$0, $0] };
            fallthrough
        case 6:
            chars.insert(contentsOf: ["F","F"], at: 0)
        case 8: break
        default:
            return nil
        }
        self.init(red: .init(strtoul(String(chars[2...3]), nil, 16)) / 255.0,
                  green: .init(strtoul(String(chars[4...5]), nil, 16)) / 255.0,
                  blue: .init(strtoul(String(chars[6...7]), nil, 16)) / 255.0,
                  alpha: .init(strtoul(String(chars[0...1]), nil, 16)) / 255.0)
    }
    static func hexColor(hexRGBA: String) -> UIColor {
        if let color = UIColor(hexaRGBA: hexRGBA) {
            return color
        }
        return .black
    }
    static func hexColorARGB(hexARGB: String) -> UIColor {
        if let color = UIColor(hexaARGB: hexARGB) {
            return color
        }
        return .black
    }
}
