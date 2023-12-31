//
//  Extension.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/8/23.
//

import Foundation
import LarkSecurityComplianceInterface
extension PointKey {
    var associatedDynamicPointKey: PointKey? {
        switch self {
        case .ccmCopy: return .ccmCopyObject
        case .ccmExport: return .ccmExportObject
        case .ccmFileDownload: return .ccmFileDownloadObject
        case .ccmAttachmentDownload: return .ccmAttachmentDownloadObject
        case .ccmOpenExternalAccess: return .ccmOpenExternalAccessObject
        default: return nil
        }
    }
    
    var associatedStaticPointKey: PointKey? {
        switch self {
        case .ccmOpenExternalAccess: return nil
        default: return self
        }
    }
}

public extension PolicyModel {
    var associateStaticPolicyModel: PolicyModel? {
        switch self.pointKey {
        case .ccmExport, .ccmFileDownload, .ccmAttachmentDownload, .ccmCopy:
            if let entity = self.entity as? CCMEntity {
                return PolicyModel(self.pointKey, CCMEntity(entityType: entity.entityType,
                                                            entityDomain: entity.entityDomain,
                                                            entityOperate: entity.entityOperate,
                                                            operatorTenantId: entity.operatorTenantId,
                                                            operatorUid: entity.operatorUid,
                                                            fileBizDomain: .ccm))
            } else if let entity = self.entity as? CalendarEntity {
                return PolicyModel(self.pointKey, CCMEntity(entityType: entity.entityType,
                                                            entityDomain: entity.entityDomain,
                                                            entityOperate: entity.entityOperate,
                                                            operatorTenantId: entity.operatorTenantId,
                                                            operatorUid: entity.operatorUid,
                                                            fileBizDomain: .calendar))
            }
            return nil
        case .ccmOpenExternalAccess: return nil
        default: return self
        }
    }

    var associateDynamicPolicyModel: PolicyModel? {
        guard let associatePointKey = self.pointKey.associatedDynamicPointKey else {
            return nil
        }
        switch self.pointKey {
        case .ccmExport, .ccmFileDownload, .ccmAttachmentDownload, .ccmCopy, .ccmOpenExternalAccess, .ccmCreateCopy:
            if let entity = self.entity as? CCMEntity, let toenEntityType = entity.tokenEntityType {
                return PolicyModel(associatePointKey, CCMEntity(entityType: toenEntityType,
                                                                entityDomain: entity.entityDomain,
                                                                entityOperate: entity.entityOperate,
                                                                operatorTenantId: entity.operatorTenantId,
                                                                operatorUid: entity.operatorUid,
                                                                fileBizDomain: .ccm,
                                                                token: entity.token,
                                                                ownerTenantId: entity.ownerTenantId,
                                                                ownerUserId: entity.ownerUserId))
            } else if let entity = self.entity as? CalendarEntity, let toenEntityType = entity.tokenEntityType {
                return PolicyModel(associatePointKey, CCMEntity(entityType: toenEntityType,
                                                                entityDomain: entity.entityDomain,
                                                                entityOperate: entity.entityOperate,
                                                                operatorTenantId: entity.operatorTenantId,
                                                                operatorUid: entity.operatorUid,
                                                                fileBizDomain: .ccm,
                                                                token: entity.token,
                                                                ownerTenantId: entity.ownerTenantId,
                                                                ownerUserId: entity.ownerUserId))
            }
            return PolicyModel(associatePointKey, self.entity)
        default: return nil
        }
    }
}
