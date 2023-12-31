//
//  AvatarColorTool.swift
//  LarkChatSetting
//
//  Created by liluobin on 2023/2/14.
//

import LarkUIKit
import LarkExtensions
import UniverseDesignColor

final class AvatarImageCacheManager {
    /// 各颜色对应的默认图片，缓存起来，防止重复创建
    private var colorImageMap: [String: UIImage] = [:]

    func getColorImageFor(originImage: UIImage, color: UIColor) -> UIImage {
        guard let hex6 = color.hex6 else {
            return originImage.ud.withTintColor(color)
        }
        if let image = colorImageMap[hex6] { return image }
        // 通过颜色，生成对应的图片
        let resultImage = originImage.ud.withTintColor(color)
        colorImageMap[hex6] = resultImage
        return resultImage
    }
}

final class ColorCalculator {
    static func middleColorForm(_ from: UIColor, to: UIColor) -> UIColor {
        guard let fromValue = from.hex6?.replacingOccurrences(of: "#", with: ""),
              let toValue = to.hex6?.replacingOccurrences(of: "#", with: ""),
                fromValue.count == 6,
              toValue.count == 6 else {
            return from
        }
        let fromRGB = self.getRGBValue(colorText: fromValue)
        let toRGB = self.getRGBValue(colorText: toValue)
        // swiftlint:disable all
        let color = UIColor(red: (fromRGB.0 + toRGB.0) / (2.0 * 255),
                            green: (fromRGB.1 + toRGB.1) / (2.0 * 255),
                            blue: (fromRGB.2 + toRGB.2) / (2.0 * 255),
                            alpha: 1.0)
        // swiftlint:enable all
        return color
    }

    static func getRGBValue(colorText: String) -> (CGFloat, CGFloat, CGFloat) {
        let mask = 0x000000FF
        var color: UInt32 = 0
        let scanner = Scanner(string: colorText)
        scanner.scanHexInt32(&color)
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        return (CGFloat(r), CGFloat(g), CGFloat(b))
    }
}
