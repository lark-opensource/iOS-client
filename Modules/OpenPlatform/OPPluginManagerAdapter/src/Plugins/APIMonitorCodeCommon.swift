//
//  APIMonitorCodeCommon.swift
//  OPPluginManagerAdapter
//
//  Created by baojianjun on 2023/8/15.
//

import Foundation
import ECOProbe

@objcMembers
public final class APIMonitorCodeCommon: OPMonitorCode {

    /// native收到js api调用
    public static let native_receive_invoke = APIMonitorCodeCommon(code: 10002, level: OPMonitorLevelNormal, message: "native_receive_invoke")

    /// native回调js
    public static let native_callback_invoke = APIMonitorCodeCommon(code: 10003, level: OPMonitorLevelNormal, message: "native_callback_invoke")

    /// native开始派发执行api
    public static let native_invoke_start = APIMonitorCodeCommon(code: 10004, level: OPMonitorLevelNormal, message: "native_invoke_start")

    /// native完成API执行
    public static let native_invoke_result = APIMonitorCodeCommon(code: 10005, level: OPMonitorLevelNormal, message: "native_invoke_result")

    /// native使用PM派发执行api
    public static let native_pm_invoke_start = APIMonitorCodeCommon(code: 10006, level: OPMonitorLevelNormal, message: "native_pm_invoke_start")

    /// native PM完成api执行
    public static let native_pm_invoke_result = APIMonitorCodeCommon(code: 10007, level: OPMonitorLevelNormal, message: "native_pm_invoke_result")

    /// native执行前 进入了后台
    public static let native_invoke_enter_background = APIMonitorCodeCommon(code: 10009, level: OPMonitorLevelNormal, message: "native_invoke_enter_background")

    /// native执行前 从后台回到前台
    public static let native_invoke_back_foreground = APIMonitorCodeCommon(code: 10010, level: OPMonitorLevelNormal, message: "native_invoke_back_foreground")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: APIMonitorCodeCommon.domain, code: code, level: level, message: message)
    }
    public static let domain = "client.open_platform.api.common"
}
