//
//  DocumentUserPermissionValidator.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation
import SKFoundation
import SpaceInterface

struct DocumentUserPermissionValidator: UserPermissionValidator {

    static var name: String { "DocumentUserPermissionValidator" }
    var name: String { Self.name }

    typealias UserPermissionModel = DocumentUserPermission

    typealias Action = DocumentUserPermission.Action
    typealias ComposeAction = DocumentUserPermission.ComposeAction

    private let userPermission: DocumentUserPermission?
    private let isFromCache: Bool

    init(model: DocumentUserPermission?, isFromCache: Bool) {
        self.userPermission = model
        self.isFromCache = isFromCache
    }

    func validate(request: PermissionRequest) -> PermissionValidatorResponse {
        Logger.verbose("UserPermission.Document - start validate request", traceID: request.traceID)
        if let composeAction = Self.convertComposeAction(operation: request.operation) {
            Logger.verbose("UserPermission.Document - validate compseAction: \(composeAction)",
                        traceID: request.traceID)
            return validate(request: request, composeAction: composeAction)
        } else if let action = Self.convertAction(operation: request.operation) {
            Logger.verbose("UserPermission.Document - validate action: \(action)",
                        traceID: request.traceID)
            return validate(request: request, action: action)
        } else {
            Logger.info("UserPermission.Document - skipped, failed to convert operation to document permission action",
                        extraInfo: ["operation": request.operation],
                        traceID: request.traceID)
            // 转换不到 action 表示不需要通过 UserPermission 鉴权
            return .pass
        }
    }

    func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionValidatorResponse) -> Void) {
        Logger.verbose("UserPermission.Document - async validate not impl, fallback to sync validate request", traceID: request.traceID)
        // 用户权限检查没有所谓的异步鉴权逻辑，与同步鉴权相同
        let response = validate(request: request)
        completion(response)
    }

    private func validate(request: PermissionRequest, action: Action) -> PermissionValidatorResponse {
        guard let userPermission else {
            Logger.warning("UserPermission.Document - return forbidden response when validate action without user permission",
                           traceID: request.traceID)
            // 鉴权时，若还没请求到用户权限，直接报错
            return .forbidden(denyType: .blockByUserPermission(reason: .userPermissionNotReady),
                              defaultUIBehaviorType: UserPermissionUtils.defaultUIBehaviorType(request: request))
        }

        guard !isFromCache || request.operation.isOfflineEnabled else {
            Logger.warning("UserPermission.Document - return forbidden response when validate action not support cache",
                           traceID: request.traceID)
            return .forbidden(denyType: .blockByUserPermission(reason: .cacheNotSupport),
                              defaultUIBehaviorType: UserPermissionUtils.defaultUIBehaviorType(request: request))
        }

        if userPermission.check(action: action) {
            Logger.info("UserPermission.Document - user permission pass, return allow response",
                        traceID: request.traceID)
            return .pass
        }
        let reason = userPermission.denyReason(for: action) ?? .normal(denyReason: .unknown)
        Logger.warning("UserPermission.Document - user permission failed, return forbidden response",
                    extraInfo: [
                        "action": action,
                        "reason": reason
                    ],
                    traceID: request.traceID)
        return response(for: reason, request: request)
    }

    private func validate(request: PermissionRequest, composeAction: ComposeAction) -> PermissionValidatorResponse {
        guard let userPermission else {
            Logger.warning("UserPermission.Document - return forbidden response when validate compose action without user permission",
                           traceID: request.traceID)
            // 鉴权时，若还没请求到用户权限，直接报错
            return .forbidden(denyType: .blockByUserPermission(reason: .userPermissionNotReady),
                              defaultUIBehaviorType: UserPermissionUtils.defaultUIBehaviorType(request: request))
        }

        guard !isFromCache || request.operation.isOfflineEnabled else {
            Logger.warning("UserPermission.LegacyFolder - return forbidden response when validate action not support cache",
                           traceID: request.traceID)
            return .forbidden(denyType: .blockByUserPermission(reason: .cacheNotSupport),
                              defaultUIBehaviorType: UserPermissionUtils.defaultUIBehaviorType(request: request))
        }

        if userPermission.check(action: composeAction) {
            Logger.info("UserPermission.Document - user permission pass, return allow response",
                        traceID: request.traceID)
            return .pass
        }
        let reason = userPermission.denyReason(for: composeAction) ?? .normal(denyReason: .unknown)
        Logger.warning("UserPermission.Document - user permission failed, return forbidden response",
                       extraInfo: [
                        "composeAction": composeAction,
                        "reason": reason
                       ],
                       traceID: request.traceID)
        return response(for: reason, request: request)
    }

    private typealias DenyReason = DocumentUserPermission.DocumentPermissionDenyReason

    private func response(for reason: DenyReason, request: PermissionRequest) -> PermissionValidatorResponse {
        switch reason {
        case .previewBlockBySecurityAudit:
            let message = SecurityAuditConverter.toastMessage(operation: request.operation)
            return .forbidden(denyType: .blockBySecurityAudit,
                              defaultUIBehaviorType: .error(text: message, allowOverrideMessage: false))
        case let .normal(denyReason) where denyReason == .blockByCAC:
            let message = SecurityAuditConverter.toastMessage(operation: request.operation)
            return .forbidden(denyType: .blockByFileStrategy,
                              defaultUIBehaviorType: .error(text: message, allowOverrideMessage: false))
        case let .normal(denyReason) where denyReason == .blockByAudit:
            let message = SecurityAuditConverter.toastMessage(operation: request.operation)
            return .forbidden(denyType: .blockByUserPermission(reason: denyReason),
                              preferUIStyle: UserScopeNoChangeFG.WWJ.auditPermissionControlEnable ? .hidden : .disabled,
                              defaultUIBehaviorType: .error(text: message, allowOverrideMessage: false))
        case let .normal(reason):
            return .forbidden(denyType: .blockByUserPermission(reason: reason),
                              defaultUIBehaviorType: UserPermissionUtils.defaultUIBehaviorType(request: request))
        }
    }

    // 转换为文档用户权限的点位
    static func convertAction(operation: PermissionRequest.Operation) -> Action? {
        switch operation {
        case .export:
            return .export
        case .view:
            return .view
        case .perceive:
            return .perceive
        case .preview:
            return .preview
        case .edit, .moveSheetTab:
            return .edit
        case .copyContent:
            return .copy
        case .createCopy:
            return .duplicate
        case .comment:
            return .comment
        case .createSubNode:
            return .createSubNode
        case .deleteEntity:
            return .operateEntity
        case .inviteFullAccess:
            return .inviteContainerFullAccess
        case .inviteEdit:
            return .inviteContainerCanEdit
        case .inviteView:
            return .inviteContainerCanView
        case .inviteSinglePageFullAccess:
            return .inviteSinglePageFullAccess
        case .inviteSinglePageEdit:
            return .inviteSinglePageCanEdit
        case .inviteSinglePageView:
            return .inviteSinglePageCanView
        case .moveThisNode:
            return .beMoved
        case .moveSubNode:
            return .moveFrom
        case .moveToHere:
            return .moveTo
        case .applyEmbed:
            return .applyEmbed
        case .manageContainerCollaborator:
            return .manageContainerCollaborator
        case .manageContainerPermissionMeta:
            return .manageContainerMeta
        case .manageSinglePageCollaborator:
            return .manageSinglePageCollaborator
        case .manageSinglePagePermissionMeta:
            return .manageSinglePageMeta
        case .secretLabelVisible:
            return .visitSecretLevel
        case .modifySecretLabel:
            return .modifySecretLevel
        case .isContainerFullAccess:
            return .manageContainerMeta
        case .isSinglePageFullAccess:
            return .manageSinglePageMeta
        case .manageVersion:
            return .manageVersion
        case .deleteVersion:
            return .operateEntity
        case .importToOnlineDocument:
            return .download
        case .viewCollaboratorInfo:
            return .showCollaboratorInfo
        case .download:
            return .download
        case .downloadAttachment:
            return .download
        case .updateTimeZone,
                .managePermissionMeta,
                .manageCollaborator,
                .openWithOtherApp:
            // 复合点位
            return nil
            // 无关点位
        case .shareToExternal:
            return nil
        case .delete,
                .save,
                .upload,
                .uploadAttachment:
            Logger.undefinedValidation(operation: operation, validator: Self.name)
            return nil
        }
    }

    // 有新的 case 记得加单测
    static func convertComposeAction(operation: PermissionRequest.Operation) -> ComposeAction? {
        switch operation {
        case .manageCollaborator:
            return .manageCollaborator
        case .managePermissionMeta:
            return .managePermissionMeta
        case .updateTimeZone:
            return .updateTimeZone
        case .openWithOtherApp:
            return .openWithOtherApp
        default:
            return nil
        }
    }
}
