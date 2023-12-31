//
//  WPBizEvent.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/6/6.
//

import UIKit
import LKCommonsLogging
import LarkWorkplaceModel

/// 模板化工作台业务埋点事件
// swiftlint:disable identifier_name
enum WPNewEvent: String {
    var eventName: String {
        return rawValue
    }
    /// 打开工作台（新）
    case openplatformWorkspaceMainPageView = "openplatform_workspace_main_page_view"
    /// 模板化工作台-所有的内容点击事件
    @available(*, deprecated, message: "use WorkplaceTrackEvetName")
    case openplatformWorkspaceMainPageClick = "openplatform_workspace_main_page_click"
    /// 模板化工作台-所有内容的渲染曝光
    @available(*, deprecated, message: "use WorkplaceTrackEvetName")
    case openplatformWorkspaceMainPageComponentExpoView = "openplatform_workspace_main_page_component_expo_view"
    /// 模板化工作台-跳转内部页面
    case openplatformWorkspaceInternalPageView = "openplatform_workspace_internal_page_view"
    /// 模板化工作台-点击右上角设置，进入设置页面
    case openplatformWorkspaceSettingPageView = "openplatform_workspace_setting_page_view"
    /// 工作台设置页点击
    case openplatformWorkspaceSettingPageClick = "openplatform_workspace_setting_page_click"

    /// 工作台停留时长上报
    case openplatformWorkspaceMonitorReportView = "openplatform_workspace_monitor_report_view"
    /// 「我的常用」拖动排序
    case openplatformWorkspaceMainPageSortClick = "openplatform_workspace_main_page_sort_click"
    /// Block 分享
    case shareBlock = "openplatform_workspace_block_share_chat_click"
}

/// 新版埋点上报的Key
enum WPEventNewKey: String {
    /// 点击事件
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.click")
    case click = "click"
    /// 渲染事件
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.view")
    case view = "view"
    /// 跳转目标
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.target")
    case target = "target"
    /// 组件类型
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.type")
    case type = "type"
    /// 组件具体类型（native、block）
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.sub_type")
    case sub_type = "sub_type"
    /// 应用Id
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.application_id")
    case applicationId = "application_id"
    /// 应用名称
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.app_name")
    case appName = "app_name"
    /// Block模式类型（标准 & 非标准）
    case blockMode = "mode"
    /// 操作菜单数量
    case menuCount = "menu_count"
    /// 工作台类型（template=模板化，old=老工作台）
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.host")
    case host = "host"
    /// 「我的常用」状态：编辑态、默认态
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.status")
    case commonAndRecommandStatus = "status"
    /// 链接id
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.link_id")
    case linkId = "link_id"
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.template_id")
    case templateId = "template_id"
    /// 是否来自我的常用组件
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.if_my_common")
    case isInFavoriteComponent = "if_my_common"
    /// Block 菜单项类型
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.menu_type")
    case blockMenuType = "menu_type"
    /// IM 会话 ID
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.chat_id")
    case chatId = "chat_id"
    /// 转发到私聊的数量
    case personalChatCount = "personal_chat_cnt"
    /// App ID
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.app_id")
    case appId = "app_id"
    /// Block ID
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.block_id")
    case blockId = "block_id"
    /// Block Type ID
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.block_type_id")
    case blockTypeId = "block_type_id"
}

/// 上报跳转的value
@available(*, deprecated, message: "use WorkplaceTrackTargetValue")
enum WPTargetValue: String {
    /// 无
    case none = "none"
    /// 内部页面
    case inner_page = "openplatform_workspace_internal_page_view"
    /// 设置页
    case setting_page = "openplatform_workspace_setting_page_view"
    /// 应用目录
    case app_menu = "openplatform_ecosystem_application_menu_view"
    /// 添加页面
    case add_page = "openplatform_workspace_add_app_page_view"
    /// block 编辑
    case openplatform_workspace_editor_applist_view = "openplatform_workspace_editor_applist_view"
}

/// 点击对象的上报value
@available(*, deprecated, message: "use WorkplaceTrackClickValue")
enum WPClickValue: String {
    /// 应用
    case application
    /// Block 标题
    case blockTitle = "block_name"
    /// Block 标题栏操作按钮
    case more
    /// 链接（应用列表中用户配置的link）
    case link
    /// 大搜
    case search
    /// 应用目录
    case appdirectory
    /// 自定义按钮
    case selfDefined = "self-defined"
    /// 设置
    case setting
    /// 添加应用
    case add_app = "add_app"
    /// Block
    case block
    /// Block菜单项点击
    case blockMenuItem = "block_menu_item"
    /// Icon 应用菜单项
    case iconMenuItem = "icon_menu_item"
    /// icon 链接菜单项
    case linkMenuItem = "link_menu_item"
    /// Icon 首页管理点击减号删除
    case remove
    /// 管理常用
    case management
    /// 常用组件/应用拖动排序
    case sort
    /// Block菜单->设置
    case mainBlockContent = "main_block_content"
    /// 点击最近使用 Tab
    case recentlyUsedTab = "recent_use_tab"
    /// Block 分享
    case send
}

/// 曝光的 UI 类型
@available(*, deprecated, message: "use WorkplaceTrackExposeUIType")
enum WPExposeUIType: String {
    /// 顶部导航栏
    case header = "header"
    /// 我的常用子模块
    case commom_and_recommend = "my_common_and_recommend"
    /// 最近使用子模块
    case recentlyUsed = "recent_use"
    /// Block
    case block = "block"
    /// Block 菜单
    case blockMenu = "block_menu"
    /// Icon 形态的 App 长按菜单
    case appMenu = "app_menu"
    /// 应用分组（仅原生工作台）
    case appGroups = "app_groups"
    /// 全部应用 （仅原生工作台）
    case allApps = "all_apps"
}

// swiftlint:ensable identifier_name

// swiftlint:disable redundant_string_enum_value
/// 组件实现类型的上报value
@available(*, deprecated, message: "use WorkplaceTrackSubType")
enum WPSubTypeValue: String {
    /// 原生
    case native = "native"
    /// block
    case block = "block"
}

/// 模板化工作台加载性能Key
enum TmplPerformanceKey: String {
    /// 是否使用缓存
    case useCache = "use_cache"
    /// 中转页耗时
    case router = "router"
    /// 基础环境初始化完成
    case initEnv = "init_env"
    /// 工作台业务数据获取完成
    case requestData = "request_data"
    /// 首屏Block加载完成
    case firstFrameBlockShow = "first_frame_block_show"
    /// 初始化blockKit（移动端上报0）
    case initBlockKit = "init_blockit"
    /// 所有block展示（移动端上报0）
    case allBlockShow = "all_block_show"
}
// swiftlint:enable redundant_string_enum_value

/// 模板化工作台相关
extension WPEventReport {
    /// 上报添加小程序应用信息
    @discardableResult
    func setAppInfo(item: WPAppItem, appScene: WPTemplateModule.ComponentDetail.Favorite.AppSubType?) -> WPEventReport {
        set(key: "application_id", value: item.appId)
        set(key: "app_name", value: item.name)
        if let appScene {
            // 仅支持判断常用、推荐，其他均认为是other
            if appScene == .common || appScene == .recommend {
                set(key: "app_scene", value: appScene.rawValue)
            } else {
                set(key: "app_scene", value: "other")
            }
        }
        let appType: String
        // 依次判断是否MP，H5，BOT
        if let appId = item.appId, !appId.isEmpty {
            appType = "MP"
        } else if let h5Url = item.url?.mobileWebURL, !h5Url.isEmpty {
            appType = "H5"
        } else if let botId = item.botId, !botId.isEmpty {
            appType = "BOT"
        } else {
            appType = "none"
        }
        return set(key: "app_type", value: appType)
    }
}
