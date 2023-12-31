//
//  WPFGKey.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/6/11.
//

import Foundation
import LarkSetting

enum WPFGKey: String {
    /// 用于控制工作台管理功能前置需求中端侧表现
    case workflowOptimize = "lark.workplace.workflow_optimize"

    /// 应用角标开关
    case badgeOn = "gadget.open_app.badge"

    /// 工作台H5应用支持以网页多开方式打开新容器应用
    case openH5SceneInWebWay = "ipad.web.mutil.scene.workplace.enable"

    /// 工作台运营弹窗开关
    case notificationOn = "lark.workplace.notification"

    /// 是否支持工作台首页 Block 添加 Console 菜单项
    case blockConsoleOn = "openplatform.workplace.block.console"

    /// 模版化工作台 Badge 开关
    case enableTemplateBadge = "openplatform.template.badge"

    /// 是否启用模版 schema 备用 CDN 降级
    case enableTemplateBackupCDN = "lark.workplace.template.use_backup_cdn"

    /// 推荐应用支持普通用户移除
    case enableNormalUserRemoveApps = "suite.admin.appcenter.recommend_app"

    /// 是否开启预请求Block数据
    case enablePrefetchBlock = "lark.workplace.block.prefetch_data"

    /// 是否支持原生工作台预加载
    case enableNativePrefetch = "lark.open_platform.workplace.native.prefetch"

    /// 是否支持使用内存中的数据来加载工作台
    case enableUseDataFromMemory = "lark.workplace.use_data_from_memory"

    /// 启用 Native 组件下线兜底
    case enableNativeComponentFallback = "lark.workplace.native_component_fallback"

    /// 启用 Widget 组件下线兜底
    case enableWidgetComponentFallback = "lark.workplace.widget_component_fallback"

    /// 工作台xBlock 超时策略优化
    case enableBlockitTimeoutOptimize = "openplatform.blockit.timeout_optimize"

    /// 常用组件支持最近使用
    case enableRecentlyUsedApp = "lark.workplace.recentlyapp_ios"

    /// 是否切换至新用户态隔离框架
    case enableContainerUserScope = "lark.workplace.container.scope.user"

    /// 是否使用 Lark UA (业务不带UA则使用Rust默认Lark UA)
    case enableLarkUa = "lark.workplace.network_lark_ua_enable"
    
    /// 操作菜单是否支持「添加到导航栏」选项
    case enableAddAppToNavbar = "lark.workplace.add_app_to_navbar"
    
    /// H5应用/小程序导航栏 Badge 是否直接从 rust 获取
    case newOpenAppTabBadge = "lark.open_platform.new_app_tab_badge"

    /// Web 门户的 FG
    case enableWKURLSchemaHandler = "openplatform.offline.wkurlschemehandler"
    case enableSetMainNavi = "openplatform.offline.wp.setmainnavi"
    case disableLeaveConfirm = "openplatform.web.leaveconfirm.disable"
    case enableAdvancedTabEffect = "openplatform.web.workplace.advancedtabeffect.enable"

    var key: FeatureGatingManager.Key {
        FeatureGatingManager.Key(stringLiteral: rawValue)
    }
}
