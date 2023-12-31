//
//  SecurityAuditConverter.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/19.
//

import Foundation
import SpaceInterface
import SKFoundation
import SKResource
import LarkSecurityAudit
import ServerPB

enum SecurityAuditConverter {
    static func convertEntity(entity: PermissionRequest.Entity) -> Entity {
        let entityType: ServerPB_Authorization_EntityType
        switch entity {
        case let .ccm(token, type, _):
            switch type {
            case .doc:
                entityType = .ccmDoc
            case .sheet:
                entityType = .ccmSheet
            case .bitable, .baseAdd:
                entityType = .ccmBitable
            case .mindnote:
                entityType = .ccmMindnote
            case .file:
                entityType = .ccmFile
            case .slides:
                entityType = .ccmSlide
            case .imMsgFile:
                spaceAssertionFailure("prefer DriveSDK + imFile domain instead of DocsType.imMsgFile")
                entityType = .imFile
            case .folder, .trash, .myFolder, .wiki, .mediaFile, .docX, .wikiCatalog, .minutes, .unknown, .whiteboard, .sync:
                entityType = .unknown
            }
            var authEntity = Entity()
            authEntity.entityType = entityType
            authEntity.id = token
            return authEntity
        case let .driveSDK(domain, fileID):
            switch domain {
            case .imFile:
                entityType = .imFile
            case .openPlatformAttachment,
                    .calendarAttachment,
                    .mailAttachment:
                entityType = .unknown
            }
            var authEntity = Entity()
            authEntity.entityType = entityType
            authEntity.id = fileID
            return authEntity
        }
    }

    /// Admin 精细化管控大部分收敛到了安全 SDK 内，端上直接判断的仅剩下 .shareToExternal
    static func convertLegacyPermissionType(operation: PermissionRequest.Operation) -> PermissionType? {
        switch operation {
        case .shareToExternal:
            return .fileShare
        default:
            return nil
        }
    }

    static func toastMessage(operation: PermissionRequest.Operation) -> String {
        return BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast
    }
}
