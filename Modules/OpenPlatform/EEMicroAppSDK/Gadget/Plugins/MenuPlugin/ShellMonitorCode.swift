//
//  ShellMonitorCode.swift
//  EEMicroApp
//
//  Created by 刘洋 on 2021/3/9.
//

import Foundation
import LarkOPInterface
import OPSDK

/// 定义菜单插件内埋点code
public final class ShellMonitorCode: OPMonitorCode {

    /// 添加常用应用失败
    public static let add_common_app_error = ShellMonitorCode(code: 10_003, level: OPMonitorLevelError, message: "add_common_app_error")
    /// 移除常用应用失败
    public static let remove_common_app_error = ShellMonitorCode(code: 10_004, level: OPMonitorLevelError, message: "remove_common_app_error")
    /// 添加常用应用成功
    public static let add_common_app_success = ShellMonitorCode(code: 10_005, level: OPMonitorLevelNormal, message: "add_common_app_success")
    /// 移除常用应用成功
    public static let remove_common_app_success = ShellMonitorCode(code: 10_006, level: OPMonitorLevelNormal, message: "remove_common_app_success")
    /// 小程序打开机器人成功
    public static let mp_open_bot_success = ShellMonitorCode(code: 10_007, level: OPMonitorLevelNormal, message: "mp_open_bot_success")
    /// 小程序打开机器人失败
    public static let mp_open_bot_error = ShellMonitorCode(code: 10_008, level: OPMonitorLevelError, message: "mp_open_bot_error")

    /// 成功打开设置页面
    public static let open_settings_success = ShellMonitorCode(code: 10_009, level: OPMonitorLevelNormal, message: "open_settings_success")

    /// 成功返回主页
    public static let back_home_success = ShellMonitorCode(code: 10_010, level: OPMonitorLevelNormal, message: "back_home_success")

    /// 成功关闭小程序Debug
    public static let mp_debug_close_success = ShellMonitorCode(code: 10_011, level: OPMonitorLevelNormal, message: "mp_debug_close_success")

    /// 成功打开小程序Debug
    public static let mp_debug_open_success = ShellMonitorCode(code: 10_012, level: OPMonitorLevelNormal, message: "mp_debug_open_success")
    
    /// 点击添加到桌面按钮
    public static let mp_add_desktop_icon_click = ShellMonitorCode(code: 10_013, level: OPMonitorLevelNormal, message: "mp_add_desktop_icon_click")


    private init(code: Int, level: OPMonitorLevel = OPMonitorLevelNormal, message: String) {
        super.init(domain: ShellMonitorCode.domain, code: code, level: level, message: message)
    }

    static let domain = "client.open_platform.common.shell"
}
