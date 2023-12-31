//
//  AppreciableDefines.swift
//  ByteViewTracker
//
//  Created by kiri on 2021/12/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 一级分类：通用可感知事件
/// - es数据库里的service
/// - path: SlardarEvent.name
public enum AppreciableType: String, Hashable {
    /// 基础性能
    case vc_basic_performance
    /// 可感知错误
    case vc_appreciable_error
    /// 会中监控，5s 时间间隔
    case vc_inmeet_perf_monitor
    /// 主端可感知耗时，一级分类为appreciable_loading_time
    /// case lark
}

/// 二级分类: 可感知错误
/// - service: vc_appreciable_error
/// - path: SlardarEvent.extra.event
public enum AppreciableError: String, Hashable {
    /// RTC错误
    case vc_perf_rtc_error
    /// 短链请求失败
    case vc_perf_http_error
    /// 视频流订阅超时
    case vc_perf_rtc_sub_timeout
    /// 单日第三方请求失败数，例如EffectPlatform资源下载失败
    case vc_perf_third_http_error
    /// Lynx相关错误
    case vc_lynx_error
}

/// 二级分类: 基础性能
/// - service: vc_basic_performance/vc_inmeet_perf_monitor
/// - path: SlardarEvent.extra.event
public enum AppreciableEvent: String, Hashable {
    /// 耗电量
    case vc_perf_power_consume
    /// 实时电量
    case vc_perf_power_realtime
    /// 温度状态
    case vc_perf_thermal_state
    /// MemoryPressure警告
    case vc_perf_memory_pressure
    /// 音频路由切换耗时
    case vc_change_audio_route_time
    /// tab列表下拉耗时
    case vc_tab_pull_time
    /// tab列表上拉耗时
    case vc_tab_load_more_time
    /// 超声波识别
    case vc_ultrawave_recognize
    /// 会前性能测量
    case vc_metric_before_meeting
    /// 会中性能测量
    case vc_metric_in_meeting
    /// 会后性能测量
    case vc_metric_after_meeting
    /// 日志打印
    case vc_log_frequency_monitor
    /// 参会人获取参会人信息后到展示所用时间
    case vc_participant_model_to_display_cost
    /// MagicShare进入一个新页面时的性能测量
    case vc_magic_share_pagenum_mem_dev
    /// 大小窗耗时
    case vc_floating_switch_time
}
