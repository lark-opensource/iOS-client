//
//  Settings.swift
//  LarkSecurityComplianceInfra
//
//  Created by qingchun on 2022/4/22.
//

import Foundation
import LarkSetting
import LarkContainer

public protocol Settings {
    var conditionAccessDisabled: Bool? { get }
    var rootAndEmulatorDetectKaEnable: Bool? { get }
    var rootAndEmulatorDetectDisable: Bool? { get }
    var screenProtectionDisalbed: Bool? { get }
    var pasteProtectionDisalbed: Bool? { get }
    var enablePolicyEngine: Bool? { get }
    var policyEngineDisableLocalValidate: Bool? { get }
    var policyEngineFetchPolicyInterval: Int? { get }
    var policyEngineLocalValidateCountLimit: Int? { get }
    var policyEnginePointcutRetryDelay: Int? { get }
    var disableFileStrategy: Bool? { get }
    var disableFileOperate: Bool? { get }
    var fileStrategyFallbackResult: Bool? { get }
    var disableFileStrategyShareCache: Bool? { get }
    var disableFileStrategyShare: Bool? { get }
    var dynamicPointkeyMaxCacheSize: [String: Int]? { get }
    var enableStreamCipherMode: Bool? { get }
    var loginRestrictionHeatbeatInterval: Int? { get }
    var fileStrategyRetryDelayTime: Int? { get }
    var fileStrategyRetryMaxCount: Int? { get }
    var fileStrategyDelayCleanTime: Int? { get }
    var fileStrategyDelayCleanInaccuracy: Int? { get }
    var fileStrategyUpdateFrequencyControl: Int? { get }
    var disableHandleSecurityAction: Bool? { get }
    var disableNetworkPathMonitor: Bool? { get }
    var disableTenantLoginSessionInvalidOpt: Bool? { get }
    var disableDynamicCache: Bool? { get }
    var disablePasteProtectMenuOpt: Bool? { get }
    var pasteProtectHiddenItems: [String]? { get }
    var pasteProtectRemainItems: [String]? { get }
    var disableSDKInitWait: Bool? { get }
    var enableSecurityV2: Bool? { get }
    var enableSecuritySettingsV2: Bool? { get }

    var allSettings: [String: Any]? { get }
}

public struct SettingsImp: SettingDecodable, Settings {
    public let conditionAccessDisabled: Bool?
    public let rootAndEmulatorDetectKaEnable: Bool?
    public let rootAndEmulatorDetectDisable: Bool?
    public let screenProtectionDisalbed: Bool?
    public let pasteProtectionDisalbed: Bool?
    public let enablePolicyEngine: Bool?
    public let policyEngineDisableLocalValidate: Bool?
    public let policyEngineFetchPolicyInterval: Int?
    public let policyEngineLocalValidateCountLimit: Int?
    public let policyEnginePointcutRetryDelay: Int?
    public let disableFileStrategy: Bool?
    public let disableFileOperate: Bool?
    public let fileStrategyFallbackResult: Bool?
    public let disableFileStrategyShareCache: Bool?
    public let disableFileStrategyShare: Bool?
    public let dynamicPointkeyMaxCacheSize: [String: Int]?
    public let enableStreamCipherMode: Bool?
    public let loginRestrictionHeatbeatInterval: Int?
    public let fileStrategyRetryDelayTime: Int?
    public let fileStrategyRetryMaxCount: Int?
    public let fileStrategyDelayCleanTime: Int?
    public let fileStrategyDelayCleanInaccuracy: Int?
    public let fileStrategyUpdateFrequencyControl: Int?
    public let disableHandleSecurityAction: Bool?
    public let disableNetworkPathMonitor: Bool?
    public let disableTenantLoginSessionInvalidOpt: Bool?
    public let disableDynamicCache: Bool?
    public let disablePasteProtectMenuOpt: Bool?
    public let pasteProtectHiddenItems: [String]?
    public let pasteProtectRemainItems: [String]?
    public let disableSDKInitWait: Bool?
    public let enableSecurityV2: Bool?
    public let enableSecuritySettingsV2: Bool?

    public var allSettings: [String: Any]?

    public enum CodingKeys: String, CodingKey {
        case conditionAccessDisabled = "condition_access_disabled"
        case rootAndEmulatorDetectKaEnable = "root_and_emulator_detect_ka_enable"
        case rootAndEmulatorDetectDisable = "root_and_emulator_detect_disable"
        case screenProtectionDisalbed = "screen_protection_disabled"
        case pasteProtectionDisalbed = "paste_protection_disabled"
        case enablePolicyEngine = "enable_policy_engine"
        case policyEngineDisableLocalValidate = "policy_engine_disable_local_validate"
        case policyEngineFetchPolicyInterval = "policy_engine_fetch_policy_interval"
        case policyEngineLocalValidateCountLimit = "policy_engine_local_validate_count_limit"
        case policyEnginePointcutRetryDelay = "policy_engine_pointcut_retry_delay"
        case disableFileStrategy = "disable_file_strategy"
        case disableFileOperate = "disable_file_operate"
        case fileStrategyFallbackResult = "file_strategy_fallback_result"
        case disableFileStrategyShareCache = "disable_file_strategy_share_cache"
        case disableFileStrategyShare = "disable_file_strategy_share"
        case dynamicPointkeyMaxCacheSize = "dynamic_pointkey_max_cache_size"
        case enableStreamCipherMode = "enable_stream_cipher_mode"
        case loginRestrictionHeatbeatInterval = "login_restriction_heartbeat_interval"
        case fileStrategyRetryDelayTime = "file_strategy_retry_delay_time"
        case fileStrategyRetryMaxCount = "file_strategy_retry_max_count"
        case fileStrategyDelayCleanTime = "file_strategy_delay_clean_time"
        case fileStrategyDelayCleanInaccuracy = "file_strategy_delay_clean_inaccuracy"
        case fileStrategyUpdateFrequencyControl = "file_strategy_update_frequency_control"
        case disableHandleSecurityAction = "disable_handle_security_action"
        case disableNetworkPathMonitor = "disable_network_path_monitor"
        case disableTenantLoginSessionInvalidOpt = "disable_tenant_login_session_invalid_opt"
        case disableDynamicCache = "disable_dynamic_cache"
        case disablePasteProtectMenuOpt = "disable_paste_protect_menu_opt"
        case pasteProtectHiddenItems = "paste_protect_hidden_items"
        case pasteProtectRemainItems = "paste_protect_remain_items"
        case disableSDKInitWait = "disable_sdk_init_wait"
        case enableSecurityV2 = "enable_security_v2"
        case enableSecuritySettingsV2 = "enable_security_settings_v2"
    }
}

extension SettingsImp {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "lark_security_compliance_config")

    public static let logTag = "security_compliance_primitive_settings"

    public static func settings(resolver: UserResolver) -> Settings {
        do {
            let settingService = try resolver.resolve(assert: SettingService.self)
            let settings = try settingService.setting(with: Self.settingKey)
            let data = try JSONSerialization.data(withJSONObject: settings)
            var current = try JSONDecoder().decode(Self.self, from: data)
            current.allSettings = settings
            return current
        } catch {
            return SettingsImp(conditionAccessDisabled: false,
                               rootAndEmulatorDetectKaEnable: false,
                               rootAndEmulatorDetectDisable: false,
                               screenProtectionDisalbed: false,
                               pasteProtectionDisalbed: false,
                               enablePolicyEngine: true,
                               policyEngineDisableLocalValidate: false,
                               policyEngineFetchPolicyInterval: 5 * 60,
                               policyEngineLocalValidateCountLimit: 100,
                               policyEnginePointcutRetryDelay: 5,
                               disableFileStrategy: false,
                               disableFileOperate: false,
                               fileStrategyFallbackResult: false,
                               disableFileStrategyShareCache: false,
                               disableFileStrategyShare: false,
                               dynamicPointkeyMaxCacheSize: ["PointKey_IM_MSG_FILE_READ": 500],
                               enableStreamCipherMode: false,
                               loginRestrictionHeatbeatInterval: 900,
                               fileStrategyRetryDelayTime: 5,
                               fileStrategyRetryMaxCount: 2,
                               fileStrategyDelayCleanTime: 10 * 60,
                               fileStrategyDelayCleanInaccuracy: 60,
                               fileStrategyUpdateFrequencyControl: 2,
                               disableHandleSecurityAction: false,
                               disableNetworkPathMonitor: false,
                               disableTenantLoginSessionInvalidOpt: false,
                               disableDynamicCache: false,
                               disablePasteProtectMenuOpt: false,
                               pasteProtectHiddenItems: [],
                               pasteProtectRemainItems: [],
                               disableSDKInitWait: false,
                               enableSecurityV2: false,
                               enableSecuritySettingsV2: false
            )
        }
    }
}
