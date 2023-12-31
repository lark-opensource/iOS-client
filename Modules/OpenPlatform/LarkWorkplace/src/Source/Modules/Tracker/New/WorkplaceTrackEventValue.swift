//
//  WorkplaceTrackEventValue.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/29.
//

import Foundation

/// 最佳实践:
/// * 一般情况下对于在多处使用且 Value 为枚举类型的，建议在此处定义完整枚举。
/// * 类似的，我们认为 Key,Value 需要做到尽可能的复用，除非有特殊情况，否则枚举命名应当和原始字段严格一致，不要使用别名。
/// * 类型命名规范: 使用 WorkplaceTrack 前缀。

/// 跳转页面取值
enum WorkplaceTrackTargetValue: String {
    /// 无
    case `none`
    /// 内部页面
    case openplatform_workspace_internal_page_view
    /// 设置页
    case openplatform_workspace_setting_page_view
    /// 应用目录
    case openplatform_ecosystem_application_menu_view
    /// 添加页面
    case openplatform_workspace_add_app_page_view
    /// block 编辑
    case openplatform_workspace_editor_applist_view
    /// 应用分享
    case openplatform_application_share_view
    /// 切工作台tab
    case openplatform_workspace_main_page_view
    /// 角标管理
    case badge_management
}

/// 点击对象取值
enum WorkplaceTrackClickValue: String {
    /// 应用
    case application
    /// block 标题
    case block_name
    /// block 标题栏操作
    case more
    /// 链接
    case link
    /// 大搜
    case search
    /// 应用目录
    case appdirectory
    /// 自定义按钮
    case self_defined = "self-defined"
    /// 设置
    case setting
    /// 添加应用
    case add_app
    /// block
    case block
    /// block 菜单项点击
    case block_menu_item
    /// icon 应用菜单
    case icon_menu_item
    /// icon 链接菜单
    case link_menu_item
    /// icon 首页管理点击减号删除
    case remove
    /// 管理常用
    case management
    /// 常用组件/应用拖动排序
    case sort
    /// block菜单->设置
    case main_block_content
    /// 点击最近使用 tab
    case recent_use_tab
    /// block 分享
    case send
    /// 应用目录
    case openplatform_application_get
    /// 应用分享
    case app_share

    /// 立即更新
    case update_now
    /// 下次更新
    case update_next_time
    /// 切工作台tab
    case tab
    /// 「管理」气泡卡片点击关闭
    case close
}

/// 曝光 UI 类型
enum WorkplaceTrackExposeUIType: String {
    /// 顶部导航栏
    case header
    /// 我的常用子模块
    case my_common_and_recommend
    /// 最近使用子模块
    case recent_use
    /// block
    case block
    /// block 菜单
    case block_menu
    /// icon 形态的 app 长按菜单
    case app_menu
    /// 应用分组（仅原生工作台）
    case app_groups
    /// 全部应用（仅原生工作台）
    case all_apps
}

/// 组件菜单类型
enum WorkplaceTrackMenuType: String {
    case remove
    case share
    case sort
    case custom
    case blockSetting
    case add_to_navigation
    /// 角标管理
    case badge_management
}

enum WorkplaceTrackHostType: String {
    /// 原生工作台
    case old
    /// 模版工作台
    case template
}

/// 组件实现类型的上报value
enum WorkplaceTrackSubType: String {
    /// 原生
    case native
    /// block
    case block
}

/// 「我的常用」状态
enum WorkplaceTrackFavoriteStatus: String {
    /// 默认态
    case `default`
    /// 编辑态
    case edit
}

/// 「我的常用」拖拽状态
enum WorkplaceTrackFavoriteDragType: String {
    case icon
    case block
}

/// 「我的常用」移除 item 类型
enum WorkplaceTrackFavoriteRemoveType: String {
    case icon
    case block
    case link
}
