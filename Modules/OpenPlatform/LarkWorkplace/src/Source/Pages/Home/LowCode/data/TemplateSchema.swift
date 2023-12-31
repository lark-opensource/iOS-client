//
//  TemplateSchema.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/4/1.
//

import Foundation
import SwiftyJSON
import LarkUIKit

// ⚠️ 重构字段结构，放在struct里
// swiftlint:disable identifier_name
/// 组件ID
let ComponentIdKey: String = "id"
/// 组件名
let ComponentNameKey: String = "componentName"
/// 组件属性
let PropsKey: String = "props"
/// 组件样式
let StylesKey: String = "styles"
/// 子节点
let ChildrenKey: String = "children"

/// 组件标题
let ComponentTitle: String = "title"

/// 组件宽度
let ComponentWidth: String = "width"
/// 组件高度
let ComponentHeight: String = "height"

/// 填满父布局
let FillParent: String = "fill_parent"
/// 包裹内容（由子内容撑开）
let WrapContent: String = "wrap_content"

/// 列表布局 - loading、loadFailed状态示意图高度
let listLayoutStateTipHeight: CGFloat = 200

/// 页面配置的的组件名（为方便PC端，弄成了组件）
let PageConfig: String = "Header"

/// *******************
// MARK: 通用props
/// *******************
/// 是否展示背景
let ShowBackground: String = "showBackground"
/// 是否展示Header
let ShowHeader: String = "showHeader"
/// 标题取值键
let TitleKey: String = "title"
/// ⚠️ 我的常用 header title
/// 因为5.13及以下版本中，我的常用 header title 会解析 props.title 作为 extraComponents，并且会据此判断是否设置「外置标题」，
/// 但是 我的常用 组件的 title 并非「外置标题」（这里存在历史遗留问题，上下文已丢失），这个「外置标题」逻辑会为我的常用
/// 多添加一个 header（这个bug在5.14+被修复）；为了兼容这个问题，对「我的常用」header title 字段进行特化处理。
let CommonTitleKey: String = "mTitle"
/// 操作菜单选项
let MenuItemsKey: String = "menuItems"
/// 标题图标取值键
let TitleIconKey: String = "titleIconUrl"
/// 操作选项的名字
let ActionNameKey: String = "name"
/// 操作选项的iconUrl
let ActionIconUrlKey: String = "iconUrl"
/// 操作选项的跳转链接
let ActionSchemaKey: String = "schema"
/// 操作选项的key
let ActionKeyKey: String = "key"

/// *******************
// MARK: 通用styles
/// *******************
/// 背景颜色
let BackgroundColor: String = "backgroundColor"
/// 背景圆角
let BackgroundRadius: String = "backgroundRadius"
/// 上间距
let MarginTop: String = "marginTop"
/// 下间距
let MarginBottom: String = "marginBottom"
/// 左间距
let MarginLeft: String = "marginLeft"
/// 右间距
let MarginRight: String = "marginRight"

/// 默认通用横向间距
let horizontalMargin: Int = 16
/// 默认通用纵向间距
let verticalMargin: Int = 12

/// *******************
///     常用组件
/// *******************

let favoriteModuleHeaderBottomGap = 16
let favoriteModuleHeaderTopGap = 8
let favoriteModuleHeaderHeight = 42

/// 常用单模块-标题布局参数
let favoriteSingleModuleHeaderTopMargin = favoriteModuleHeaderTopGap - favoriteSingleModuleHeaderTopPadding
let favoriteSingleModuleHeaderTopPadding = 7
let favoriteSingleModuleHeaderHeight = 28
let favoriteSingleModuleHeaderBottomPadding = 7
let favoriteSingleModuleHeaderBottomMargin = favoriteModuleHeaderBottomGap - favoriteSingleModuleHeaderBottomPadding

/// 常用多模块-标题布局参数
let favoriteMultiModuleHeaderTopMargin = favoriteModuleHeaderTopGap - favoriteMultiModuleHeaderTopPadding
let favoriteMultiModuleHeaderTopPadding = 0
let favoriteMultiModuleHeaderHeight = 42
let favoriteMultiModuleHeaderBottomPadding = 0
let favoriteMultiModuleHeaderBottomMargin = favoriteModuleHeaderBottomGap - favoriteMultiModuleHeaderBottomPadding

/// 常用副标题布局参数
let favoriteTipsTopPadding = -4
let favoriteTipsHeight = 22
let favoriteTipsBottomPadding = 12

/// *******************
///     页面配置信息
/// *******************
/// 是否展示title的字段
let ShowTitle: String = "showTitle"

/// *******************
///     应用列表组件
/// *******************
/// 展示模式（上图下文，左图右文）
let DisplayMode: String = "displayMode"
/// 标题是否内置
let IsInnerTitle: String = "isTitleInside"

/// 应用列表内部纵向间距（上图下文）
let appListItemInnerVGap: CGFloat = 8.0
/// 双行文案的高度
let doubleLineTextHeight: CGFloat = 36.0
/// 内置标题高度
let commonInnerTitleHeight: CGFloat = 44.0
/// 外置标题高度
let commonOutterTitleHeight: CGFloat = 28.0
/// 外置标题间距
let commonOutterTitleGap: CGFloat = 12.0

/// 组件默认高度
let cardDefaultHeight: CGFloat = 72

/// Block默认高度
let blockDefaultHeight: CGFloat = 150.0
/// block之间的纵向间距
let blockToBlockInset: CGFloat = 24.0
/// block到icon应用的纵向间距
let blockToIconInset: CGFloat = 12.0
/// icon应用框标准宽度
let commonAppContainerWidth: CGFloat = Display.pad ? 76.0 : 84.0
/// icon应用横向间距
let commonAppHorizontalPadding: CGFloat = Display.pad ? 2.0 : 12.0
// swiftlint:enable identifier_name
