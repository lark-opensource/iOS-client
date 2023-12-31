//
//  AppConfigManager.swift
//  Pods
//
//  Created by liuwanlin on 2020/3/3.
//

import Foundation
import RxSwift
import LKCommonsLogging
import ThreadSafeDataStructure
import LarkFeatureGating
import LarkSetting
import LarkStorage
import LarkContainer

public protocol AppConfigService {
    func feature(for key: String) -> Feature
}

@propertyWrapper
public struct AppConfig {
    private let key: String

    public init(_ key: String) {
        self.key = key
    }

    public var wrappedValue: Feature {
        return AppConfigManager.shared.feature(for: key)
    }
}

public final class AppConfigManager: AppConfigService {
    static var logger = Logger.log(AppConfigManager.self, category: "AppConfigManager")
    private static let leanModeKey = KVKey("LeanModeStatus", default: false)
    private static let LKSettingFieldName = UserSettingKey.make(userKeyLiteral: "lean_mode_config")

    /// AppConfigManager singleton
    public static var shared = AppConfigManager()

    // 精简模式是否开启
    public var leanModeIsOn: Bool {
        return checkLoadLocalConfig(userId: self.currentUserId)
    }

    /// current active user id
    private var currentUserId: String = ""

    let settings: SafeDictionary<String, Any> = [:] + .readWriteLock

    /// Clear config for user
    public func clearConfig() {
        AppConfigManager.logger.info("Clear config for user: \(self.currentUserId)")
        self.currentUserId = ""
        self.settings.removeAll()
    }

    /// reload config
    /// - Parameters:
    ///   - userId: user id
    ///   - clearConfig: clear last user config
    public func reloadConfig(for userId: String, clearConfig: Bool = true) {
        if clearConfig {
            AppConfigManager.shared.clearConfig()
        }

        AppConfigManager.logger.info("userId: \(userId), current userId: \(self.currentUserId)")
        if !self.checkAndSave(useId: userId) {
            return
        }
        /// 如果开了精简模式，才给settings赋值
        guard checkLoadLocalConfig(userId: userId) else {
            return
        }

        // 使用settings，reload config
        let userResolver = try? Container.shared.getUserResolver(userID: userId, compatibleMode: true)
        let settingService = try? userResolver?.resolve(assert: SettingService.self)
        if let settingConfig = try? settingService?.setting (with: Self.LKSettingFieldName) {
            self.settings.replaceInnerData(by: settingConfig)
            AppConfigManager.logger.info("leanmode settings count: \(self.settings.count)")
        }
    }

    /// 启动优化：下次冷启动是否需要加载本地AppConfig缓存
    /// - Parameter
    ///     - status: LeanMode Status
    /// 上次退出App时为正常模式，则冷启动不序列化本地AppConfig
    /// 上次退出App时为精简模式，则冷启动需要序列化本地AppConfig
    public func updateLocalConfigStatus(status: Bool, userId: String) {
        let userStore = buildUserStore(userId: userId)
        userStore[AppConfigManager.leanModeKey] = status
    }

    /// Get feature config with key
    /// - Parameter key: key of the target feature
    public func feature(for key: String) -> Feature {
        let featureKey = settingKeyAppendSuffix(for: key)
        if let isOn = self.settings[featureKey] as? Bool {
            var config = FeatureConf(isOn: isOn, traits: "")
            AppConfigManager.logger.info("leanmode settings for key:\(key), isOn: \(config.isOn)")
            return (try? Feature(key: featureKey, feature: config))!
        }

        return defaultFeature(for: key)
    }

    /// Check if the feature of key is exist
    /// - Parameter key: key of the target feature
    public func exist(for key: String) -> Bool {
        let featureKey = settingKeyAppendSuffix(for: key)
        if let isOn = self.settings[featureKey] as? Bool {
            /// 可以获取到值
            return true
        }
        return false
    }

    private func settingKeyAppendSuffix(for key: String) -> String {
        return key + ".isOn"
    }

    /// 上次退出App时为正常模式，则冷启动不序列化本地AppConfig
    /// 上次退出App时为精简模式，则冷启动需要序列化本地AppConfig
    private func checkLoadLocalConfig(userId: String) -> Bool {
        let userStore = buildUserStore(userId: userId)
        let leanModeStatus = userStore[AppConfigManager.leanModeKey]
        AppConfigManager.logger.info("lean mode status: \(leanModeStatus)")
        return leanModeStatus
    }
 
    private func buildUserStore(userId: String) -> KVStore {
        return KVStores.udkv(
            space: .user(id: userId),
            domain: Domain.biz.core.child("SuiteAppConfig")
        )
    }
 
    private func checkAndSave(useId: String) -> Bool {
        if self.currentUserId.isEmpty {
            self.currentUserId = useId
            return true
        }

        return self.currentUserId == useId
    }

    private func key(for userId: String) -> String {
        return "app_config_\(userId)"
    }

    private func defaultFeature(for key: String) -> Feature {
        var config = FeatureConf(isOn: true, traits: "")
        return (try? Feature(key: key, feature: config))!
    }
}
