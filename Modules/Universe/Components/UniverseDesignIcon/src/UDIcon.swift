//
//  UDIcon.swift
//  UniverseIcon
//
//  Created by 姚启灏 on 2020/8/6.
//

import UIKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignTheme

// MARK: - Public

public typealias UDIconKey = UDIconType

public class UDIcon {

    // 非iconFont资源，资源名称前添加icon_
    static let assetPrefix = "icon_"

    public static var tracker: UDTrackerDependency?

    public static var iconFontEnable: Bool = false

    /// 通过 key 获取图标
    /// - Parameters:
    ///   - key: 图标 key，命名参照 Figma 设计稿（去前缀改驼峰命名）
    ///   - renderingMode: 图片渲染模式，默认为 .automatic
    ///   - iconColor: 图标染色，若为空则对单色图标染，彩色图标保持原色，默认为 nil
    ///   - size: 图标尺寸，若为空返回默认边长 24 的方形图标，默认值为 nil  【2倍为 24，3 倍为 48】
    public static func getIconByKey(_ key: UDIconKey,
                                    renderingMode: UIImage.RenderingMode = .automatic,
                                    iconColor: UIColor? = nil,
                                    size: CGSize? = nil) -> UIImage {
        return generateIconByKey(key,
                                 size: size ?? Cons.minIconSize,
                                 color: iconColor,
                                 renderingMode: renderingMode)
    }

    /// 通过名称字符串获取图标
    /// Figma 链接：https://www.figma.com/file/z27mSnJ9vbBeW6VnkLVAg6/%5BUD%5D-07-%E5%9B%BE%E6%A0%87%E8%A1%A8%E6%83%85%E5%BA%93?type=design&node-id=1-30&mode=design&t=xoWh5omsI4E8jHQX-0
    /// - Parameters:
    ///   - keyName: 图标名称，命名参照 Figma 设计稿（去前缀改驼峰命名）
    ///   - renderingMode: 图片渲染模式，默认为 .automatic
    ///   - iconColor: 图标染色，若为空则对单色图标染，彩色图标保持原色，默认为 nil
    ///   - size: 图标尺寸，若为空返回默认边长 24 的方形图标，默认值为 nil 【2倍为 24，3 倍为 48】
    ///
    /// 字符串示例：`icon_mail-setting_outlined` 或 `mail-setting_outlined` 的形式均可
    public static func getIconByString(_ keyName: String,
                                       renderingMode: UIImage.RenderingMode = .automatic,
                                       iconColor: UIColor? = nil,
                                       size: CGSize? = nil) -> UIImage? {
        guard let lowerCamelStyle = UDIcon.convertToLowerCamelStyle(keyName) else { return nil }
        guard let key = UDIconKey(named: lowerCamelStyle) else {
            return nil
        }
        return generateIconByKey(key,
                                 size: size ?? Cons.minIconSize,
                                 color: iconColor,
                                 renderingMode: renderingMode)
    }

    /// 通过 key 获取图标，默认不缩放，需要业务方自己处理
    /// - Parameters:
    ///   - key: 图标 key，命名参照 Figma 设计稿（去前缀改驼峰命名）
    ///   - renderingMode: 图片渲染模式，默认为 .automatic
    ///   - iconColor: 图标染色，若为空则对单色图标染，彩色图标保持原色，默认为 nil
    public static func getIconByKeyNoLimitSize(_ key: UDIconKey,
                                               renderingMode: UIImage.RenderingMode = .automatic,
                                               iconColor: UIColor? = nil) -> UIImage {
        return generateIconByKey(key,
                                 size: nil,
                                 color: iconColor,
                                 renderingMode: renderingMode)
    }

    /// 获取适配 Context Menu 菜单大小的图标
    ///
    /// - Note: https://bytedance.feishu.cn/wiki/wikcnLD3kmD41T2Vr6BAVQelUZt
    public static func getContextMenuIconBy(key: UDIconKey,
                                            renderingMode: UIImage.RenderingMode = .automatic,
                                            iconColor: UIColor? = nil) -> UIImage {
        let contentSize = CGSize(width: 20, height: 20)
        let fullSize = CGSize(width: 24, height: 24)
        let rawIcon = generateIconByKey(key,
                                        size: contentSize,
                                        color: iconColor,
                                        renderingMode: renderingMode)
        let imageOrigin = CGPoint(x: (fullSize.width - contentSize.width) / 2,
                                  y: (fullSize.height - contentSize.height) / 2)
        UIGraphicsBeginImageContextWithOptions(fullSize, false, 0)
        rawIcon.draw(in: CGRect(origin: imageOrigin, size: contentSize))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let contextMenuIcon = result ?? rawIcon
        return contextMenuIcon
    }

    /// 通过字符串获取图标 key
    public static func getIconTypeByName(_ key: String) -> UDIconKey? {
        guard let iconName = UDIcon.convertToLowerCamelStyle(key) else { return nil }
        return UDIconKey(named: iconName)
    }
}

// MARK: - Private

extension UDIcon {

    private static func generateIconByKey(_ key: UDIconKey,
                                          size: CGSize? = nil,
                                          color: UIColor? = nil,
                                          renderingMode: UIImage.RenderingMode = .automatic) -> UIImage {
        // 获取资源
        var iconImage: UIImage
        do {
            switch key.resource {
            case .assetFile(let iconName):
                iconImage = try BundleResources.imageFromAssets(named: iconName)
                if let preferredIconSize = size, iconImage.size != preferredIconSize, !preferredIconSize.isEmpty() {
                    iconImage = iconImage.ud.resized(to: preferredIconSize)
                }
            case .iconFont(let iconCode):
                let preferredIconSize = size ?? Cons.largeIconSize
                iconImage =  try BundleResources.imageFromIconFont(unicode: iconCode, size: preferredIconSize)
            }
        } catch let error as BundleResources.ImageError {
            UDIcon.tracker?.logger(component: .UDIcon, loggerType: .error, msg: "Generate icon failed with resource error: \(error.rawValue)")
            iconImage = UIImage()
        } catch {
            UDIcon.tracker?.logger(component: .UDIcon, loggerType: .error, msg: "Generate icon failed with unexpected error: \(error.localizedDescription)")
            iconImage = UIImage()
        }
        // 染色
        if let preferredIconColor = color {
            iconImage = iconImage.ud.withTintColor(preferredIconColor, renderingMode: renderingMode)
        } else if !key.resource.rawValue.lowercased().hasSuffix("colorful") {
            iconImage = iconImage.ud.withTintColor(Cons.defaultIconColor, renderingMode: renderingMode)
        }
        // 更改 RenderingMode
        if iconImage.renderingMode != renderingMode {
            iconImage = iconImage.withRenderingMode(renderingMode)
        }
        return iconImage
    }

    private static func convertToLowerCamelStyle(_ figmaName: String) -> String? {
        guard !figmaName.isEmpty else { return nil }
        var string = figmaName
        if figmaName.starts(with: assetPrefix) {
            string.removeFirst(assetPrefix.count)
        }

        var index = string.index(before: string.endIndex)
        while index != string.startIndex {
            if string[index] == "-" || string[index] == "_" {
                let next = string.index(after: index)
                string.replaceSubrange(index...next, with: string[next].uppercased())
            }

            index = string.index(before: index)
        }
        return string
    }
}

// MARK: - Constants

fileprivate enum Cons {

    // icon 默认颜色
    static let defaultIconColor = UIColor.ud.iconN1

    // 默认绘制的小尺寸 Icon 尺寸
    static var minIconSize: CGSize = CGSize(width: 24, height: 24)

    // 默认绘制的中尺寸 Icon 尺寸
    static var largeIconSize: CGSize = CGSize(width: 48, height: 48)
}

// MARK: - Utils

public extension UIImage {

    internal func isNilOrEmpty() -> Bool {
        let isCGOrCIImageEmpty = (self.cgImage == nil) && (self.ciImage == nil)
        let isWidthEmpty = self.size.width == 0
        let isHeightEmpty = self.size.height == 0
        return isCGOrCIImageEmpty || isWidthEmpty || isHeightEmpty
    }
}

extension CGSize {
    func isEmpty() -> Bool {
        return self.width.isZero || self.height.isZero
    }
}

extension CGRect {
    func isEmpty() -> Bool {
        return self.size.isEmpty() || self.isNull || self.isEmpty
    }
}

enum UDIconResource {
    case iconFont(_ code: String)
    case assetFile(_ name: String)

    var rawValue: String {
        switch self {
        case .iconFont(let code):
            return code
        case .assetFile(let name):
            return name
        }
    }
}
