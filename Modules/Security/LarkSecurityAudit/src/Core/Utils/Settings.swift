//
//  Settings.swift
//  LarkSecurityAudit
//
//  Created by ByteDance on 2022/8/30.
//

import Foundation
import LarkSetting
import LarkContainer

struct AuditPermissionSetting: SettingDecodable {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "lark_authz_audit_config")

    let authzRetryCount: Int
    let authzRetryDelay: Int
    let authzRetry: Bool

    enum CodingKeys: String, CodingKey {
        case authzRetryCount = "authz_retry_count"
        case authzRetryDelay = "authz_retry_delay"
        case authzRetry = "authz_retry"
    }

    public static func optPullPermissionsettings(userResolver: UserResolver) -> AuditPermissionSetting {
        let service = try? userResolver.resolve(assert: SettingService.self)
        guard let current = try? service?.setting(with: AuditPermissionSetting.self, decodeStrategy: .useDefaultKeys) else {
            return AuditPermissionSetting(authzRetryCount: 2, authzRetryDelay: 5000, authzRetry: true)
        }
        return current
    }
}
