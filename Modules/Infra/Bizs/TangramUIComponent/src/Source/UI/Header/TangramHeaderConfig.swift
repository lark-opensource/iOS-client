//
//  TangramHeaderConfig.swift
//  TangramHeaderView
//
//  Created by Saafo on 2021/4/22.
//

import UIKit
import Foundation
import LarkTag
import UniverseDesignColor
import UniverseDesignTheme

/// TangramHeaderView 的初始化配置
public struct TangramHeaderConfig {
    public typealias CustomViewProvider = () -> UIView?

    public static var `default`: TangramHeaderConfig {
        return TangramHeaderConfig(
            title: "",
            titleColor: UDColor.textTitle,
            titleNumberOfLines: 3,
            iconProvider: nil,
            headerTag: nil,
            theme: .light,
            showMenu: false,
            menuTapHandler: nil,
            customView: nil,
            customViewSize: .zero
        )
    }

    /// tagType优先级大于tag，textColor，backgroundColor，font作用于tag
    public struct HeaderTag: Equatable {
        public var tagType: TagType?
        public var tag: String?
        public var textColor: UIColor
        public var backgroundColor: UIColor
        // 与TagType对齐，Tag不支持自提缩放
        public var font: UIFont

        public init(tagType: TagType? = nil,
                    tag: String? = nil,
                    textColor: UIColor = UIColor.ud.textCaption,
                    backgroundColor: UIColor = UIColor.ud.staticBlack.withAlphaComponent(0.1),
                    font: UIFont = UIFont.ud.caption0) {
            self.tagType = tagType
            self.tag = tag
            self.textColor = textColor
            self.backgroundColor = backgroundColor
            self.font = font
        }

        public static func == (_ left: HeaderTag, _ right: HeaderTag) -> Bool {
            return left.tagType == right.tagType &&
                left.tag == right.tag &&
                left.textColor == right.textColor &&
                left.backgroundColor == right.backgroundColor &&
                left.font == right.font
        }
    }

    public enum Theme {
        case light
        case dark

        public var iconColor: UIColor {
            switch self {
            case .light: return UIColor.ud.iconN2
            case .dark: return UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
            }
        }
    }

    public var textColor: UIColor {
        // 保留线上对Style.textColor的响应，方便后续扩展，只是不再对外暴露
        if let titleColor = self.titleColor {
            return titleColor
        }
        switch self.theme {
        case .light: return UIColor.ud.textTitle
        case .dark: return UIColor.ud.primaryOnPrimaryFill
        }
    }

    /// 标题内容
    public var title: String
    /// 标题字体颜色，若为nil，则用默认规则textColor
    public var titleColor: UIColor?
    public var titleNumberOfLines: Int
    /// 设置图标的闭包
    public var iconProvider: ((UIImageView) -> Void)?
    /// 标题后的 Tag
    public var headerTag: HeaderTag?
    /// 亮暗主题，默认为亮色
    public var theme: Theme
    public var showMenu: Bool = false
    public var menuTapHandler: ((UIButton) -> Void)?
    /// 可配置区域
    public var customView: CustomViewProvider?
    public var customViewSize: CGSize = .zero

    /// - Parameters:
    ///   - title:                      标题内容
    ///   - iconProvider:               设置图标的闭包
    ///   - headerTag:                  标题后的 Tag
    ///   - customView:                 可配置区域，传入前必须已经设置好大小
    ///   - customViewSize:            customView size
    public init(title: String,
                titleColor: UIColor?,
                titleNumberOfLines: Int,
                iconProvider: ((UIImageView) -> Void)?,
                headerTag: HeaderTag?,
                theme: Theme,
                showMenu: Bool,
                menuTapHandler: ((UIButton) -> Void)?,
                customView: CustomViewProvider?,
                customViewSize: CGSize) {
        self.title = title
        self.titleColor = titleColor
        self.titleNumberOfLines = titleNumberOfLines
        self.iconProvider = iconProvider
        self.headerTag = headerTag
        self.theme = theme
        self.showMenu = showMenu
        self.menuTapHandler = menuTapHandler
        self.customView = customView
        self.customViewSize = customViewSize
    }
}
