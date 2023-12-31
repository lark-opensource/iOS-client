//
//  FeatureSwitch.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/11.
//

import Foundation
import LarkAccountInterface
import LarkAppConfig
import LKCommonsLogging
import LarkKAFeatureSwitch

class RustFeatureSwitch: FeatureSwitchProtocol {

    static let logger = Logger.plog(RustFeatureSwitch.self, category: "SuiteLogin.FeatureSwitch")

    func bool(for key: String) -> Bool {
        guard let switchKey = LarkKAFeatureSwitch.FeatureSwitch.SwitchKey(rawValue: key) else {
            Self.logger.error("unknown key to get feature switch, use false", additionalData: [
                "key": key
            ])
            return false
        }
        let value = LarkKAFeatureSwitch.FeatureSwitch.share.bool(for: switchKey) // user:checked (setting)
        Self.logger.info("get feature switch value", additionalData: [
            "value": String(describing: value)
        ])
        return value
    }

    func config(for key: String) -> [String] {
        guard let configKey = LarkKAFeatureSwitch.FeatureSwitch.ConfigKey(rawValue: key) else {
            Self.logger.error("unknown config key to get feature switch, use empty", additionalData: [
                "key": key
            ])
            return []
        }
        let value = LarkKAFeatureSwitch.FeatureSwitch.share.config(for: configKey)
        Self.logger.info("get feature config value", additionalData: [
            "value": String(describing: value)
        ])
        return value
    }

}
