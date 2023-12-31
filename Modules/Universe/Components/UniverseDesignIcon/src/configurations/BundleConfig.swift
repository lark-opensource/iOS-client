// Warning: Do Not Edit It!
// Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
// Toolchains For EE
/*
 *
 *
 *  ______ ______ _____        __
 * |  ____|  ____|_   _|      / _|
 * | |__  | |__    | |  _ __ | |_ _ __ __ _
 * |  __| |  __|   | | | '_ \|  _| '__/ _` |
 * | |____| |____ _| |_| | | | | | | | (_| |
 * |______|______|_____|_| |_|_| |_|  \__,_|
 *
 *
 */

import Foundation
import UIKit

// swiftlint:disable all
class BundleConfig: NSObject {
    static let SelfBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/UniverseDesignIcon", withExtension: "framework") {
            return Bundle(url: url)!
        } else {
            return Bundle.main
        }
    }()
    private static let UniverseDesignIconBundleURL = SelfBundle.url(forResource: "UniverseDesignIcon", withExtension: "bundle")
    static let UniverseDesignIconBundle: Bundle? = {
        if let bundleURL = UniverseDesignIconBundleURL {
            return Bundle(url: bundleURL)
        }
        return nil
    }()
}

class BundleResources {

    enum ImageError: String, Error {
        case resourceNotFound
        case iconFontNotLoaded
        case imageSizeNotValid
        case imageContextError
        case unknownError
    }

    static func imageFromAssets(named name: String) throws -> UIImage {
        guard let image = UIImage(named: name,
                                  in: BundleConfig.UniverseDesignIconBundle,
                                  compatibleWith: nil) else {
            throw ImageError.resourceNotFound
        }
        return image
    }

    /// 通过 IconFont 创建 UDIcon image 实例
    /// - Parameters:
    ///   - type: UDIcon token，从 Figma 设计稿中获得
    ///   - fontSize: IconFont 字体大小，默认即为图标宽度
    ///   - imageSize: IconFont 生成图标大小，默认为 48x48
    static func imageFromIconFont(unicode iconCode: String,
                                  size iconSize: CGSize) throws -> UIImage {
        guard let iconfont = getIconFont(size: iconSize.height) else {
            throw ImageError.iconFontNotLoaded
        }

        if iconSize.isEmpty() {
            throw ImageError.imageSizeNotValid
        }

        var iconRect = CGRect(origin: .zero, size: iconSize)
        if __CGSizeEqualToSize(iconSize, CGSize.zero) {
            iconRect = CGRect(origin: .zero, size: iconCode.size(withAttributes: [.font: iconfont]))
        }
        UIGraphicsBeginImageContextWithOptions(iconRect.size, false, 0)
        defer { UIGraphicsEndImageContext() }

        if iconRect.isEmpty() {
            throw ImageError.imageSizeNotValid
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center
        let iconCodeString = NSAttributedString(
            string: iconCode,
            attributes: [.font : iconfont, .paragraphStyle: paragraphStyle]
        )
        iconCodeString.draw(in: iconRect)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            throw ImageError.imageContextError
        }
        return image
    }

    private static var isIconFontRegistered = false
    private static var iconFontName = "UniverseDesignIconFont"

    private static func getIconFont(size fontSize: CGFloat) -> UIFont? {
        // 注册 IconFont 字体
        if !isIconFontRegistered {
            registerIconFont()
        }
        // 获取 IconFont 字体
        if let font = UIFont(name: iconFontName, size: fontSize) {
            return font
        }
        // 重试注册并获取 IconFont 字体，避免第一次注册失败
        registerIconFont()
        if let newFont = UIFont(name: iconFontName, size: fontSize) {
            return newFont
        }
        return nil
    }

    private static func registerIconFont() {
        UIFont.ud.registerFont(withFilenameString: "UniverseDesignIconFont.ttf", bundle: BundleConfig.UniverseDesignIconBundle ?? Bundle.main)
        isIconFontRegistered = true
    }
}
// swiftlint:enable all
