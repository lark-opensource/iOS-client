//
//  OPMonitorDefine.swift
//  LarkOPInterface
//
//  Created by yinyuan on 2020/5/22.
//

import Foundation

@objcMembers
public final class OPMonitorEventKey: NSObject {
    public static let trace_id = "trace_id"                             // 用于tracing追踪
    public static let error_code = "error_code"                         // 业务错误码
    public static let error_msg = "error_msg"                           // 业务错误信息
    public static let error_domain = "error_domain"                     // 业务错误的 domain
    public static let error_user_info = "error_user_info"               // 业务错误的 user_info
    public static let time = "time"                                     // 埋点时间戳(ms)
    public static let duration = "duration"                             // 耗时信息(ms)
    public static let monitor_level = "monitor_level"                   // monitor code 的 level
    public static let monitor_domain = "monitor_domain"                 // monitor code 的 domain
    public static let monitor_code = "monitor_code"                     // monitor code 的 code
    public static let monitor_id = "monitor_id"                         // monitor code 的 id
    public static let monitor_message = "monitor_message"               // monitor code 的 message
    public static let monitor_tags = "monitor_tags"                     // monitor tag 列表信息
    public static let monitor_file = "monitor_file"                     // monitor 埋点时文件名
    public static let monitor_function = "monitor_function"             // monitor 埋点时方法名
    public static let monitor_line = "monitor_line"                     // monitor 埋点时行号
    public static let result_type = "result_type"                       // 结果
    public static let ope_monitor_level = "ope_monitor_level"           // OPerror monitor code 的 level
    public static let ope_monitor_domain = "ope_monitor_domain"         // OPerror monitor code 的 domain
    public static let ope_monitor_code = "ope_monitor_code"             // OPerror monitor code 的 code
    public static let ope_monitor_message = "ope_monitor_message"       // OPerror monitor code 的 message
}

@objcMembers
public final class OPMonitorEventValue: NSObject {
    public static let success = "success"
    public static let fail = "fail"
    public static let cancel = "cancel"
    public static let timeout = "timeout"
}

@objcMembers
public final class OPMonitorConstants: NSObject {
    public static let tag_separator = ","
    public static let default_report_name = "op_monitor_event"
    public static let default_log_tag = "op_monitor"
    public static let event_name = "event_name"
    /// Passport 实时日志和遗留埋点上报 service
    public static let default_passport_report_name = "passport_monitor_event"
    /// Passport 当前埋点上报 service
    public static let passport_watcher_name = "passport_watcher_event"
}

@objcMembers
public final class OPMonitorSerializeKeys: NSObject {
    public static let key_event_name = "name"
    public static let key_categories = "categories"
    public static let key_metrics = "metrics"
}


@objcMembers
public final class OPMonitorRedundantDataKeys: NSObject {
    public static let safe_delete_keys = ["user_id", "tenant_id"]
}
