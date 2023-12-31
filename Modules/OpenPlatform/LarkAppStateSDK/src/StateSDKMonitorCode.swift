//
//  StateSDKMonitorCode.swift
//  LarkAppStateSDK
//
//  Created by  bytedance on 2020/9/28.
//

import Foundation
import ECOProbe

/// 应用机制 Monitor ID 定义
/// - 修改请先修改 [统一定义文档](https://bytedance.feishu.cn/sheets/shtcnCCboz4CUWBUtZkdmZV0PLb?sheet=ve29xQ&table=tblhdeAY8y&view=vewDYgteNU)
/// 按规范，定义的时候，变量名与message保持一致
@objcMembers
public class StateSDKMonitorCode: OPMonitorCode {
    /// 应用状态rust请求成功
    static public let app_strategy_success = StateSDKMonitorCode(code: 10_000, level: OPMonitorLevelNormal, message: "app_strategy_success")
    /// 应用状态rust sdk错误
    static public let rust_sdk_error = StateSDKMonitorCode(code: 10_001, level: OPMonitorLevelError, message: "rust_sdk_error")
    /// 数据解析出错
    static public let app_strategy_data_parse_err = StateSDKMonitorCode(code: 10_100, level: OPMonitorLevelError, message: "app_strategy_data_parse_err")
    /// 数据非法空值
    static public let app_strategy_data_null = StateSDKMonitorCode(code: 10_101, level: OPMonitorLevelError, message: "app_strategy_data_null")
    /// status非可用时tips值非法
    static public let app_strategy_data_not_match = StateSDKMonitorCode(code: 10_102, level: OPMonitorLevelError, message: "app_strategy_data_not_match")
    /// 参数异常
    static public let app_strategy_params_invalid = StateSDKMonitorCode(code: 10_103, level: OPMonitorLevelError, message: "app_strategy_params_invalid")
    /// rust请求超时
    static public let app_strategy_timeout = StateSDKMonitorCode(code: 10_104, level: OPMonitorLevelError, message: "app_strategy_timeout")
    /// 其它异常
    static public let app_strategy_other_err = StateSDKMonitorCode(code: 10_110, level: OPMonitorLevelError, message: "app_strategy_other_err")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: StateSDKMonitorCode.domain, code: code, level: level, message: message)
    }

    static public let domain = "client.open_platform.gadget.app_strategy"
}

/// 应用机制 - 监控事件
public class StateSDKMonitorEvent {
    /// 应用可用性检查引导
    static let op_app_strategy_info_check = "op_app_strategy_info_check"
}
