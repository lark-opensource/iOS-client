//
//  WorkplaceTrackEventName.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/10.
//

import Foundation

/// 埋点业务名。
///
/// 所有的业务埋点名应当在此处定义，不允许裸写字符串定义。
///
/// 最佳实践：
/// * 我们认为 key 需要做到尽可能的复用，除非有特殊情况，否则枚举命名应当和原始字段严格一致，不要使用别名。
enum WorkplaceTrackEventName: String {
    /// 在工作台弹窗曝光提示更新
    case openplatform_workspace_main_page_update_view
    /// 在工作台提示更新的弹窗上点击
    case openplatform_workspace_main_page_update_click
    /// 原生工作台渲染是否成功
    case appcenter_rendering
    /// widget应用曝光
    case appcenter_widgetopen
    /// 「我的常用」拖动排序
    case openplatform_workspace_main_page_sort_click
    /// 工作台点击添加应用icon
    case appcenter_click_addapps
    /// 通过顶部导航栏应用目录按钮进入应用目录（新埋点）
    case openplatform_ecosystem_workspace_mainpage_click
    /// 点击顶部导航设置
    case appcenter_click_settings

    /// 应用长按菜单触发
    case appcenter_set_more
    /// 应用设置菜单“取消常用”点击
    case appcenter_set_cancel_commonuse
    /// 应用设置菜单“设置常用”点击
    case appcenter_set_commonuse
    /// 应用设置菜单“排序”点击
    case appcenter_set_order

    /// 工作台点击长按菜单选项
    case openplatform_workspace_appcard_action_menu_click
    /// 工作台打开长按菜单
    case openplatform_workspace_appcard_action_menu_view

    /// 模板化工作台-所有的内容点击事件
    case openplatform_workspace_main_page_click
    /// 模板化工作台-所有内容的渲染曝光
    case openplatform_workspace_main_page_component_expo_view

    /// 点击打开运营位
    case appcenter_operation_open
    /// 工作台运营位曝光
    case appcenter_operation_exposure
    /// 运营位“一键安装应用弹窗”点击安装
    case appcenter_operation_installapp_install
    /// 运营位“一键安装应用弹窗”点击关闭
    case appcenter_operation_installapp_skip
    /// 运营位“一键安装应用弹窗”点击查看详情
    case appcenter_operation_installapp_viewdetail

    /// onboarding一键安装应用弹窗安装成功应用
    case appcenter_onboardinginstall_installsuccessed
    /// onboarding一键安装应用弹窗曝光
    case appcenter_onboardinginstall_exposure
    /// onboarding一键安装应用弹窗点击安装
    case appcenter_onboardinginstall_istall
    /// 运营位“一键安装应用弹窗”弹窗安装成功应用
    case appcenter_operation_installapp_installsuccessed
    /// onboarding一键安装应用弹窗点击查看详情
    case appcenter_onboardinginstall_viewdetail
    /// onboarding一键安装应用弹窗点击跳过
    case appcenter_onboardinginstall_skip
    /// 在工作台界面，应用菜单页的展示
    case openplatform_workspace_icon_menu_item_view
    /// 「管理」气泡卡片曝光
    case openplatform_workspace_manage_onboarding_view
    /// 「管理」气泡卡片点击
    case openplatform_workspace_manage_onboarding_click
    /// 工作台应用曝光
    case openplatform_workspace_application_view
}
