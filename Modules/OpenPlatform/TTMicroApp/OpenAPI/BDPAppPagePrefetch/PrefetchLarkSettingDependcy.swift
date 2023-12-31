//
//  PrefetchLarkSettingDependcy.swift
//  TTMicroApp
//
//  Created by 刘焱龙 on 2022/8/19.
//

import Foundation
import LarkSetting

private struct OPPrefetchConcurrentSetting: SettingDecodable {
    static var settingKey  = UserSettingKey.make(userKeyLiteral: "prefetch_concurrent_config")
    let prefetchSupportConcurrent: [String: Bool]
}

private struct OPPrefetchConsistencyConfigSetting: SettingDecodable {
    static var settingKey  = UserSettingKey.make(userKeyLiteral: "prefetch_config")
    let appIdToEnable: [String: Bool]
    let `default`: Bool
    let prefetchLimit: Int
}

private struct OPPrefetchFixDecodeSetting: SettingDecodable {
    static var settingKey  = UserSettingKey.make(userKeyLiteral: "prefetch_fix_decode")
    let appIds: [String]
    let `default`: Bool
}

@objcMembers public final class PrefetchLarkSettingDependcy: NSObject {
    static let kPrefetchDefaultSettingsKey = "default";
    static let defaultPrefetchLimit = 5

    private static var concurrentSetting: OPPrefetchConcurrentSetting = {
        (try? SettingManager.shared.setting(with: OPPrefetchConcurrentSetting.self)) ?? OPPrefetchConcurrentSetting(prefetchSupportConcurrent: [:])
    }()

    private static var consistencyConfigSetting: OPPrefetchConsistencyConfigSetting = {
        (try? SettingManager.shared.setting(with: OPPrefetchConsistencyConfigSetting.self)) ?? OPPrefetchConsistencyConfigSetting(appIdToEnable: [:], default: false, prefetchLimit: defaultPrefetchLimit)
    }()

    private static var fixDecodeSetting: OPPrefetchFixDecodeSetting = {
        (try? SettingManager.shared.setting(with: OPPrefetchFixDecodeSetting.self)) ?? OPPrefetchFixDecodeSetting(appIds: [], default: false)
    }()

    @objc
    public static var prefetchLimit: Int {
        return consistencyConfigSetting.prefetchLimit
    }

    @objc
    public static func supportUpdateFetchQueueConcurrent(appID: String) -> Bool {
        if appID.isEmpty {
            return false
        }
        if let supportConcurrent = concurrentSetting.prefetchSupportConcurrent[appID] {
            return supportConcurrent
        }
        return concurrentSetting.prefetchSupportConcurrent[kPrefetchDefaultSettingsKey] ?? false
    }

    @objc
    public static func supportPrefetchConsistency(appID: String) -> Bool {
        if appID.isEmpty {
            return false
        }
        if let support = consistencyConfigSetting.appIdToEnable[appID] {
            return support
        }
        return consistencyConfigSetting.default
    }

    @objc
    public static func shouldFixDecode(appID: String) -> Bool {
        if appID.isEmpty {
            return false
        }
        if fixDecodeSetting.appIds.contains(appID) {
            return true
        }
        return fixDecodeSetting.default
    }
}
