//
//  FolderUserPermissionValidator.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/19.
//

import Foundation
import SKFoundation
import SpaceInterface

struct FolderUserPermissionValidator: UserPermissionValidator {

    static var name: String { "FolderUserPermissionValidator" }
    var name: String { Self.name }

    typealias UserPermissionModel = FolderUserPermission
    let userPermission: FolderUserPermission?
    let isFromCache: Bool

    init(model: FolderUserPermission?, isFromCache: Bool) {
        self.userPermission = model
        self.isFromCache = isFromCache
    }

    func validate(request: PermissionRequest) -> PermissionValidatorResponse {
        Logger.verbose("UserPermission.Folder - start validate request", traceID: request.traceID)
        guard let action = Self.convert(operation: request.operation) else {
            Logger.info("UserPermission.Folder - skipped, failed to convert operation to folder permission action",
                        extraInfo: ["operation": request.operation],
                        traceID: request.traceID)
            // 取不到点位，说明不需要走 permission 鉴权
            return .pass
        }
        guard let userPermission else {
            Logger.warning("UserPermission.Folder - return forbidden response when validate action without user permission",
                           traceID: request.traceID)
            // 鉴权时，若还没请求到用户权限，直接报错
            return .forbidden(denyType: .blockByUserPermission(reason: .userPermissionNotReady),
                              defaultUIBehaviorType: UserPermissionUtils.defaultUIBehaviorType(request: request))
        }

        guard !isFromCache else {
            Logger.warning("UserPermission.Folder - return forbidden response when validate action not support cache",
                           traceID: request.traceID)
            return .forbidden(denyType: .blockByUserPermission(reason: .cacheNotSupport),
                              defaultUIBehaviorType: UserPermissionUtils.defaultUIBehaviorType(request: request))
        }

        if userPermission.check(action: action) {
            Logger.info("UserPermission.Folder - user permission pass, return allow response",
                        traceID: request.traceID)
            return .pass
        }
        let reason = userPermission.denyReason(for: action) ?? .unknown
        Logger.warning("UserPermission.Folder - user permission failed, return forbidden response",
                       extraInfo: [
                        "action": action,
                        "reason": reason
                       ],
                       traceID: request.traceID)
        return .forbidden(denyType: .blockByUserPermission(reason: reason),
                          defaultUIBehaviorType: UserPermissionUtils.defaultUIBehaviorType(request: request))
    }

    func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionValidatorResponse) -> Void) {
        Logger.verbose("UserPermission.Folder - async validate not impl, fallback to sync validate request", traceID: request.traceID)
        // 用户权限检查没有所谓的异步鉴权逻辑，与同步鉴权相同
        let response = validate(request: request)
        completion(response)
    }

    /// 转换为文件夹用户权限的点位
    static func convert(operation: PermissionRequest.Operation) -> FolderUserPermission.Action? {
        switch operation {
        case .view, .perceive:
            return .view
        case .edit:
            return .edit
        case .manageCollaborator:
            return .manageCollaborator
        case .managePermissionMeta:
            return .manageMeta
        case .inviteFullAccess:
            return .inviteFullAccess
        case .inviteEdit:
            return .inviteCanEdit
        case .inviteView:
            return .inviteCanView
        case .moveThisNode:
            return .beMoved
        case .moveToHere:
            return .moveTo
        case .moveSubNode:
            return .moveFrom
        case .createSubNode:
            return .createSubNode
        case .applyEmbed,
                .preview,
                .comment,
                .copyContent,
                .createCopy,
                .delete,
                .deleteEntity,
                .deleteVersion,
                .download,
                .downloadAttachment,
                .export,
                .inviteSinglePageEdit,
                .inviteSinglePageFullAccess,
                .inviteSinglePageView,
                .isContainerFullAccess,
                .isSinglePageFullAccess,
                .manageContainerCollaborator,
                .manageContainerPermissionMeta,
                .manageSinglePageCollaborator,
                .manageSinglePagePermissionMeta,
                .manageVersion,
                .modifySecretLabel,
                .openWithOtherApp,
                .save,
                .secretLabelVisible,
                .shareToExternal,
                .upload,
                .uploadAttachment,
                .viewCollaboratorInfo,
                .updateTimeZone,
                .importToOnlineDocument,
                .moveSheetTab:
            Logger.undefinedValidation(operation: operation, validator: Self.name)
            return nil
        }
    }
}
