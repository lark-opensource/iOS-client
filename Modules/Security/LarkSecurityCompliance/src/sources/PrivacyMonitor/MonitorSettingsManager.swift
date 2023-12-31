//
//  MonitorSettingsManager.swift
//  LarkSecurityCompliance
//
//  Created by Hao Wang on 2023/3/2.
//

import Foundation
import LarkSnCService
import LarkSetting
import LarkReleaseConfig
import LarkSecurityComplianceInfra
import LarkEnv
#if canImport(LarkDebug)
import LarkDebug
#endif
import BootManager

let logger = LoggerImpl(category: "Monitor")

/// 管理类，开关&缓存等逻辑
public final class MonitorSettingsManager {
    private let kSafeModeKey = "lk_safe_mode_crash_count"

    let storage = SCStorageImpl(category: .privacyMonitor)

    public static let shared = MonitorSettingsManager()
    private init() {}

    /// Monitor 是否启动的功能开关，目前只管控飞书包
    /// 1. 本地debug关闭；
    /// 2. Saas 包（包括Saas KA）；
    /// 3. 私有化 KA 包。
    func monitorEnabled() -> Bool {
        if isSafeModeEnabled() {
            return false
        }
        #if DEBUG
        return false
        #else
        if !isFeishu() {
            logger.info("PrivacyMonitor disabled in lark.")
            return false
        }
        if localEnabled() {
            if EnvManager.env.isStaging {
                logger.info("PrivacyMonitor disabled in boe.")
                return false
            }
            logger.info("PrivacyMonitor enabled local env.")
            return true
        }
        if monitorSaasEnabled() {
            logger.info("PrivacyMonitor enabled saas.")
            return true
        }
        if monitorPrivateKAEnabled() {
            logger.info("PrivacyMonitor enabled private KA.")
            return true
        }
        logger.info("PrivacyMonitor disabled in feishu.")
        return false
        #endif
    }

    /// 获取安全模式是否可以用，crashCount>=3
    private func isSafeModeEnabled() -> Bool {
        return UserDefaults.standard.integer(forKey: kSafeModeKey) >= 3
    }

    /// Monitor 是否启动的默认功能开关，控制saas包
    /// 1. Private KA 包不开启；
    /// 2. 线下包（debug+inHouse）默认开启；
    /// 3. 线上包默认关闭，上线后通过setting平台灰度放量。
    private func monitorSaasEnabled() -> Bool {
        return !isPrivateKA() && remoteMonitorSaasEnabled()
    }

    /// 私有化 KA 功能开关
    /// 1. 线下包（debug+inHouse）默认开启；
    /// 2. 线上包默认关闭，上线后通过setting平台灰度放量。
    private func monitorPrivateKAEnabled() -> Bool {
        return isPrivateKA() && remoteMonitorPrivateKAEnabled()
    }

    /// 低端机 或 私有化KA 场景
    func isLowMachineOrPrivateKA() -> Bool {
        logger.info("LowMachine is \(isLowMachine), PrivateKA is \(isPrivateKA())")
        return isLowMachine || isPrivateKA()
    }

    /// 网络管控的快速判断开关
    /// - Returns: 返回允许开启状态
    func networkEnabled() -> Bool {
        return !isKA() && (localEnabled() || remoteNetworkEnabled())
    }

    /// 网络管控的本地判断开关
    private func networkLocalEnabled() -> Bool {
        return !isKA() && localEnabled()
    }

    /// 线下包开关，默认开启，保证能监控到隐私弹窗前
    private func localEnabled() -> Bool {
        return isDebug() || isInHouse()
    }

    /// 是否是飞书包
    private func isFeishu() -> Bool {
        return ReleaseConfig.isFeishu
    }

    /// 内侧包，不包括本地debug
    private func isDebug() -> Bool {
        #if canImport(LarkDebug)
        return appCanDebug()
        #else
        return false
        #endif
    }

    private func isInHouse() -> Bool {
        #if ALPHA
        return true
        #else
        return false
        #endif
    }

    /// KA 逻辑判断
    private func isKA() -> Bool {
        ReleaseConfig.isKA
    }

    /// 私有化KA 逻辑判断
    private func isPrivateKA() -> Bool {
        ReleaseConfig.isPrivateKA
    }

    /// Saas KA 逻辑判断
    private func isSaasKA() -> Bool {
        return isKA() && !isPrivateKA()
    }

    /// 低端机 逻辑判断
    private let isLowMachine = {
        return NewBootManager.shared.liteConfigEnable()
    }()
}

// MARK: - Properties

extension MonitorSettingsManager {

    private struct Keys {
        // Monitor
        static let MonitorRemoteSettingKey = UserSettingKey.make(userKeyLiteral: "privacy_monitor_setting_iOS")
        static let MonitorEnabledRemoteSettingKey = "lark_privacy_monitor_enabled"
        static let MonitorEnabledPrivateKARemoteSettingKey = "lark_privacy_monitor_private_ka_enabled"
        // Monitor frequceny
        static let MonitorFrequencyDowngradeRemoteSettingKey = "monitor_frequency_downgrade_config"
        // Monitor log
        static let MonitorLogRemoteSettingKey = "monitor_log_config"
        // Monitor rule engine
        static let RuleStrategiesRemoteSettingKey = UserSettingKey.make(userKeyLiteral: "scs_rule_engine_strategy_sets")
        // Network
        static let NetworkRemoteSettingKey = UserSettingKey.make(userKeyLiteral: "snc_network_control_settings")
        static let NetworEnabledkRemoteSettingKey = "enable"
    }

    /// 更新配置缓存
    public func updateMonitorConfigFromSetting() {
        // Monitor
        do {
            let remoteSettings = try? SettingManager.shared.setting(with: Keys.MonitorRemoteSettingKey) // Global
            monitorSettings = remoteSettings
            ruleStrategies = try? SettingManager.shared.setting(with: Keys.RuleStrategiesRemoteSettingKey) // Global
        }
        // Network
        do {
            let remoteSettings = try? SettingManager.shared.setting(with: Keys.NetworkRemoteSettingKey) // Global
            networkSettings = remoteSettings
        }
    }

    var monitorSettings: [String: Any]? {
        get {
            let content: String? = try? get(key: Keys.MonitorRemoteSettingKey.stringValue)
            return content?.toDictionary()
        }
        set {
            try? set(newValue?.toJsonString(), forKey: Keys.MonitorRemoteSettingKey.stringValue)
        }
    }

    func frequencyConfig() -> (disabled: Bool, timeThreshold: Int, countThreshold: Int) {
        guard let settings = monitorSettings?[Keys.MonitorFrequencyDowngradeRemoteSettingKey] as? [String: Any] else {
            return (false, 1, 10)
        }
        return ((settings["downgrade_disabled"] as? Bool).or(false),
                (settings["time_threshold"] as? Int).or(1),
                (settings["count_threshold"] as? Int).or(10))
    }

    /// log 是否开启，默认开启，支持远端配置
    func logEnabled() -> Bool {
        guard let settings = monitorSettings?[Keys.MonitorLogRemoteSettingKey] as? [String: Any] else {
            return true
        }
        let saasDisabled = (settings["saas_disabled"] as? Bool).or(false)
        let privateKADisabled = (settings["private_ka_disabled"] as? Bool).or(false)
        return (!saasDisabled && !isPrivateKA()) || (!privateKADisabled && isPrivateKA())
    }

    var ruleStrategies: [String: Any]? {
        get {
            let content: String? = try? get(key: Keys.RuleStrategiesRemoteSettingKey.stringValue)
            return content?.toDictionary()
        }
        set {
            try? set(newValue?.toJsonString(), forKey: Keys.RuleStrategiesRemoteSettingKey.stringValue)
        }
    }

    /// 远端 Monitor Enabled Settings。（非私有化KA）
    /// 线上正式包开关，默认开启，灰度使用
    private func remoteMonitorSaasEnabled() -> Bool {
        return (monitorSettings?[Keys.MonitorEnabledRemoteSettingKey] as? Bool).or(true)
    }

    /// 远端私有化KA开关，默认关闭，灰度使用
    private func remoteMonitorPrivateKAEnabled() -> Bool {
        return (monitorSettings?[Keys.MonitorEnabledPrivateKARemoteSettingKey] as? Bool).or(false)
    }

    // MARK: - Network

    /// 远端 Monitor Enabled Settings
    var networkSettings: [String: Any]? {
        get {
            let content: String? = try? get(key: Keys.NetworkRemoteSettingKey.stringValue)
            if content == nil { logger.info("Network Monitor: can't get remote setting, use local default setting.") }
            var contentDict = content?.toDictionary() ?? [
                "network_allow_configs": [
                    [
                        "start_with_paths": [
                            "/var/mobile/Containers/Data/",
                            "/monitor/collect/batch/",
                            "/monitor/collect/c/logcollect",
                            "/monitor/collect/c/exception",
                            "/monitor/collect/c/code_coverage"
                        ],
                        "end_with_domains": [],
                        "invoke_type": "response"
                    ]
                ],
                "enable": false,
                "network_upload_sample_rate": 100
            ]
            if MonitorSettingsManager.shared.networkLocalEnabled() {
                contentDict["enable"] = true
                contentDict["enable_webview_monitor"] = true
            }
            return contentDict
        }
        set {
            try? set(newValue?.toJsonString(), forKey: Keys.NetworkRemoteSettingKey.stringValue)
        }
    }

    private func remoteNetworkEnabled() -> Bool {
        return (networkSettings?[Keys.NetworEnabledkRemoteSettingKey] as? Bool).or(false)
    }
}

// MARK: - Wrapper 方法

extension MonitorSettingsManager {
    private func set<T: Codable>(_ value: T?, forKey: String) throws {
        try storage.set(value, forKey: forKey)
    }
    private func get<T: Codable>(key: String) throws -> T? {
        return try storage.get(key: key)
    }
}
