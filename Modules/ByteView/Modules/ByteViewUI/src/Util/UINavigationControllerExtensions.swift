//
//  UINavigationControllerExtensions.swift
//  ByteViewCommon
//
//  Created by liurundong.henry on 2021/10/19.
//

import Foundation
import ByteViewCommon
import UniverseDesignColor

/// 导航栏显示样式参数
public struct ByteViewNavigationBarStyleParams {
    public let barStyle: UIBarStyle
    public let barTintColor: UIColor
    public let titleTextColor: UIColor
    public let titleFontSize: CGFloat
    public let buttonTintColor: UIColor
    public let buttonHighlightTintColor: UIColor
    public var barBgColor: UIColor
}

/// 导航栏显示样式
public enum ByteViewNavigationBarStyle {
    case light
    case dark
    case custom(displayParams: ByteViewNavigationBarStyleParams)
    // disable-lint: magic number
    public var displayParams: ByteViewNavigationBarStyleParams {
        switch self {
        case .light:
            return ByteViewNavigationBarStyleParams(
                barStyle: .default,
                barTintColor: .ud.bgBody,
                titleTextColor: .ud.textTitle,
                titleFontSize: 17.0,
                buttonTintColor: .ud.iconN1,
                buttonHighlightTintColor: .ud.N500,
                barBgColor: .ud.bgBody
            )
        case .dark:
            return ByteViewNavigationBarStyleParams(
                barStyle: .black,
                barTintColor: .ud.primaryOnPrimaryFill,
                titleTextColor: .ud.primaryOnPrimaryFill,
                titleFontSize: 17.0,
                buttonTintColor: .ud.iconN1,
                buttonHighlightTintColor: .ud.iconN1,
                barBgColor: .ud.N800
            )
        case .custom(displayParams: let displayParams):
            return displayParams
        }
    }
    // enable-lint: magic number
    /// 以一种导航栏显示样式为基础，生成指定背景颜色的样式
    public static func generateCustomStyle(_ originStyle: ByteViewNavigationBarStyle, bgColor: UIColor) -> ByteViewNavigationBarStyle {
        var modifiedDisplayParams = originStyle.displayParams
        modifiedDisplayParams.barBgColor = bgColor
        return ByteViewNavigationBarStyle.custom(displayParams: modifiedDisplayParams)
    }
}

public extension VCExtension where BaseType: UINavigationController {
    /// 更新导航栏样式
    func updateBarStyle(_ style: ByteViewNavigationBarStyle) {
        let displayParams: ByteViewNavigationBarStyleParams
        switch style {
        case .light, .dark:
            displayParams = style.displayParams
        case .custom(let customParams):
            displayParams = customParams
        }
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: displayParams.titleTextColor,
                                   NSAttributedString.Key.font: UIFont.systemFont(ofSize: displayParams.titleFontSize, weight: .medium)]
        internalSetBarStyle(displayParams.barStyle,
                            tintColor: displayParams.buttonTintColor,
                            backgroundImage: UIImage.ud.fromPureColor(displayParams.barBgColor),
                            titleTextAttributes: titleTextAttributes)
    }
    /// 设置导航栏上各项颜色
    private func internalSetBarStyle(
        _ style: UIBarStyle,
        tintColor: UIColor,
        backgroundImage: UIImage,
        titleTextAttributes: [NSAttributedString.Key: Any]) {
            if #available(iOS 15.0, *) {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.shadowImage = UIImage()
                appearance.shadowColor = .clear
                appearance.backgroundImage = backgroundImage
                appearance.titleTextAttributes = titleTextAttributes
                base.navigationBar.tintColor = tintColor
                base.navigationBar.standardAppearance = appearance
                base.navigationBar.scrollEdgeAppearance = appearance
                base.navigationBar.isTranslucent = false
            } else {
                self.base.navigationBar.isTranslucent = false
                self.base.navigationBar.shadowImage = UIImage()
                self.base.navigationBar.setBackgroundImage(backgroundImage, for: .default)
                self.base.navigationBar.tintColor = tintColor
                self.base.navigationBar.titleTextAttributes = titleTextAttributes
                self.base.navigationBar.barStyle = style
            }
        }
}
