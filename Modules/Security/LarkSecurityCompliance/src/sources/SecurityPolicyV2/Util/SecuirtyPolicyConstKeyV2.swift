//
//  ConstKey.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/15.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkAccountInterface
import LarkContainer
import LarkSetting
import LarkSecurityComplianceInfra

extension SecurityPolicyV2 {
    struct SecurityPolicyConstKey {
        static let pointKeyPrefix = "PC:CLIENT:ios:"
        static let staticCacheKey = "security_policy_static_cache"
        static let staticCacheLocalCachePath = "staticCache"
        static let staticCacheMigrateKey = "static_cache_migrate_key"
        static let ccmCloudOperateType: [EntityOperate] = [
            .ccmExport,
            .ccmCopy,
            .ccmContentPreview,
            .ccmMoveRecycleBin,
            .ccmCreateCopy
        ]

        static let ccmOperateToPointKey: [EntityOperate: PointKey] = [
            .ccmExport: .ccmExport,
            .ccmContentPreview: .ccmContentPreview,
            .ccmCopy: .ccmCopy,
            .ccmMoveRecycleBin: .ccmMoveRecycleBin,
            .ccmCreateCopy: .ccmCreateCopy
        ]

        static let staticCacheCount = 17

        static let staticCacheMaxCapacity = 50

        static let ipPolicyList = "ipPolicy"

        static let sceneFallbackResult = "sceneFallbackResult"

        static let staticCacheMigrateKeyV3 = "static_cache_migrate_key_v3"
    }
}
