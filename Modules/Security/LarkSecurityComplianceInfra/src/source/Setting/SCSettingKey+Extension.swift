//
//  SCSettingKey+Extension.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/8/2.
//

import Foundation

public extension SCSettingKey {
    static let enableStreamCipherMode = SCSettingKey(rawValue: "enable_stream_cipher_mode", version: "6.10", owner: "chengqingchun")
    static let disableSDKInitWait = SCSettingKey(rawValue: "disable_sdk_init_wait", version: "6.10", owner: "chengqingchun")
    static let dynamicPointkeyMaxCacheSize = SCSettingKey(rawValue: "dynamic_pointkey_max_cache_size", version: "6.1", owner: "wangxijing")
    static let disableAppLockSceneOpt = SCSettingKey(rawValue: "disable_app_lock_scene_opt", version: "7.1", owner: "chengqingchun")
    static let securityAuditDeprecatedPermType = SCSettingKey(rawValue: "security_audit_deprecated_perm_type", version: "7.1", owner: "chenjinglin")
    static let dlpMaxCheckTime = SCSettingKey(rawValue: "dlp_max_check_time", version: "7.1", owner: "wangxijing")
    static let lruCacheSize = SCSettingKey(rawValue: "lru_cache_size", version: "7.1", owner: "wangxijing")
    static let dlpPeriodOfValidity = SCSettingKey(rawValue: "dlp_period_of_validity", version: "7.1", owner: "wangxijing")
    static let logReportFilterPolicySetKeys = SCSettingKey(rawValue: "log_report_filter_policy_set_keys", version: "7.3", owner: "wangxijing")
    static let logDeleteFilterPolicySetKeys = SCSettingKey(rawValue: "log_delete_filter_policy_set_keys", version: "7.3", owner: "wangxijing")
    static let conditionAccessDisabled = SCSettingKey(rawValue: "condition_access_disabled", version: "5.22", owner: "chengqingchun")
    static let rootAndEmulatorDetectKaEnable = SCSettingKey(rawValue: "root_and_emulator_detect_ka_enable", version: "6.4", owner: "chengqingchun")
    static let rootAndEmulatorDetectDisable = SCSettingKey(rawValue: "root_and_emulator_detect_disable", version: "6.4", owner: "chengqingchun")
    static let screenProtectionDisalbed = SCSettingKey(rawValue: "screen_protection_disabled", version: "5.23", owner: "chengqingchun")
    static let pasteProtectionDisalbed = SCSettingKey(rawValue: "paste_protection_disabled", version: "5.24", owner: "wangxijing")
    static let loginRestrictionHeatbeatInterval = SCSettingKey(rawValue: "login_restriction_heartbeat_interval", version: "6.1", owner: "wangxijing")
    static let disableNetworkPathMonitor = SCSettingKey(rawValue: "disable_network_path_monitor", version: "6.10", owner: "wangxijing")
    static let disableTenantLoginSessionInvalidOpt = SCSettingKey(rawValue: "disable_tenant_login_session_invalid_opt", version: "6.10", owner: "wangxijing")
    static let disablePasteProtectMenuOpt = SCSettingKey(rawValue: "disable_paste_protect_menu_opt", version: "6.11", owner: "wangxijing")
    static let pasteProtectHiddenItems = SCSettingKey(rawValue: "paste_protect_hidden_items", version: "6.11", owner: "wangxijing")
    static let pasteProtectRemainItems = SCSettingKey(rawValue: "paste_protect_remain_items", version: "6.11", owner: "wangxijing")
    static let disableAppLockWindowLevelOpt = SCSettingKey(rawValue: "disable_app_lock_window_level_opt", version: "7.4", owner: "chengqingchun")
    static let canReplacePdfHostViewController = SCSettingKey(rawValue: "can_replace_webview_container_pdf", version: "7.6", owner: "wangxijing")
    static let disableDynamicCache = SCSettingKey(rawValue: "disable_dynamic_cache", version: "6.1", owner: "wangxijing")
    static let fileStrategyUpdateFrequencyControl = SCSettingKey(rawValue: "file_strategy_update_frequency_control", version: "6.1", owner: "wangxijing")
    static let fileStrategyDelayCleanTime = SCSettingKey(rawValue: "file_strategy_delay_clean_time", version: "6.1", owner: "wangxijing")
    static let fileStrategyDelayCleanInaccuracy = SCSettingKey(rawValue: "file_strategy_delay_clean_inaccuracy", version: "6.1", owner: "wangxijing")
    static let disableFileStrategy = SCSettingKey(rawValue: "disable_file_strategy", version: "6.1", owner: "wangxijing")
    static let disableFileOperate = SCSettingKey(rawValue: "disable_file_operate", version: "6.1", owner: "wangxijing")
    static let disableFileStrategyShareCache = SCSettingKey(rawValue: "disable_file_strategy_share_cache", version: "6.1", owner: "wangxijing")
    static let disableFileStrategyShare = SCSettingKey(rawValue: "disable_file_strategy_share", version: "6.1", owner: "wangxijing")
    static let fileStrategyFallbackResult = SCSettingKey(rawValue: "file_strategy_fallback_result", version: "6.1", owner: "wangxijing")
    static let fileStrategyRetryDelayTime = SCSettingKey(rawValue: "file_strategy_retry_delay_time", version: "6.1", owner: "wangxijing")
    static let fileStrategyRetryMaxCount = SCSettingKey(rawValue: "file_strategy_retry_max_count", version: "6.1", owner: "wangxijing")
    static let disableHandleSecurityAction = SCSettingKey(rawValue: "disable_handle_security_action", version: "6.7", owner: "chenjinglin")
    static let enableAppLockSettingV2 = SCSettingKey(rawValue: "enable_app_lock_setting_v2", version: "7.7", owner: "chenjinglin")
    static let enableFileReplaceItem = SCSettingKey(rawValue: "enable_file_replace_item", version: "7.8", owner: "chenqingchun")
    static let disableSecurityPolicyMigrate = SCSettingKey(rawValue: "disable_security_policy_migrate", version: "7.9", owner: "chenjinglin")

}
