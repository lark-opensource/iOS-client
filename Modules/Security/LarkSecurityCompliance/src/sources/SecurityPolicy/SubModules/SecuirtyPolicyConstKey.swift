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

struct SecurityPolicyConstKey {
    static let pointKeyPrefix = "PC:CLIENT:ios:"
    static let ccmCloudOperateType: [EntityOperate] = [
        .ccmExport,
        .ccmCopy,
        .ccmContentPreview,
        .ccmMoveRecycleBin,
        .ccmCreateCopy
    ]

    static let ccmOperateType: [EntityOperate] = [
        .ccmFileDownload,
        .ccmExport,
        .ccmAttachmentDownload,
        .ccmCopy,
        .ccmCreateCopy,
        .ccmContentPreview,
        .ccmFileDownload
    ]

    static let operateTypeMap: [EntityOperate: PermissionType] = [
        .ccmExport: .fileExport,
        .ccmAttachmentDownload: .fileDownload,
        .ccmCopy: .fileCopy,
        .ccmFileDownload: .fileDownload,
        .imFileDownload: .fileDownload,
        .imFilePreview: .localFilePreview
    ]

    static let ccmLocalFileEntityType: [EntityType] = [
        .file
    ]

    static let ccmOperateToPointKey: [EntityOperate: PointKey] = [
        .ccmExport: .ccmExport,
        .ccmContentPreview: .ccmContentPreview,
        .ccmCopy: .ccmCopy,
        .ccmMoveRecycleBin: .ccmMoveRecycleBin,
        .ccmCreateCopy: .ccmCreateCopy
    ]

    static let scenePointKey: [PointKey] = [
        .imFileRead,
        .imFileDownload
    ]

    static let sceneEntityOperate: [EntityOperate] = [
        .imFileRead,
        .imFileDownload
    ]

    static var staticPolicyModel: [PolicyModel] {
        @LarkContainer.Provider var userService: PassportUserService
        guard let userID = Int64(userService.user.userID),
              let tenantID = Int64(userService.userTenant.tenantID) else {
            SPLogger.info("security policy: cannot get user_id or tennant_id in int64")
            return []
        }

        var ccmStaticFilepolicyEntitys: [PolicyModel] = [
            PolicyModel(.ccmContentPreview,
                        CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmContentPreview, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
            PolicyModel(.ccmCopy,
                        CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmCopy, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
            PolicyModel(.ccmFileDownload,
                        CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmFileDownload, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
            PolicyModel(.ccmFilePreView,
                        CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmFilePreView, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
            PolicyModel(.ccmAttachmentDownload,
                        CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmAttachmentDownload, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
            PolicyModel(.ccmFileUpload,
                        CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmFileUpload, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
            PolicyModel(.ccmAttachmentUpload,
                        CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmAttachmentUpload, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
            PolicyModel(.ccmCreateCopy,
                        CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmCreateCopy, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
            PolicyModel(.ccmMoveRecycleBin,
                        CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmMoveRecycleBin, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm))
        ]

        SecurityPolicyConstKey.ccmCloudOperateType.forEach { operateType in
            guard let pointKey = SecurityPolicyConstKey.ccmOperateToPointKey[operateType] else { return }
            ccmStaticFilepolicyEntitys.append(
                PolicyModel(pointKey, CCMEntity(entityType: .doc, entityDomain: .ccm, entityOperate: operateType, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)))
        }

        let imStaticFilepolicyEntitys: [PolicyModel] = [
            PolicyModel(.imFilePreview,
                        IMFileEntity(entityType: .imMsgFile, entityDomain: .im, entityOperate: .imFilePreview, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .im)),
            PolicyModel(.imFileCopy, IMFileEntity(entityType: .imMsgFile, entityDomain: .im, entityOperate: .imFileCopy, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .im))
        ]

        let calendarStaticFilepolicyEntitys: [PolicyModel] = [
            PolicyModel(.ccmFileDownload,
                        CalendarEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmFileDownload, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .calendar))
        ]

        return ccmStaticFilepolicyEntitys + imStaticFilepolicyEntitys + calendarStaticFilepolicyEntitys
    }

    static var disableFileOperateOrStrategy: Bool {
        @LarkContainer.Provider var settings: Settings
        return settings.disableFileOperate.isTrue || settings.disableFileStrategy.isTrue
    }

    static func enableFileProtectionClient(resolver: UserResolver) -> Bool {
        let settings = try? resolver.resolve(assert: Settings.self)
        let service = try? resolver.resolve(assert: FeatureGatingService.self)
        let realTimeFG = service?.dynamicFeatureGatingValue(with: "lark.security.file_protection_client") ?? false
        return realTimeFG && !(settings?.disableFileOperate).isTrue && !(settings?.disableFileStrategy).isTrue
    }

    static func enableFileProtectionClientFG(resolver: UserResolver) -> Bool {
        let service = try? resolver.resolve(assert: FeatureGatingService.self)
        return service?.dynamicFeatureGatingValue(with: "lark.security.file_protection_client") ?? false
    }

    static func enableFGorIsScene(resolver: UserResolver, isScene: Bool) -> Bool {
        let realTimeFG = SecurityPolicyConstKey.enableFileProtectionClientFG(resolver: resolver)
        return realTimeFG || isScene
    }

    static let sceneCacheCacheKey = "sceneCache"

    static let staticCacheCacheKey = "staticCache"

    static let ipPolicyList = "ipPolicy"

    static let sceneFallbackResult = "sceneFallbackResult"

    static let disableCacheList: [PointKey] = [
        .imFileDownload
    ]
}
