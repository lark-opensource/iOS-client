//
//  SecurityAuditLauncherDelegate.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/11/24.
//

import LarkAccountInterface

public final class SecurityAuditLauncherDelegate: PassportDelegate {
    public let name: String = "SecurityAudit"

    public func userDidOffline(state: PassportState) {
        // 登出停止SDK
        SecurityAuditManager.shared.initSDK(.emptyConfig)
        SecurityAuditManager.shared.stop()
    }
}
