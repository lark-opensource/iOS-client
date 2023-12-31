//
//  OPMonitorServiceRemoteConfig.swift
//  LarkOPInterface
//
//  Created by yinyuan on 2020/5/26.
//

import Foundation

/// 远端配置，用于采样率控制等
@objcMembers
public final class OPMonitorServiceRemoteConfig: NSObject {

    /// 默认采样率
    private var sampleRate: Float = 1
    /// 默认 trace 级别采样率
    private var traceSampleRate: Float = 0
    /// 默认 normal 级别采样率
    private var normalSampleRate: Float = 1
    /// 默认 warn 级别采样率
    private var warnSampleRate: Float = 1
    /// 默认 error 级别采样率
    private var errorSampleRate: Float = 1
    /// 默认 fatal 级别采样率
    private var fatalSampleRate: Float = 1

    /// 优先级从大到小排序的规则列表
    private var orderedRules: [OPMonitorRule] = []

    /// 构建配置，可重复调用
    public func buildConfig(config: [String: Any]?) {
        guard let config = config else {
            // 规则格式不正确
            return
        }

        // 默认采样率
        self.sampleRate = config["sample_rate"] as? Float ?? self.sampleRate
        self.traceSampleRate = config["trace_sample_rate"] as? Float ?? self.traceSampleRate
        self.normalSampleRate = config["normal_sample_rate"] as? Float ?? self.normalSampleRate
        self.warnSampleRate = config["warn_sample_rate"] as? Float ?? self.warnSampleRate
        self.errorSampleRate = config["error_sample_rate"] as? Float ?? self.errorSampleRate
        self.fatalSampleRate = config["fatal_sample_rate"] as? Float ?? self.fatalSampleRate

        guard let rules = config["rules"] as? [[String: Any]] else {
            // 规则解析失败
            return
        }

        // 解析建立优先级从大到小排序的规则列表
        var orderedRules = rules.map { (rule) -> OPMonitorRule in
            OPMonitorRule(rawValue: rule)
        }

        orderedRules = orderedRules.sorted(by: { (rule, rule1) -> Bool in
            rule.priority > rule1.priority
        })

        objc_sync_enter(self)
        self.orderedRules = orderedRules
        objc_sync_exit(self)

        // 建立 index 优化匹配性能
        // 待实现
    }

    /// 获取 data 数据采样率
    public func sampleRate(data: [String: Any]) -> Float {

        // 默认采样率
        var sampleRate = self.sampleRate
        if let level = data[OPMonitorEventKey.monitor_level] as? UInt {
            switch OPMonitorLevel(rawValue: level) {
            case .trace:
                sampleRate = self.traceSampleRate
                break
            case .normal:
                sampleRate = self.normalSampleRate
                break
            case .warn:
                sampleRate = self.warnSampleRate
                break
            case .error:
                sampleRate = self.errorSampleRate
                break
            case .fatal:
                sampleRate = self.fatalSampleRate
                break
            default:
                break
            }
        }

        objc_sync_enter(self)
        // 尝试从 rule 中取采样率（如果有）
        if let rule = matchedRule(data: data), let ruleSampleRate = rule.sampleRate {
            sampleRate = ruleSampleRate
        }
        objc_sync_exit(self)

        // 目前只支持 1/0两个值(后续将支持浮点采样率)
        return sampleRate >= 1 ? 1 : 0
    }

    /// 寻找优先级最高的匹配规则
    private func matchedRule(data: [String: Any]) -> OPMonitorRule? {
        return self.orderedRules.first { (rule) -> Bool in
            rule.match(data: data)
        }
    }
}
