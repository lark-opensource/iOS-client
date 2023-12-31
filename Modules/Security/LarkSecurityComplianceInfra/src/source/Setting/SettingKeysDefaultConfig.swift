//
//  SettingKeysDefaultConfig.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/7/27.
//

import Foundation

public struct SCKeysDefaultConfig {
    public static let config: [SCSettingKey: Any] = [
        .enableStreamCipherMode: false,
        .disableSDKInitWait: false,
        .dynamicPointkeyMaxCacheSize: [
            "PointKey_IM_MSG_FILE_READ": 500
        ],
        .lruCacheSize: [
            "PointKey_CCM_OPEN_EXTERNAL_ACCESS_OBJECT": 100,
            "PointKey_CCM_EXPORT_OBJECT": 100,
            "PointKey_CCM_FILE_DOWNLOAD_OBJECT": 100,
            "PointKey_CCM_ATTACHMENT_DOWNLOAD_OBJECT": 100,
            "PointKey_CCM_CONTENT_COPY_OBJECT": 100
        ],
        .dlpMaxCheckTime: 900,
        .dlpPeriodOfValidity: 10 * 60,
        .securityAuditDeprecatedPermType: [
            16 // 本地文件预览
        ],
        .disableDynamicCache: false,
        .logReportFilterPolicySetKeys: [
            "FILE_PROTECT"
        ],
        .logDeleteFilterPolicySetKeys: [
            "FILE_PROTECT",
            "RETENTION_DELETE"
        ],
        .fileStrategyUpdateFrequencyControl: 2,
        .fileStrategyDelayCleanTime: 10 * 60,
        .fileStrategyDelayCleanInaccuracy: 60,
        .disableFileStrategy: false,
        .disableFileOperate: false,
        .disableFileStrategyShare: false,
        .disableFileStrategyShareCache: false,
        .fileStrategyFallbackResult: false,
        .fileStrategyRetryMaxCount: 2,
        .fileStrategyRetryDelayTime: 5,
        .disableHandleSecurityAction: false,
        // 二期新增的key
        .conditionAccessDisabled: false,
        .rootAndEmulatorDetectKaEnable: false,
        .rootAndEmulatorDetectDisable: false,
        .screenProtectionDisalbed: false,
        .pasteProtectionDisalbed: false,
        .loginRestrictionHeatbeatInterval: 900,
        .disableNetworkPathMonitor: false,
        .disableTenantLoginSessionInvalidOpt: false,
        .disablePasteProtectMenuOpt: false,
        .pasteProtectHiddenItems: [String](),
        .pasteProtectRemainItems: [String](),
        .disableAppLockWindowLevelOpt: false,
        .enableAppLockSettingV2: false,
        .canReplacePdfHostViewController: false,
        .enableFileReplaceItem: true,
        .disableSecurityPolicyMigrate: false
    ]
}
