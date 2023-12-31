//
//  PrivacyMonitorTask.swift
//  LarkSecurityCompliance
//
//  Created by huanzhengjie on 2022/10/26.
//

import UIKit
import BootManager
import LarkPrivacyMonitor
import LarkAppConfig
import MMKV
import LarkSnCService

/// Monitor SDK 初始化任务
class PrivacyMonitorTask: FlowBootTask, Identifiable { // Global
    static var identify: TaskIdentify = "PrivacyMonitorTask"

    override func execute(_ context: BootContext) {
        if MonitorSettingsManager.shared.monitorEnabled() {
            logger.info("PrivacyMonitor start.")
            // 一次启动期间配置只生效一次，不支持热更新。
            PrivacyMonitor.shared.storage = MonitorSettingsManager.shared.storage
            PrivacyMonitor.shared.logger = logger
            PrivacyMonitor.shared.monitor = MonitorImpl(business: .privacy_monitor)
            PrivacyMonitor.shared.isLowMachineOrPrivateKA = MonitorSettingsManager.shared.isLowMachineOrPrivateKA()
            PrivacyMonitor.shared.updateFrequencyConfig(MonitorFrequencyConfig())
            PrivacyMonitor.shared.updateLogConfig(MonitorLogConfig())
            // 开启 Monitor
            PrivacyMonitor.shared.start(withConfig: PrivacyMonitorConfig())
            logger.info("PrivacyMonitor end.")
        }
        if MonitorSettingsManager.shared.networkEnabled() {
            logger.info("Network control start...")
            LarkPrivacyMonitor.NetworkMonitor.shared.logger = logger
            LarkPrivacyMonitor.NetworkMonitor.shared.env = EnvironmentImpl()
            LarkPrivacyMonitor.NetworkMonitor.shared.start(config: NetworkMonitorConfig())
        }
    }

    override var runOnlyOnce: Bool {
        return true
    }
}

// MARK: - 实现 Monitor 配置需要的相关协议，注入 Monitor 使用

final class PrivacyMonitorConfig: MonitorConfig {
    /// Monitor SDK 初始化规则下发，单端独立配置
    func settings() -> [String: Any]? {
        return remoteSetting(ofKey: "monitor_sdk_config")
    }

    /// 策略引擎配置下发，单端独立配置
    func ruleEngineConfig() -> [String: Any]? {
        if MonitorSettingsManager.shared.isLowMachineOrPrivateKA() {
            // 私有化KA | lite功能开启（低端机） 不开启策略引擎，不触发规则管控
            return ["enable_rule_engine": false]
        }
        return remoteSetting(ofKey: "rule_engine_config")
    }

    /// 管控策略规则引发，双端共用一份配置
    func ruleStrategies() -> [String: Any]? {
        return MonitorSettingsManager.shared.ruleStrategies
    }

    private func remoteSetting(ofKey key: String) -> [String: Any]? {
        guard let remoteSetting = MonitorSettingsManager.shared.monitorSettings else {
            return nil
        }
        return (remoteSetting[key] as? [String: Any])
    }
}

final class NetworkMonitorConfig: Config {
    func settings() -> [String: Any]? {
        return MonitorSettingsManager.shared.networkSettings
    }
}

final class MonitorFrequencyConfig: FrequencyConfig {
    private let config: (disabled: Bool, timeThreshold: Int, countThreshold: Int)

    init() {
        config = MonitorSettingsManager.shared.frequencyConfig()
    }

    func enabled() -> Bool {
        return !config.disabled
    }

    func timeThreshold() -> Int {
        return max(config.timeThreshold, 1)
    }

    func countThreshold() -> Int {
        return max(config.countThreshold, 1)
    }

}

final class MonitorLogConfig: LogConfig {
    func enabled() -> Bool {
        return MonitorSettingsManager.shared.logEnabled()
    }
}
