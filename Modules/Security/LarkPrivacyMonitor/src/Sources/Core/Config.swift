//
//  Config.swift
//  LarkPrivacyMonitor
//
//  Created by Hao Wang on 2023/3/1.
//

import Foundation

public protocol Config {
    /// Monitor SDK 初始化配置
    func settings() -> [String: Any]?
}

/// 使用Monitor的相关配置
public protocol MonitorConfig: Config {
    /// 策略引擎配置
    func ruleEngineConfig() -> [String: Any]?
    /// 策略规则配置
    func ruleStrategies() -> [String: Any]?
}

/// 频控的相关配置（降级策略）
/// 比如 1秒（timeThreshold）内调用超过10次（countThreshold）则触发频控降级
public protocol FrequencyConfig {
    /// 是否开启频控降级能力，默认true
    func enabled() -> Bool
    /// 时间阈值
    func timeThreshold() -> Int
    /// 次数阈值
    func countThreshold() -> Int
}

/// 频控的相关配置（管控策略）
public protocol FrequencyRuleConfig {
    func ruleConfigs() -> [[String: Any]]
}

/// 日志功能的相关配置
public protocol LogConfig {
    /// 是否开启日志能力，默认true
    func enabled() -> Bool
}
