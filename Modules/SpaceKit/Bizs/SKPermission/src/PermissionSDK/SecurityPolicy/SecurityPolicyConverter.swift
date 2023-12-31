//
//  SecurityPolicyConverter.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/19.
//

import Foundation
import SpaceInterface
import SKFoundation
import ServerPB
import LarkSecurityComplianceInterface

enum SecurityPolicyConverter {
    typealias Logger = PermissionSDKLogger
    static func convertPolicyModel(request: PermissionRequest, operatorUserID: Int64, operatorTenantID: Int64) -> PolicyModel? {
        let entityType = convertEntityType(request: request)
        let entityDomain = convertEntityDomain(entity: request.entity, bizDomain: request.bizDomain)
        guard let entityOperation = convertEntityOperation(request: request) else {
            Logger.info("SecurityPolicy.Converter - failed to convert request to entity operation",
                        extraInfo: ["operation": request.operation],
                        traceID: request.traceID)
            // 不需要进行检查
            return nil
        }
        let entity: PolicyEntity
        switch request.bizDomain {
        case let .customCCM(fileBizDomain):
            let ccmEntity = CCMEntity(entityType: entityType,
                                      entityDomain: entityDomain,
                                      entityOperate: entityOperation,
                                      operatorTenantId: operatorTenantID,
                                      operatorUid: operatorUserID,
                                      fileBizDomain: fileBizDomain)
            if dlpRelevantOperations.contains(entityOperation),
               case let .ccm(token, type, hostMeta) = request.entity {
                if let dlpMeta = request.extraInfo.overrideDLPMeta {
                    ccmEntity.token = dlpMeta.objToken
                    ccmEntity.tokenEntityType = convertEntityType(docsType: dlpMeta.objType)
                } else if let dlpMeta = hostMeta {
                    ccmEntity.token = dlpMeta.objToken
                    ccmEntity.tokenEntityType = convertEntityType(docsType: dlpMeta.objType)
                } else {
                    ccmEntity.token = token
                    ccmEntity.tokenEntityType = convertEntityType(docsType: type)
                }
            }
            entity = ccmEntity
        case let .customIM(fileBizDomain, senderUserID, senderTenantID, msgID, fileKey, chatID, chatType):
            entity = IMFileEntity(entityType: entityType,
                                  entityDomain: entityDomain,
                                  entityOperate: entityOperation,
                                  operatorTenantId: operatorTenantID,
                                  operatorUid: operatorUserID,
                                  fileBizDomain: fileBizDomain,
                                  senderUserId: senderUserID,
                                  senderTenantId: senderTenantID,
                                  msgId: msgID,
                                  fileKey: fileKey,
                                  chatID: chatID,
                                  chatType: chatType)
        }
        let pointKey = convertPointKey(entityOperation: entityOperation)
        Logger.verbose("SecurityPolicy.Converter - convert Policy Model complete",
                       extraInfo: [
                        "entityType":entityType,
                        "entityDomain": entityDomain,
                        "entityOperation": entityOperation,
                        "bizDomain": request.bizDomain.desensitizeDescription,
                        "pointKey": pointKey
                       ],
                       traceID: request.traceID)
        return PolicyModel(pointKey, entity)
    }

    private static func convertEntityType(request: PermissionRequest) -> EntityType {
        // 老逻辑中，上传下载操作需要强制修正为 EntityType.file
        switch request.operation {
        case .upload, .uploadAttachment,
                .download, .downloadAttachment:
            return .file
        default:
            // 其他继续往下走转换逻辑
            break
        }
        let entity = request.entity
        switch entity {
        case let .ccm(_, type, _):
            return convertEntityType(docsType: type)
        case let .driveSDK(domain, _):
            switch domain {
            case .imFile:
                switch request.bizDomain {
                case .customIM:
                    return .imMsgFile
                case .customCCM:
                    return .file
                }
            case .openPlatformAttachment:
                spaceAssertionFailure("open platform attachment not define")
                return .file
            case .calendarAttachment:
                spaceAssertionFailure("calendar attachment not define")
                return .file
            case .mailAttachment:
                spaceAssertionFailure("mail attachment not define")
                return .file
            }
        }
    }

    static func convertEntityType(docsType: DocsType) -> EntityType {
        switch docsType {
        case .doc:
            return .doc
        case .docX:
            return .docx
        case .sheet:
            return .sheet
        case .bitable:
            return .bitable
        case .mindnote:
            return .mindnote
        case .slides:
            return .slides
        case .file:
            return .file
        case .folder:
            return .spaceCatalog
        case .imMsgFile:
            spaceAssertionFailure("prefer DriveSDK + imFile domain instead of DocsType.imMsgFile")
            return .imMsgFile
        case .wiki:
            spaceAssertionFailure("use wiki content type for CAC validation")
            return .doc
        default:
            spaceAssertionFailure("docType: \(docsType) convertion rule not define")
            return .doc
        }
    }

    static func convertEntityDomain(entity: PermissionRequest.Entity, bizDomain: PermissionRequest.BizDomain) -> EntityDomain {
        switch entity {
        case let .ccm(_, type, _):
            switch type {
            case .imMsgFile:
                spaceAssertionFailure("prefer DriveSDK + imFile domain instead of DocsType.imMsgFile")
                return .im
            default:
                return .ccm
            }
        case let .driveSDK(domain, _):
            switch domain {
            case .imFile:
                // TODO: 和安卓对齐
                switch bizDomain {
                case .customIM:
                    return .im
                case .customCCM:
                    return .ccm
                }
            case .calendarAttachment:
                return .calendar
            case .openPlatformAttachment:
                return .ccm
            case .mailAttachment:
                return .ccm
            }
        }
    }

    // 转换为 CAC 的点位，nil 表示此请求不需要进行 CAC 校验
    private static func convertEntityOperation(request: PermissionRequest) -> EntityOperate? {
        switch request.operation {
        case .export:
            if case let .ccm(_, type, _) = request.entity,
               type == .file {
                spaceAssertionFailure("ccm file type should not use export operation")
            }
            return .ccmExport
        case .view, .preview:
            switch request.entity {
            case let .ccm(_, type, _) where type == .file:
                return .ccmFilePreView
            case let .driveSDK(domain, _) where domain == .imFile:
                return .ccmFilePreView
            default:
                return .ccmContentPreview
            }
        case .copyContent:
            switch request.bizDomain {
            case .customIM:
                return .imFileCopy
            case .customCCM:
                return .ccmCopy
            }
        case .createCopy, .importToOnlineDocument:
            return .ccmCreateCopy
        case .upload:
            switch request.bizDomain {
            case .customIM:
                return .imFileUpload
            case .customCCM:
                return .ccmFileUpload
            }
        case .download, .openWithOtherApp, .save:
            if case let .ccm(_, type, _) = request.entity,
               type != .file {
                spaceAssertionFailure("ccm non-file type should not use download operation")
            }
            switch request.bizDomain {
            case .customIM:
                return .imFileDownload
            case .customCCM:
                return .ccmFileDownload
            }
        case .downloadAttachment:
            return .ccmAttachmentDownload
        case .uploadAttachment:
            return .ccmAttachmentUpload
        case .shareToExternal:
            return .openExternalAccess
        default:
            return nil
        }
    }

    static func convertAuthEntity(request: PermissionRequest, entityOperation: EntityOperate, needKAConvertion: Bool) -> AuthEntity {
        let entity = SecurityAuditConverter.convertEntity(entity: request.entity)
        let originPermissionType = convertPermissionType(entityOperation: entityOperation)
        var permissionType = originPermissionType
        if needKAConvertion {
            permissionType = convertPermissionTypeForKAHuaQin(permissionType: permissionType, entity: request.entity)
        }
        Logger.verbose("SecurityPolicy.Converter - convert Auth Entity complete",
                       extraInfo: [
                        "permisisonType": permissionType,
                        "needKAConvertion": needKAConvertion,
                        "originPermissionType": originPermissionType,
                        "entity": "type:\(entity.entityType), id:\(DocsTracker.encrypt(id: entity.id))"
                       ],
                       traceID: request.traceID)
        return AuthEntity(permType: permissionType, entity: entity)
    }

    /// 安全 SDK 内转换 admin 精细化管控的权限操作类型， nil 表示不需要通过安全 SDK 进行精细化管控判断
    private static func convertPermissionType(entityOperation: EntityOperate) -> PermissionType {
        switch entityOperation {
        case .ccmFileUpload, .ccmAttachmentUpload:
            return .fileUpload
        case .ccmFileDownload, .ccmAttachmentDownload:
            return .fileDownload
        case .ccmExport:
            return .fileExport
        case .ccmCopy, .ccmCreateCopy:
            return .fileCopy
        case .ccmFilePreView:
            return .localFilePreview
        case .ccmContentPreview:
            return .docPreviewAndOpen
        case .ccmMoveRecycleBin:
            return .fileDelete
        case .imFileDownload:
            return .fileDownload
        case .imFileCopy:
            return .fileCopy
        case .imFilePreview:
            return .localFilePreview
        case .imFileRead:
            return .fileRead
        case .openExternalAccess:
            return .unknown
        default:
            spaceAssertionFailure("convertion for operation: \(entityOperation) not defined")
            return .unknown
        }
    }

    /// KA_HQ 的特殊转换逻辑 https://bytedance.feishu.cn/docx/WNaFdA46HobJbRxK4ZWcZpcNnmb
    private static func convertPermissionTypeForKAHuaQin(permissionType: PermissionType,
                                                 entity: PermissionRequest.Entity) -> PermissionType {
        guard case let .ccm(_, type, _) = entity else {
            return permissionType
        }
        let typeAllowList: [DocsType] = [.doc, .docX, .sheet, .mindnote, .bitable, .slides]
        guard typeAllowList.contains(type) else {
            return permissionType
        }
        switch permissionType {
        case .fileDownload:
            return .docDownload
        case .fileExport:
            return .docExport
        @unknown default:
            return permissionType
        }
    }

    static func convertPointKey(entityOperation: EntityOperate) -> PointKey {
        switch entityOperation {
        case .ccmCopy:
            return .ccmCopy
        case .ccmExport:
            return .ccmExport
        case .ccmAttachmentDownload:
            return .ccmAttachmentDownload
        case .ccmAttachmentUpload:
            return .ccmAttachmentUpload
        case .ccmContentPreview:
            return .ccmContentPreview
        case .ccmFilePreView:
            return .ccmFilePreView
        case .ccmCreateCopy:
            return .ccmCreateCopy
        case .ccmFileUpload:
            return .ccmFileUpload
        case .ccmFileDownload:
            return .ccmFileDownload
        case .ccmMoveRecycleBin:
            return .ccmMoveRecycleBin
        case .imFileDownload:
            return .imFileDownload
        case .imFileCopy:
            return .imFileCopy
        case .imFilePreview:
            return .imFilePreview
        case .imFileRead:
            return .imFileRead
        case .openExternalAccess:
            return .ccmOpenExternalAccess
        default:
            spaceAssertionFailure("invalid entityOperate")
            return .ccmCopy
        }
    }
}
