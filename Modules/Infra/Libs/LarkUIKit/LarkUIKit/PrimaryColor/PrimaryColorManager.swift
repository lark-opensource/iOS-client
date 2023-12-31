//
//  PrimaryColorManager.swift
//  LarkThread
//
//  Created by lizhiqiang on 2019/10/14.
//

import UIKit
import Foundation
import ByteWebImage
import LKCommonsLogging
import LarkStorage

// swiftlint:disable init_color_with_token
open class PrimaryColorManager {
    private static let logger = Logger.log(PrimaryColorManager.self, category: "PrimaryColor")
    open class var trailKey: String {
        assertionFailure("子类必须重写")
        return ""
    }
    // limit maxSaturation minBrightness maxBrightness
    public static let maxSaturation: CGFloat = 0.5
    public static let maxBrightness: CGFloat = 0.5
    public static let minBrightness: CGFloat = 0.3

    public static func getPrimaryColorImageBy(image: UIImage, avatarKey: String, size: CGSize, finish: @escaping (UIImage?, Error?) -> Void) {
        let colorCacheKey = avatarKey + Self.trailKey
        let imageCacheKey = avatarKey + "_\(size.width)_\(size.height)" + Self.trailKey

        func handlePrimaryColor(_ domainColor: UIColor?) {
            guard let primaryColor = domainColor else {
                finish(nil, nil)
                return
            }
            // save color to cache file
            Self.saveCacheColor(primaryColor, for: colorCacheKey)
            // get image
            let blendImage = Self.getScreenBlendModelImageBy(color: primaryColor, size: size)
            // save new blend image to cache
            LarkImageService.shared.cacheImage(image: blendImage, resource: .default(key: imageCacheKey))
            finish(blendImage, nil)
        }

        // get blendImage from cache
        if let blendImage = LarkImageService.shared.image(with: .default(key: imageCacheKey)) {
            finish(blendImage, nil)
            return
        }

        // get primaryColor from cache
        if let cachePrimaryColor = Self.getCacheColor(by: colorCacheKey) {
            handlePrimaryColor(cachePrimaryColor)
            return
        }

        // get primaryColor from image
        Self.getDomainColorByImage(image, quality: .lowest, finish: { (domainColor) in
            handlePrimaryColor(domainColor)
        })
    }

    private static func getDomainColorByImage(_ image: UIImage, quality: UIImage.UIImageColorsQuality, finish: @escaping (UIColor?) -> Void) {
        func finishInMainThread(color: UIColor?) {
            DispatchQueue.main.async {
                finish(color)
            }
        }

        DispatchQueue.global().async {
            // get size by qulity.
            let newSize = image.getScaleDownSize(quality: quality)
            // resize image by new size
            guard let newImage = image.getResizeImageBySize(newSize) else {
                finishInMainThread(color: nil)
                return
            }
            // get domain color
            guard let domainColor = ColorThief.getColor(from: newImage)?.makeColor() else {
                finishInMainThread(color: nil)
                return
            }

            // get limited color
            let limitedColor = Self.getLimitedColor(domainColor)

            finishInMainThread(color: limitedColor)
        }
    }

    private static func getLimitedColor(_ color: UIColor) -> UIColor {
        var HSB = color.covertToHSB()
        HSB = adjustColorForHSB(HSB)
        return UIColor(hue: HSB.H, saturation: HSB.S, brightness: HSB.B, alpha: 1)
    }

    open class func adjustColorForHSB(_ HSB: (H: CGFloat, S: CGFloat, B: CGFloat)) -> (H: CGFloat, S: CGFloat, B: CGFloat) {
        let S = min(HSB.S, Self.maxSaturation)
        let B = max(min(HSB.B, Self.minBrightness), Self.maxBrightness)
        return (H: HSB.H, S: S, B: B)
    }

    private static func getScreenBlendModelImageBy(color: UIColor, size: CGSize) -> UIImage {
        // get gradient image
        let topImage = UIImage.getGradientImageByColors(
            [
                color.withAlphaComponent(0.6),
                color.withAlphaComponent(0)
            ],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 0, y: 1),
            size: size
        )
        // get image form a color and size
        let bottomImage = UIImage.getImageByColor(color, size: size)
        // blend images by screen model
        let newImage = UIImage.getImageByBlendBottomImage(
            bottomImage,
            topImage: topImage,
            size: size,
            blendModel: .screen
        )
        return newImage
    }

    private static func getCacheColor(by key: String) -> UIColor? {
        if let dic = Self.getCacheColorPlist() {
            return dic[key]
        }
        return nil
    }

    private static func saveCacheColor(_ color: UIColor, for key: String) {
        var colorDic: [String: UIColor]
        if let dic = Self.getCacheColorPlist() {
            colorDic = dic
        } else {
            colorDic = [String: UIColor]()
        }
        colorDic[key] = color
        let path = Self.getCacheColorPath()
        let result = path.archive(rootObject: colorDic)
        if result == false {
            PrimaryColorManager.logger.error("write file error key is \(key)")
        }
    }

    private static func getCacheColorPlist() -> [String: UIColor]? {
        let cachePath = Self.getCacheColorPath()
        if cachePath.exists {
            return cachePath.unarchive() as? [String: UIColor]
        } else {
            return nil
        }
    }

    private static func getCacheColorPath() -> IsoPath {
        let domain = Domain.biz.messenger.child("PrimaryColor")
        let cachePath = IsoPath.in(space: .global, domain: domain).build(.cache)
        do {
            try cachePath.createDirectoryIfNeeded()
        } catch {
            PrimaryColorManager.logger.error("create \(businessPath()) dir fail \(error.localizedDescription)")
        }
        return cachePath + "primryCacheColor.plist"
    }

    open class func businessPath() -> String {
        assertionFailure("子类必须重写")
        return ""
    }
}

extension UIImage {
    public enum UIImageColorsQuality: CGFloat {
        case lowest = 20 // 20px
        case low = 50 // 50px
        case medium = 100 // 100px
        case high = 250 // 250px
        case highest = 0 // No scale
    }

    public func getScaleDownSize(quality: UIImageColorsQuality) -> CGSize {
        var scaleDownSize: CGSize = self.size
        if quality != .highest {
            // 如果需要缩小的都已经>=最大的边
            if quality.rawValue >= max(self.size.width, self.size.height) {
                return scaleDownSize
            }
            // 最长边缩小成指定size
            if self.size.width < self.size.height {
                let ratio = self.size.height / self.size.width
                scaleDownSize = CGSize(width: quality.rawValue / ratio, height: quality.rawValue)
            } else {
                let ratio = self.size.width / self.size.height
                scaleDownSize = CGSize(width: quality.rawValue, height: quality.rawValue / ratio)
            }
        }

        return scaleDownSize
    }

    public func getResizeImageBySize(_ newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        defer {
            UIGraphicsEndImageContext()
        }
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }

        return result
    }

    class func getImageByBlendBottomImage(_ bottomImage: UIImage, topImage: UIImage, size: CGSize, blendModel: CGBlendMode) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)

        let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        bottomImage.draw(in: areaSize)
        topImage.draw(in: areaSize, blendMode: blendModel, alpha: 1)
        let newImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()

        return newImage
    }

    class func getGradientImageByColors(_ colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint, size: CGSize) -> UIImage {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: size)
        gradientLayer.colors = colors.map({ (color) -> CGColor in
            return color.cgColor
        })
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        UIGraphicsGetCurrentContext().flatMap { gradientLayer.render(in: $0) }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image ?? UIImage()
    }

    class func getImageByColor(_ color: UIColor, size: CGSize, opaque: Bool = true) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, opaque, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        /// ci自测上有反馈一列crash，强制解包导致 做个兼容
        return img ?? UIImage()
    }
}

extension UIColor {
    func covertToHSB() -> (H: CGFloat, S: CGFloat, B: CGFloat) {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        // 如果需要标准的HSB，H还需要 H * 360
        return (h, s, b)
    }
}
// swiftlint:enable init_color_with_token
