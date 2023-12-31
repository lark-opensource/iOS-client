//
//  AccountConfig.swift
//  LarkAccount
//
//  Created by quyiming on 2020/9/10.
//

import LarkAccountInterface
import LKCommonsLogging

// MARK: - Feature Switch

enum FeatureConfigKey: String {
    /// applog acitve服务uri，计激活安装，算DAU的，iOS/Android使用
    case ttActiveUri = "tt_active_uri"

    /// device服务uri，iOS/Android的applog使用
    case ttDeviceUri = "tt_device_uri"
}

class AccountFeatureSwitchDefault: FeatureSwitchProtocol {
    static let logger = Logger.log(AccountFeatureSwitchDefault.self, category: "SuiteLogin.AccountFeatureSwitchDefault")

    func config(for key: String) -> [String] {
        guard let confKey = FeatureConfigKey(rawValue: key) else {
            Self.logger.error("unknown feature config key", additionalData: [
                "key": key
            ])
            return []
        }

        Self.logger.info("get default feature config", additionalData: [
            "key": key
        ])
        switch confKey {
        case .ttActiveUri, .ttDeviceUri:
            return []
        }
    }
}

extension FeatureSwitchProtocol {

    func config(for key: FeatureConfigKey) -> [String] {
        return config(for: key.rawValue)
    }
}

// MARK: - App Config

enum AppConfigFeatureKey: String {
    case sso
}

class AppConfigDefault: AppConfigProtocol {
    func featureOn(for key: String) -> Bool {
        guard let fgKey = AppConfigFeatureKey(rawValue: key) else {
            return false
        }
        switch fgKey {
        case .sso: return true
        }
    }
}

extension AppConfigProtocol {
    func featureOn(for key: AppConfigFeatureKey) -> Bool {
        return featureOn(for: key.rawValue)
    }
}
