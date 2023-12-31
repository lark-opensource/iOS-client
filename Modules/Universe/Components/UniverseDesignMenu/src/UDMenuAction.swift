//
//  UDMenuAction.swift
//  UDMenu
//
//  Created by  豆酱 on 2020/10/25.
//

import Foundation
import UIKit

/// UDMenu的点击回调
public typealias TapHandler = (() -> Void)

// MARK: 用以存储 menu 中一行数据的数据结构

/// 菜单选项类
///
/// 对单个选项的图标、标题、描述文字、是否禁用菜单等配置进行设置
public struct UDMenuAction {

    /// 菜单选项标题，注意不要超过4个汉字/9个字符
    ///
    /// 菜单选项标题用来表述该菜单选项的主要作用。通过初始化函数初始化，是UDMenuAction的必选项
    public var title: String

    /// 菜单选项图标，会强制使用组件预设颜色，如果需要自定义图标，请使用`customIconHandler`
    ///
    /// 菜单选项图标用来快速帮助用户定位以及作出相应的决定。通过初始化函数初始化，是UDMenuAction的必选项
    public var icon: UIImage?

    /// 菜单选项描述文字
    ///
    /// `subTitle` 用来辅助说明菜单选项功能的说明文字。通过访问属性进行赋值，是UDMenuAction的可选项
    ///
    /// ```swift
    /// action.subTitle = "demo of subTitle"
    /// ```
    public var subTitle: String?

    /// 菜单选项是否展示 badge
    ///
    /// badge 用来标注小红点
    public var hasBadge: Bool = false

    /// 是否禁用该菜单选项
    ///
    /// `isDisabled` 用来控制该菜单选项的禁用状态。通过访问属性进行赋值，默认为 false
    ///
    /// ```swift
    /// action.isDisabled = true
    /// ```
    public var isDisabled: Bool = false
    
    /// 是否使用业务自定义的图片，如彩色图标 / 自行染色
    ///
    /// `customIconHandler`内可以使用本地图片或网络图片进行自定义配置
    public var customIconHandler: ((UIImageView) -> Void)?

    /// 菜单选项是否展示下方间隔线
    public var showBottomBorder: Bool

    /// 菜单选项点击处理事件
    public var tapHandler: (() -> Void)?

    /// 点击禁用选项的处理事件
    ///
    /// `tapDisableHandler` 可用来处理如埋点上报、禁用提示等禁用状态下的交互需求
    public var tapDisableHandler: (() -> Void)?
    
    /// 点击事件是否在 Menu dismiss 动画完成之后执行
    public var shouldInvokeTapHandlerAfterMenuDismiss: Bool = false

    /// 菜单选项标题颜色
    ///
    /// `titleTextColor`可用来配置菜单选项标题颜色，设置此值后，Menu 统一颜色配置将对此菜单选项不生效
    public var titleTextColor: UIColor?

    /// 菜单选项副标题颜色
    ///
    /// `subTitleTextColor`可用来配置菜单选项副标题颜色，设置此值后，Menu 统一颜色配置将对此菜单选项不生效
    public var subTitleTextColor: UIColor?

    /// UDMenuAction: 初始化一个Menu选项
    /// - Parameters:
    ///   - icon: 图标
    ///   - title: 标题
    ///   - tapHandler: 点击回调
    public init(title: String, icon: UIImage?, tapHandler: TapHandler?) {
        self.init(title: title,
                  icon: icon,
                  subTitle: nil,
                  hasBadge: false,
                  isDisabled: false,
                  customIconHandler: nil,
                  showBottomBorder: false,
                  tapHandler: tapHandler,
                  tapDisableHandler: nil)
    }

    /// UDMenuAction: 初始化一个Menu选项
    /// - Parameters:
    ///   - title: 标题
    ///   - icon: 图标
    ///   - showBottomBorder: 是否展示下方间隔线
    ///   - tapHandler: 点击回调
    public init(title: String, icon: UIImage?, showBottomBorder: Bool = false, tapHandler: TapHandler?) {
        self.init(title: title,
                  icon: icon,
                  subTitle: nil,
                  hasBadge: false,
                  isDisabled: false,
                  customIconHandler: nil,
                  showBottomBorder: showBottomBorder,
                  tapHandler: tapHandler,
                  tapDisableHandler: nil)
    }

    /// UDMenuAction: 初始化一个Menu选项
    /// - Parameters:
    ///   - icon: 图标
    ///   - title: 标题
    ///   - subTitle: 副标题
    ///   - hasBadge: 是否有小红点
    ///   - isDisabled: 是否禁用
    ///   - customIconHandler: 是否使用自定义图片，闭包内 ImageView 可直接使用 UDIcon 或 ByteWebImage 通过 Key 获取网络图片资源
    ///   - showBottomBorder: 是否展示下方间隔线
    ///   - tapHandler: 点击回调
    ///   - tapDisableHandler: 禁用状态下的点击回调
    public init(title: String, icon: UIImage?, subTitle: String? = nil, hasBadge: Bool, isDisabled: Bool, customIconHandler: ( (UIImageView) -> Void)? = nil, showBottomBorder: Bool, tapHandler: ( () -> Void)?, tapDisableHandler: ( () -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self.subTitle = subTitle
        self.hasBadge = hasBadge
        self.isDisabled = isDisabled
        self.customIconHandler = customIconHandler
        self.showBottomBorder = showBottomBorder
        self.tapHandler = tapHandler
        self.tapDisableHandler = tapDisableHandler
    }
}
