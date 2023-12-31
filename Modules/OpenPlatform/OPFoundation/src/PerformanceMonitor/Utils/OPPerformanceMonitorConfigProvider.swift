//
//  OPPerformanceMonitorConfigProvider.swift
//  OPFoundation
//
//  Created by liuyou on 2021/4/22.
//

import Foundation

public final class OPPerformanceMonitorConfigProvider {

    /// 获取当前已登录用户的UserID String
    public static var currentUserIDBlock: (()->String?)?
    static var currentUserID: String? {
        return currentUserIDBlock?()
    }

    /// 获取下发的远端配置
    public static var configProvider: ((String) -> [AnyHashable: Any]?)?

    static var monitorConfig: [AnyHashable: Any]? {
        return configProvider?("monitor")
    }

    /// 从埋点配置中取得性能埋点配置
    static var performanceMonitorConfig: [AnyHashable: Any]? {
        return monitorConfig.parseValue(key: "op_performance_monitor")
    }

    /// 获取当前内存泄露埋点事件的采样率
    static var objectLeakedSamplingRate: Double {
        return performanceMonitorConfig.parseValue(key: "object_leaked_sampling_rate", defaultValue: 0)
    }

    /// 获取当前内存泄漏埋点事件的采样偏移
    static var objectLeakedSamplingOffset: Double {
        return performanceMonitorConfig.parseValue(key: "object_leaked_sampling_offset", defaultValue: 0)
    }

    /// 获取当前对象数量超限检测事件的采样率
    static var objectOvercountSamplingRate: Double {
        return performanceMonitorConfig.parseValue(key: "object_overcount_sampling_rate", defaultValue: 0)
    }

    /// 获取当前对象数量超限检测事件的采样偏移
    static var objectOvercountSamplingOffset: Double {
        return performanceMonitorConfig.parseValue(key: "object_overcount_sampling_offset", defaultValue: 0)
    }

    /// 获取当前对象数量超限检测事件的采样率
    static var memoryWaveSamplingRate: Double {
        return performanceMonitorConfig.parseValue(key: "memory_wave_sampling_rate", defaultValue: 0)
    }

    /// 获取当前对象数量超限检测事件的采样偏移
    static var memoryWaveSamplingOffset: Double {
        return performanceMonitorConfig.parseValue(key: "memory_wave_sampling_offset", defaultValue: 0)
    }

    /// 开放平台性能检测工具统一Timer执行的间隔，不得为0
    static var performanceTimerInterval: TimeInterval? {
        let value: Double? = performanceMonitorConfig.parseValue(key: "performance_timer_interval")
        guard value != 0 else { return nil }
        if let value = value {
            return TimeInterval(value)
        }
        return nil
    }

    /// 小程序对象从预期销毁到真正销毁之间能够容忍的延迟，不得为0
    static var leakDestroyDelay: TimeInterval? {
        let value: Double? = performanceMonitorConfig.parseValue(key: "leak_destroy_delay")
        guard value != 0 else { return nil }
        if let value = value {
            return TimeInterval(value)
        }
        return nil
    }

    /// 内存波动的最大增量值，以MB为单位，不得为0
    static var maxMemoryIncrementNumber: Float? {
        let value: Float? = performanceMonitorConfig.parseValue(key: "max_memory_increment_number")
        guard value != 0 else { return nil }

        return value
    }

}

/// 从字典中取指定类型数据的便捷方法
fileprivate extension  Swift.Optional where Wrapped == Dictionary<AnyHashable, Any> {

    func parseValue<Result>(key: AnyHashable, defaultValue: Result) -> Result {
        return (self?[key] as? Result) ?? defaultValue
    }

    func parseValue<Result>(key: AnyHashable) -> Result? {
        return (self?[key] as? Result)
    }

}
