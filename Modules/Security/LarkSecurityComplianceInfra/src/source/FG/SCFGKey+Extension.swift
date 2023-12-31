//
//  SCFGKey+Extension.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/8/2.
//

import Foundation

public extension SCFGKey {
    static let encryptionUpgrade = SCFGKey(rawValue: "lark.security.encryption_upgrade", version: "6.6", owner: "sunxingjian")
    static let enableDlp = SCFGKey(rawValue: "lark.security.ccm_dlp_migrate", version: "7.1", owner: "wangxijing")
    static let enableCcmDlp = SCFGKey(rawValue: "ccm.doc.dlp_enable", version: "", owner: "wangxijing")
    static let enableSecuritySDK = SCFGKey(rawValue: "lark.security.file_protection_client", version: "6.1", owner: "wangxijing")
    static let enablePrivacyMode = SCFGKey(rawValue: "messenger.leanmode.privacymode", version: "", owner: "chenqingchun")
    static let enableLoginRestrict = SCFGKey(rawValue: "lark.security.login_restrict_switch", version: "6.1", owner: "wangxijing")
    static let enableOptNetworkMonitor = SCFGKey(rawValue: "lark.security.enable_opt_network_monitor", version: "7.8", owner: "wangxijing")
    static let enableDeviceApplyReason = SCFGKey(rawValue: "lark.security.device_apply_approval", version: "7.7", owner: "sunxingjian")
    static let enableSecurityUserContainerOpt = SCFGKey(rawValue: "lark.security.enable_security_user_container_opt", version: "7.9", owner: "wangxijing")
    static let cryptoUserRust = SCFGKey(rawValue: "crypto.use.user.rust", version: "7.8", owner: "chengqingchun")
    static let enableFileMigrationPool = SCFGKey(rawValue: "enable.file.migration.pool", version: "7.8", owner: "chengqingchun")
    static let enablePasteProtectOpt = SCFGKey(rawValue: "lark.security.enable_protect_paste_opt", version: "7.10", owner: "wangxijing")
}
