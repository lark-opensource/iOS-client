//
//  UDMenuStyleConfig
//  UniverseDesignMenu
//
//  Created by qsc on 2020/11/11.
//  Copyright © ByteDance. All rights reserved.
//

import UIKit
import Foundation
import UniverseDesignColor
import UniverseDesignStyle

/// UDMenu 的外观配置
/// 未来应该是提供 enum 能力 and 读取全局配置能力对外

/// 列表阴影大小，small/medium/large三种可选
public enum UDMenuShadowSize {
    case small
    case medium
    case large
}

/// 列表阴影位置，all/up/down/left/right 五种可选
public typealias UDMenuShadowType = UIView.ShadowType

/// Menu 样式配置，包含颜色、阴影、字体、大小等
public struct UDMenuStyleConfig {

    /// menu 遮罩层颜色，默认为 neutralColor14+ alpha = 0.3
    public var maskColor: UIColor = UDMenuColorTheme.menuMaskColor

    /// menu 列表的背景色，默认为 neutralColor12
    public var menuColor: UIColor = UDMenuColorTheme.menuBackgroundColor

    /// 列表的阴影大小，默认为 medium
    public var menuShadowSize: UDMenuShadowSize = .medium

    /// 列表的阴影位置，默认为 down
    public var menuShadowPosition: UDMenuShadowType = .down

    /// menu 列表宽度
    public var menuWidth: CGFloat?

    /// menu 列表最小宽度，默认为132
    public var menuMinWidth: CGFloat = MenuCons.menuMinWidth

    /// menu 列表可展示的最大宽度，默认为Scene宽度，如果文本过多，菜单过宽
    /// 可自行配置 Menu 最大宽度，推荐配置值为 210
    public var menuMaxWidth: CGFloat {
        set {
            _menuMaxWidth = min(newValue, MenuCons.sceneFrame.width)
        }
        get {
            return _menuMaxWidth
        }
    }

    /// menu 列表项高度，默认 50pt
    public var menuItemHeight: CGFloat = 50

    /// menu 列表的圆角大小，默认为 largeRadius (8pt)
    public var cornerRadius: CGFloat = MenuCons.menuCornerRadius

    /// menu 列表距离触发区垂直方向的距离，默认 4pt
    public var marginToSourceY: CGFloat = MenuCons.menuMargin

    /// menu 列表距离触发区水平方向的距离，默认 0pt
    public var marginToSourceX: CGFloat = 0

    /// menu 列表项第一项和最后一项额外增加的距离边缘的 Inset，老版本默认 8px, 新版本为4px.
    public var menuListInset: CGFloat = MenuCons.menuMargin

    // MARK: - menu item style

    /// icon 宽度 & 高度，默认20
    public var menuItemIconWidth: CGFloat = MenuCons.iconDefaultWidth

    /// icon tint color, 用于传入 renderMode 为 template 的 icon，默认 neutralColor11
    public var menuItemIconTintColor: UIColor = UDMenuColorTheme.menuItemIconTintColor

    /// Title Color 默认 neutralColor12
    public var menuItemTitleColor: UIColor = UDMenuColorTheme.menuItemTitleColor

    /// TitleFont 默认 UDFont.body2
    public var menuItemTitleFont: UIFont = MenuCons.titleFont

    /// 背景色，默认 neutralColor1
    public var menuItemBackgroundColor: UIColor = UDMenuColorTheme.menuItemBackgroundColor

    /// 按下时背景色, 默认为 neutralColor4
    public var menuItemSelectedBackgroundColor: UIColor = UDMenuColorTheme.menuItemSelectedBackgroundColor

    /// 分割线颜色, 默认为 neutralColor5:N300
    public var menuItemSeperatorColor: UIColor = UDMenuColorTheme.menuItemSeperatorColor

    /// icon 禁用颜色，默认为icon disabled
    public var menuItemIconDisableColor: UIColor = UDMenuColorTheme.menuIconDisableColor

    /// title & subTitle 禁用颜色，默认为text disabled
    public var menuItemTextDisableColor: UIColor = UDMenuColorTheme.menuTextDisableColor

    /// subTitle 字体
    public var menuItemSubTitleFont: UIFont = MenuCons.subTitleFont

    /// 是否开启subTitle只显示一行显示(如显示手机号，会议号等情况）
    public var showSubTitleInOneLine: Bool = true

    /// menu 在 popover 下是否展示箭头
    public var showArrowInPopover: Bool = true

    /// menu 贴着 sourceView 的方向的距离
    public var menuOffsetFromSourceView: Int = 4

    /// 默认配置
    public static func defaultConfig() -> UDMenuStyleConfig {
        return UDMenuStyleConfig()
    }

    private var _menuMaxWidth: CGFloat = MenuCons.sceneFrame.width
}

internal enum MenuCons {
    /// 标题字体
    static var titleFont: UIFont { UIFont.ud.body2(.fixed) }
    /// 副标题字体
    static var subTitleFont: UIFont { UIFont.ud.caption1(.fixed) }
    /// 图标到左侧边界距离
    static var iconPaddingLeft: CGFloat { 16 }
    /// 图标默认宽度
    static var iconDefaultWidth: CGFloat { 20 }
    /// 图标 - 文本 间距
    static var iconTextSpacing: CGFloat { 12 }
    /// 文本内容到右侧边界距离
    static var textPaddingRight: CGFloat { 16 }
    /// 标题 - 副标题 间距
    static var titleSubTitleSpacing: CGFloat { 2 }
    /// content 到顶部距离
    static var paddingTop: CGFloat { 15 }
    /// content 到底部距离
    static var paddingBottom: CGFloat { 15 }
    /// Menu 缩进距离
    static var menuMargin: CGFloat { 4 }
    /// MenuItem 按压态的圆角尺寸
    static var menuItemPressedCornerRadius: CGFloat { 4 }
    /// Menu 弹出的VC圆角尺寸
    static var menuCornerRadius: CGFloat { 8 }
    /// Menu 分割线高度
    static var menuDivideLineHeight: CGFloat { 1 }
    /// Menu 分割线View 高度
    static var menuDivideViewHeight: CGFloat { 5 }
    /// Menu 的最小宽度
    static var menuMinWidth: CGFloat { 120 }
    /// Menu 的最大宽度
    static var menuMaxWidth: CGFloat { 210 }
    /// 其他宽度
    static var otherWidth: CGFloat { iconPaddingLeft + iconDefaultWidth + iconTextSpacing + textPaddingRight }
    /// 只有标题时的高度(固定值）
    static var menuItemDefaultHeight: CGFloat { paddingTop + paddingBottom + titleLineHeight}
    /// 有副标题时的不含副标题的高度
    static var otherHeight : CGFloat { menuItemDefaultHeight + titleSubTitleSpacing}

    /// title lineHeight 14 -> 20
    static var titleLineHeight = MenuCons.titleFont.figmaHeight
    /// subTitle lineHeight 12 -> 18px
    static var subTitleLineHeight = MenuCons.subTitleFont.figmaHeight

    static var sceneFrame: CGRect {
        if #available(iOS 13.0, *),
           let windowScene = UIApplication.shared.connectedScenes.first(where: { return $0.session.role == .windowApplication }) as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.frame
        } else {
            return UIScreen.main.bounds
        }
    }
}
