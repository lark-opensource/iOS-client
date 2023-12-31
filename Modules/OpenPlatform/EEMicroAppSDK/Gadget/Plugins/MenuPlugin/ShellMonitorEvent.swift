//
//  ShellMonitorEvent.swift
//  EEMicroApp
//
//  Created by 刘洋 on 2021/3/9.
//

import Foundation

/// 菜单插件内埋点上报事件名称
public final class ShellMonitorEvent {
    /// 网页应用常用应用使用
    public static let webapp_containerActions_onFavoriteClick = "Webapp_containerActions_onFavoriteClick"
    /// 小程序常用应用使用
    public static let mp_containerActions_onFavoriteClick = "mp_containerActions_onFavoriteClick"
    /// 小程序机器人使用
    public static let mp_enter_bot = "mp_enter_bot"
    /// 小程序设置插件使用
    public static let mp_settings_btn_click = "mp_settings_btn_click"
    /// 小程序主页插件使用
    public static let mp_home_btn_click = "mp_home_btn_click"
    /// 小程序debug插件关闭使用
    public static let mp_debug_close_click = "mp_debug_close_click"
    /// 小程序debug插件打开使用
    public static let mp_debug_open_click = "mp_debug_open_click"
    /// 小程序添加到桌面插件使用
    public static let mp_add_desktop_icon_click = "mp_add_desktop_icon_click"
}
