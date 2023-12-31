//
//  PolicyModelManagement.swift
//  LarkSecurityComplianceInterface
//
//  Created by ByteDance on 2023/8/9.
//

import Foundation
public enum PointCutOperate {
    case ccmContentPreview(entityType: EntityType,
                           operateTenantId: Int64,
                           operateUserId: Int64)
    case ccmContentCopy(entityType: EntityType,
                        operateTenantId: Int64,
                        operateUserId: Int64,
                        token: String,
                        ownerTenantId: Int64?,
                        ownerUserId: Int64?,
                        tokenEntityType: EntityType? = nil)
    case ccmFileDownload(entityType: EntityType,
                         operateTenantId: Int64,
                         operateUserId: Int64,
                         token: String,
                         ownerTenantId: Int64?,
                         ownerUserId: Int64?,
                         tokenEntityType: EntityType? = nil)
    case ccmExport(entityType: EntityType,
                   operateTenantId: Int64,
                   operateUserId: Int64,
                   token: String,
                   ownerTenantId: Int64?,
                   ownerUserId: Int64?,
                   tokenEntityType: EntityType? = nil)
    case ccmAttachmentDownload(entityType: EntityType,
                               operateTenantId: Int64,
                               operateUserId: Int64,
                               token: String,
                               ownerTenantId: Int64?,
                               ownerUserId: Int64?,
                               tokenEntityType: EntityType? = nil)
    case ccmOpenExternalAccess(entityType: EntityType,
                               operateTenantId: Int64,
                               operateUserId: Int64,
                               token: String,
                               ownerTenantId: Int64?,
                               ownerUserId: Int64?,
                               tokenEntityType: EntityType? = nil)
    case calendarFileDownload(entityType: EntityType,
                              operateTenantId: Int64,
                              operateUserId: Int64,
                              token: String,
                              ownerTenantId: Int64?,
                              ownerUserId: Int64?,
                              tokenEntityType: EntityType? = nil)
    
    public func asModel() -> PolicyModel {
        switch self {
        case .ccmContentCopy(let entityType,
                             let operateTenantId,
                             let operateUserId,
                             let token,
                             let ownerTenantId,
                             let ownerUserId,
                             let tokenEntityType):
            let entity = CCMEntity(entityType: entityType,
                                   entityDomain: .ccm,
                                   entityOperate: .ccmCopy,
                                   operatorTenantId: operateTenantId,
                                   operatorUid: operateUserId,
                                   fileBizDomain: .ccm,
                                   token: token,
                                   ownerTenantId: ownerTenantId,
                                   ownerUserId: ownerUserId,
                                   tokenEntityType: tokenEntityType)
            return PolicyModel(.ccmCopy, entity)
        case .ccmFileDownload(let entityType,
                              let operateTenantId,
                              let operateUserId,
                              let token,
                              let ownerTenantId,
                              let ownerUserId,
                              let tokenEntityType):
            let entity = CCMEntity(entityType: entityType,
                                   entityDomain: .ccm,
                                   entityOperate: .ccmFileDownload,
                                   operatorTenantId: operateTenantId,
                                   operatorUid: operateUserId,
                                   fileBizDomain: .ccm,
                                   token: token,
                                   ownerTenantId: ownerTenantId,
                                   ownerUserId: ownerUserId,
                                   tokenEntityType: tokenEntityType)
            return PolicyModel(.ccmFileDownload, entity)
        case .ccmExport(let entityType,
                        let operateTenantId,
                        let operateUserId,
                        let token,
                        let ownerTenantId,
                        let ownerUserId,
                        let tokenEntityType):
            let entity = CCMEntity(entityType: entityType,
                                   entityDomain: .ccm,
                                   entityOperate: .ccmExport,
                                   operatorTenantId: operateTenantId,
                                   operatorUid: operateUserId,
                                   fileBizDomain: .ccm, token: token,
                                   ownerTenantId: ownerTenantId,
                                   ownerUserId: ownerUserId,
                                   tokenEntityType: tokenEntityType)
            return PolicyModel(.ccmExport, entity)
        case .ccmAttachmentDownload(let entityType,
                                    let operateTenantId,
                                    let operateUserId,
                                    let token,
                                    let ownerTenantId,
                                    let ownerUserId,
                                    let tokenEntityType):
            let entity = CCMEntity(entityType: entityType,
                                   entityDomain: .ccm,
                                   entityOperate: .ccmAttachmentDownload,
                                   operatorTenantId: operateTenantId,
                                   operatorUid: operateUserId, fileBizDomain: .ccm,
                                   token: token,
                                   ownerTenantId: ownerTenantId,
                                   ownerUserId: ownerUserId,
                                   tokenEntityType: tokenEntityType)
            return PolicyModel(.ccmAttachmentDownload, entity)
        case .ccmOpenExternalAccess(let entityType,
                                    let operateTenantId,
                                    let operateUserId,
                                    let token,
                                    let ownerTenantId,
                                    let ownerUserId,
                                    let tokenEntityType):
            let entity = CCMEntity(entityType: entityType,
                                   entityDomain: .ccm,
                                   entityOperate: .ccmShare,
                                   operatorTenantId: operateTenantId,
                                   operatorUid: operateUserId,
                                   fileBizDomain: .ccm,
                                   token: token,
                                   ownerTenantId: ownerTenantId,
                                   ownerUserId: ownerUserId,
                                   tokenEntityType: tokenEntityType)
            return PolicyModel(.ccmOpenExternalAccess, entity)
        case .calendarFileDownload(let entityType,
                                   let operateTenantId,
                                   let operateUserId,
                                   let token,
                                   let ownerTenantId,
                                   let ownerUserId,
                                   let tokenEntityType):
            let entity = CalendarEntity(entityType: entityType,
                                        entityDomain: .ccm,
                                        entityOperate: .ccmShare,
                                        operatorTenantId: operateTenantId,
                                        operatorUid: operateUserId,
                                        fileBizDomain: .calendar,
                                        token: token,
                                        ownerTenantId: ownerTenantId,
                                        ownerUserId: ownerUserId,
                                        tokenEntityType: tokenEntityType)
            return PolicyModel(.ccmFileDownload, entity)
        case .ccmContentPreview(entityType: let entityType, operateTenantId: let operateTenantId, operateUserId: let operateUserId):
            let entity = CalendarEntity(entityType: entityType,
                                        entityDomain: .ccm,
                                        entityOperate: .ccmContentPreview,
                                        operatorTenantId: operateTenantId,
                                        operatorUid: operateUserId,
                                        fileBizDomain: .ccm)
            return PolicyModel(.ccmContentPreview, entity)
        }
    }
}
