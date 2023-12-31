//
//  VoiceModeConfig.swift
//  ByteView
//
//  Created by ZhangJi on 2022/6/6.
//

import Foundation

public struct VoiceModeConfig {
    public let batteryValue: Double
    public let actionInterval: Int
    public let thermalState: ThermalStateConfig
    public let thermalAdjustConfig: ThermalAdjustConfig

    static let `default` = VoiceModeConfig(batteryValue: 0.3, actionInterval: 7200, thermalState: .default, thermalAdjustConfig: .default)
}

extension VoiceModeConfig: Decodable {
    enum CodingKeys: String, CodingKey {
        case batteryValue
        case actionInterval
        case thermalState
        case thermalAdjustConfig
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        batteryValue = try values.decode(Double.self, forKey: .batteryValue) / 100.0
        actionInterval = try values.decode(Int.self, forKey: .actionInterval)
        thermalState = try values.decode(ThermalStateConfig.self, forKey: .thermalState)
        thermalAdjustConfig = try values.decode(ThermalAdjustConfig.self, forKey: .thermalAdjustConfig)
    }
}

/// 温度状态配置
public struct ThermalStateConfig: Decodable {
    public let serious: Int
    public let critical: Int
    public let seriousInterval: Int
    public let criticalInterval: Int

    // nolint-next-line: magic number
    static let `default` = ThermalStateConfig(serious: 600, critical: 0, seriousInterval: 1200, criticalInterval: 300)
}

public struct ThermalAdjustConfig: Decodable {
    public let isThermalAdjustEnable: Bool
    public let degradeToastInterval: Int
    public let degradeToastShowDuration: Int
    public let voiceModeToastInterval: Int
    public let voiceModeToastShowDuration: Int
    public let scheduledCheckDuration: Int
    public let seriousDegradeConfig: DegradeConfig
    public let criticalDegradeConfig: DegradeConfig
    public let upgradeConfig: UpgradeConfig

    // nolint: magic number
    static let `default` = ThermalAdjustConfig(isThermalAdjustEnable: false,
                                               degradeToastInterval: 3600,
                                               degradeToastShowDuration: 6,
                                               voiceModeToastInterval: 600,
                                               voiceModeToastShowDuration: 6,
                                               scheduledCheckDuration: 20,
                                               seriousDegradeConfig: .seriousDefault,
                                               criticalDegradeConfig: .criticalDefault,
                                               upgradeConfig: .default)
}

public struct DegradeConfig: Decodable {
    public let degradeLevels: [Int]
    public let degradeDuration: Int
    public let degradeImmediately: Bool
    public let voiceMode: Bool

    // nolint: magic number
    static let seriousDefault = DegradeConfig(degradeLevels: [6, 12],
                                              degradeDuration: 300,
                                              degradeImmediately: false,
                                              voiceMode: false)

    // nolint: magic number
    static let criticalDefault = DegradeConfig(degradeLevels: [19],
                                               degradeDuration: 300,
                                               degradeImmediately: true,
                                               voiceMode: true)
}

public struct UpgradeConfig: Decodable {
    public let upgradeState: Int
    public let duration: Int
    public let upgradeLevels: [Int]

    // nolint-next-line: magic number
    static let `default` = UpgradeConfig(upgradeState: 1, duration: 300, upgradeLevels: [0])
}
