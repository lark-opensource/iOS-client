//
//  FeaturePerformanceConfig.swift
//  ByteView
//
//  Created by liurundong.henry on 2021/5/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

// disable-lint: magic number
/// 根据设备性能特征管控特效开关
/// https://bytedance.feishu.cn/docs/doccnZAhbzd92uLasquowGxOxKg
public struct FeaturePerformanceConfig: Decodable {
    public let staticConfig: FeaturePerformanceStaticConfig
    public let dynamicConfig: FeaturePerformanceDynamicConfig
    public let performanceAdjust: PerformanceAdjustConfig?
    public let powerSaveConfig: PowerSaveConfig
    public let isPerformanceAdjustEnable: Bool
    /// 是否使用Lark降级框架
    public let isLarkDowngrade: Bool

    static let `default` = FeaturePerformanceConfig(staticConfig: .default, dynamicConfig: .default, performanceAdjust: nil, powerSaveConfig: .default, isPerformanceAdjustEnable: true, isLarkDowngrade: false)

    enum CodingKeys: String, CodingKey {
        case staticConfig = "static"
        case dynamicConfig = "dynamic"
        case performanceAdjust = "meetingPerformanceAdjust"
        case powerSaveConfig = "powerSaveConfig"
        case isPerformanceAdjustEnable
        case isLarkDowngrade = "isLarkDowngardeEnable"
    }
}

public extension FeaturePerformanceConfig {
    var isEffectValid: Bool {
        guard let isLow = isLowDevice else {
            return staticConfig.isEffectValid
        }
        return !isLow
    }

    var isLowDevice: Bool? {
        guard let deviceLevel = performanceAdjust?.deviceLevel else {
            return nil
        }
        return deviceLevel == "low"
    }

    var adjustConfig: FeaturePerformanceDynamicDetection {
        guard let config = performanceAdjust?.detection else {
            return dynamicConfig.userfulDetection
        }
        return config
    }

    var cpuUsageLowThreshold: Double {
        return adjustConfig.cpuUsageLowThreshold
    }

    var cpuUsageHighThreshold: Double {
        return adjustConfig.cpuUsageHighThreshold
    }

    var cpuUsageThresholds: Range<Double> {
        return adjustConfig.cpuUsageLowThreshold..<adjustConfig.cpuUsageHighThreshold
    }

    var dynamicDegradeLevels: [Int] {
        return dynamicConfig.adjustPolicy
    }
}

public struct PerformanceAdjustConfig: Decodable {
    public let deviceLevel: String
    public let detection: FeaturePerformanceDynamicDetection

    static let `default` = PerformanceAdjustConfig(deviceLevel: "unknown", detection: .default)
}

/// 性能相关配置
public struct FeaturePerformanceStaticConfig: Decodable {

    /// 特效静态检测（最低）性能配置
    public let effect: [FeaturePerformanceStaticItem]

    static let `default`: FeaturePerformanceStaticConfig = {
        let defaultPadEffectConfig = FeaturePerformanceStaticItem(deviceModelMain: 7, deviceModelSub: 1)
        let defaultPhoneEffectConfig = FeaturePerformanceStaticItem(deviceModelMain: 10, deviceModelSub: 1)
        return FeaturePerformanceStaticConfig(effect: [Display.pad ? defaultPadEffectConfig : defaultPhoneEffectConfig])
    }()

}

public extension FeaturePerformanceStaticConfig {
    var isEffectValid: Bool {
        for item in effect where item.isEffectValid {
            return true
        }
        return false
    }
}

/// 静态检测（最低）性能配置
public struct FeaturePerformanceStaticItem: Decodable {

    /// 设备主版本号，key = device_model_main
    let deviceModelMain: Int

    /// 设备次版本号，key = device_model_sub
    let deviceModelSub: Int
}

private extension FeaturePerformanceStaticItem {
     var isEffectValid: Bool {
        return DeviceUtil.modelNumber >= DeviceModelNumber(major: deviceModelMain, minor: deviceModelSub)
    }
}

public struct FeaturePerformanceDynamicConfig: Decodable {
    /// 新动态降级的降级level
    public let adjustPolicy: [Int]
    /// 特效静态检测（最低）性能配置
    public let performanceAdjustSets: [FeaturePerformanceDynamicItem]

    static let `default` = FeaturePerformanceDynamicConfig(adjustPolicy: [0], performanceAdjustSets: [.default])

    fileprivate var userfulDetection: FeaturePerformanceDynamicDetection {
        for config in performanceAdjustSets {
            if DeviceUtil.modelNumber >= DeviceModelNumber(major: config.range.min.main, minor: config.range.min.sub),
               DeviceUtil.modelNumber <= DeviceModelNumber(major: config.range.max.main, minor: config.range.max.sub) {
                return config.detection
            }
        }

        return .default
    }

    enum CodingKeys: String, CodingKey {
        case adjustPolicy = "newMeetingPerformanceAdjustPolicy"
        case performanceAdjustSets = "meetingPerformanceAdjustSets"
    }
}

public struct FeaturePerformanceDynamicItem: Decodable {
    public let range: FeaturePerformanceDynamicRange
    public let detection: FeaturePerformanceDynamicDetection

    static let `default` = FeaturePerformanceDynamicItem(range: .default, detection: .default)
}

public struct FeaturePerformanceDynamicRange: Decodable {
    let min: FeaturePerformanceDeviceModel
    let max: FeaturePerformanceDeviceModel
    // disable-lint: magic number
    static let `default`: FeaturePerformanceDynamicRange = {
        var minModel: FeaturePerformanceDeviceModel
        var maxModel: FeaturePerformanceDeviceModel

        if Display.pad {
            if DeviceUtil.modelNumber > DeviceModelNumber(major: 6, minor: 99) {
                minModel = FeaturePerformanceDeviceModel(main: 7, sub: 1)
                maxModel = FeaturePerformanceDeviceModel(main: 99, sub: 99)
            } else {
                minModel = FeaturePerformanceDeviceModel(main: 1, sub: 1)
                maxModel = FeaturePerformanceDeviceModel(main: 6, sub: 99)
            }
        } else {
            if DeviceUtil.modelNumber > DeviceModelNumber(major: 9, minor: 99) {
                minModel = FeaturePerformanceDeviceModel(main: 10, sub: 1)
                maxModel = FeaturePerformanceDeviceModel(main: 99, sub: 99)
            } else {
                minModel = FeaturePerformanceDeviceModel(main: 1, sub: 1)
                maxModel = FeaturePerformanceDeviceModel(main: 9, sub: 99)
            }
        }

        return FeaturePerformanceDynamicRange(min: minModel, max: maxModel)
    }()
    // enable-lint: magic number
}

public struct FeaturePerformanceDeviceModel: Decodable {
    public let main: Int
    public let sub: Int
}

public struct FeaturePerformanceDynamicDetection {
    /// 进房等待时间， key = entry_meeting_duration
    public let entryMeetingDuration: Int

    /// overload 时间， key = overload_duration
    public let overloadDuration: Int

    public let firstMonitorDuration: Int

    public let continueMonitorDuration: Int

    /// overload 规则，key = overload_rules
    public let overloadRules: [FeatureRule]

    /// underuse 规则，key = normal_rules
    public let normalRules: [FeatureRule]

    /// cpu 降级阈值， key = cpu_usage_low_threshold
    public let cpuUsageLowThreshold: Double

    /// cpu 升级阈值， key = cpu_usage_high_threshold
    public let cpuUsageHighThreshold: Double

    // disable-lint: magic number
    static let `default` = FeaturePerformanceDynamicDetection(entryMeetingDuration: 60,
                                                              overloadDuration: 30,
                                                              firstMonitorDuration: 300,
                                                              continueMonitorDuration: 10,
                                                              overloadRules: [.overloadDefault],
                                                              normalRules: [.normalDefault],
                                                              cpuUsageLowThreshold: FeatureRule.normalDefault.systemCpu + 0.05,
                                                              cpuUsageHighThreshold: FeatureRule.overloadDefault.systemCpu - 0.05)
    // enable-lint: magic number
}

extension FeaturePerformanceDynamicDetection: Decodable {
    enum CodingKeys: String, CodingKey {
        case entryMeetingDuration
        case overloadDuration
        case firstMonitorDuration
        case continueMonitorDuration
        case overloadRules
        case normalRules
        case cpuUsageLowThreshold
        case cpuUsageHighThreshold
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        entryMeetingDuration = try values.decode(Int.self, forKey: .entryMeetingDuration)
        overloadDuration = try values.decode(Int.self, forKey: .overloadDuration)
        firstMonitorDuration = try values.decode(Int.self, forKey: .firstMonitorDuration)
        continueMonitorDuration = try values.decode(Int.self, forKey: .continueMonitorDuration)
        overloadRules = try values.decode([FeatureRule].self, forKey: .overloadRules)
        normalRules = try values.decode([FeatureRule].self, forKey: .normalRules)
        cpuUsageLowThreshold = try values.decode(Double.self, forKey: .cpuUsageLowThreshold) / 100.0
        cpuUsageHighThreshold = try values.decode(Double.self, forKey: .cpuUsageHighThreshold) / 100.0
    }
}

public struct FeatureRule {
    /// app cpu usage, key = app_cpu
    public let appCpu: Double
    /// system cpu usage, key = system_cpu
    public let systemCpu: Double
    // disable-lint: magic number
    static let overloadDefault: FeatureRule = {
        if Display.pad {
            if DeviceUtil.modelNumber > DeviceModelNumber(major: 6, minor: 99) {
                return FeatureRule(appCpu: 0.12, systemCpu: 0.75)
            } else {
                return FeatureRule(appCpu: 0.24, systemCpu: 0.85)
            }
        } else {
            if DeviceUtil.modelNumber > DeviceModelNumber(major: 9, minor: 99) {
                return FeatureRule(appCpu: 0.06, systemCpu: 0.5)
            } else {
                return FeatureRule(appCpu: 0.2, systemCpu: 0.75)
            }
        }
    }()

    static let normalDefault: FeatureRule = {
        if Display.pad {
            if DeviceUtil.modelNumber > DeviceModelNumber(major: 6, minor: 99) {
                return FeatureRule(appCpu: 0.35, systemCpu: 0.35)
            } else {
                return FeatureRule(appCpu: 0.57, systemCpu: 0.57)
            }
        } else {
            if DeviceUtil.modelNumber > DeviceModelNumber(major: 9, minor: 99) {
                return FeatureRule(appCpu: 0.2, systemCpu: 0.2)
            } else {
                return FeatureRule(appCpu: 0.52, systemCpu: 0.52)
            }
        }
    }()
    // enable-lint: magic number
}

extension FeatureRule: Decodable {
    enum CodingKeys: String, CodingKey {
        case appCpu
        case systemCpu
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        appCpu = try values.decode(Double.self, forKey: .appCpu) / 100.0
        systemCpu = try values.decode(Double.self, forKey: .systemCpu) / 100.0
    }
}

// disable-lint: magic number
public struct PowerSaveConfig: Decodable {
    /// 节能模式降级档位
    public var degradeLevel: Int
    /// 降级电量阈值
    public var powerLowThreshold: Double
    /// 耗电速度阈值
    public var powerSpeedThreshold: Double
    /// 提示间隔 单位S
    public var tipsInterval: Int
    /// 电量降级自动关闭阈值
    public var closeThreshold: Double
    /// 检测多长时间的掉电速度
    public var powerLowMonitorMinutes: Double
    /// 日历会议结束前 x 分钟不予提示，<=0 表示不限制
    public var tipsIntervalBeforeCalendarEnd: Double
    /// 日历会议拖堂 x 分钟后进入兜底提示逻辑
    public var tipsIntervalAfterCalendarEnd: Double
    /// 日历会议拖堂时的兜底电量阈值
    public var powerLastResortThreshold: Double

    // nolint: magic number
    static let `default` = PowerSaveConfig(degradeLevel: 19,
                                           powerLowThreshold: 30,
                                           powerSpeedThreshold: 0.8,
                                           tipsInterval: 7200,
                                           closeThreshold: 40,
                                           powerLowMonitorMinutes: 5,
                                           tipsIntervalBeforeCalendarEnd: 10,
                                           tipsIntervalAfterCalendarEnd: 1,
                                           powerLastResortThreshold: 25)

    public var powerLowThresholdPercent: Double {
        powerLowThreshold / 100.0
    }

    public var powerSpeedThresholdPercent: Double {
        powerSpeedThreshold / 100.0
    }

    public var closeThresholdPercent: Double {
        closeThreshold / 100.0
    }

    public var powerLowMonitorSeconds: Double {
        powerLowMonitorMinutes * 60.0
    }

    public var powerLastResortThresholdPercent: Double {
        powerLastResortThreshold / 100.0
    }

    public var tipsIntervalBeforeCalendarEndSeconds: Double {
        tipsIntervalBeforeCalendarEnd * 60.0
    }

    public var tipsIntervalAfterCalendarEndSeconds: Double {
        tipsIntervalAfterCalendarEnd * 60.0
    }
}
// enable-lint: magic number

public struct LarkDowngradeConfig: Decodable {
    public let enableDowngrade: Bool

    static let `default` = LarkDowngradeConfig(enableDowngrade: false)
}
