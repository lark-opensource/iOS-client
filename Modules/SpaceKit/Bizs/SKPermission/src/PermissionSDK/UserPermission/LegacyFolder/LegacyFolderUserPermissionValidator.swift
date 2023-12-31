//
//  LegacyFolderUserPermissionValidator.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/19.
//

import Foundation
import SpaceInterface
import SKFoundation

struct LegacyFolderUserPermissionValidator: UserPermissionValidator {

    static var name: String { "LegacyFolderUserPermissionValidator" }
    var name: String { Self.name }

    typealias UserPermissionModel = LegacyFolderUserPermission
    let userPermission: LegacyFolderUserPermission?
    let isFromCache: Bool

    init(model: LegacyFolderUserPermission?, isFromCache: Bool) {
        self.userPermission = model
        self.isFromCache = isFromCache
    }

    func validate(request: PermissionRequest) -> PermissionValidatorResponse {
        Logger.verbose("UserPermission.LegacyFolder - start validate request", traceID: request.traceID)
        guard request.operation.shouldHandleByLegacyFolderValidator else {
            Logger.info("UserPermission.LegacyFolder - skipped, irrelevant operation for legacy folder permission",
                        extraInfo: ["operation": request.operation],
                        traceID: request.traceID)
            return .pass
        }
        guard let userPermission else {
            Logger.warning("UserPermission.LegacyFolder - return forbidden response when validate action without user permission",
                           traceID: request.traceID)
            // 鉴权时，若还没请求到用户权限，直接报错
            return .forbidden(denyType: .blockByUserPermission(reason: .userPermissionNotReady),
                              defaultUIBehaviorType: UserPermissionUtils.defaultUIBehaviorType(request: request))
        }
        guard !isFromCache else {
            Logger.warning("UserPermission.LegacyFolder - return forbidden response when validate action not support cache",
                           traceID: request.traceID)
            return .forbidden(denyType: .blockByUserPermission(reason: .cacheNotSupport),
                              defaultUIBehaviorType: UserPermissionUtils.defaultUIBehaviorType(request: request))
        }

        Logger.verbose("UserPermission.LegacyFolder - checking user permission",
                       extraInfo: [
                        "role": userPermission.role,
                        "operation": request.operation
                       ],
                       traceID: request.traceID)
        if validate(operation: request.operation, permission: userPermission) {
            Logger.info("UserPermission.LegacyFolder - user permission pass, return allow response",
                        traceID: request.traceID)
            return .pass
        } else {
            Logger.warning("UserPermission.LegacyFOlder - user permission failed, return forbidden response",
                           traceID: request.traceID)
            return .forbidden(denyType: .blockByUserPermission(reason: .unknown),
                              defaultUIBehaviorType: UserPermissionUtils.defaultUIBehaviorType(request: request))
        }
    }

    func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionValidatorResponse) -> Void) {
        Logger.verbose("UserPermission.LegacyFolder - async validate not impl, fallback to sync validate request", traceID: request.traceID)
        // 用户权限检查没有所谓的异步鉴权逻辑，与同步鉴权相同
        let response = validate(request: request)
        completion(response)
    }

    private func validate(operation: PermissionRequest.Operation, permission: LegacyFolderUserPermission) -> Bool {
        switch operation {
        case .view:
            return permission.satisfy(role: .viewer)
        case .edit:
            return permission.satisfy(role: .editor)
        case .manageCollaborator:
            switch permission.folderInfo.folderType {
            case .personal:
                return true
            case let .share(_, isRoot, _):
                return isRoot && permission.satisfy(role: .viewer)
            }
        case .managePermissionMeta:
            switch permission.folderInfo.folderType {
            case .personal:
                // 个人文件夹没有相关选项
                return false
            case let .share(_, isRoot, _):
                // 共享文件夹只有 owner 才能改
                return permission.isOwner && isRoot
            }
        case .inviteFullAccess:
            // 1.0 文件夹没有 FA
            return false
        case .inviteEdit:
            return permission.satisfy(role: .editor)
        case .inviteView:
            return permission.satisfy(role: .viewer)
        case .moveThisNode:
            return permission.satisfy(role: .editor)
        case .moveToHere:
            return permission.satisfy(role: .editor)
        case .moveSubNode:
            return permission.satisfy(role: .editor)
        case .createSubNode:
            return permission.satisfy(role: .editor)
        default:
            // 命中 assert 说明新增了 legacyFolderOperations，但是没有实现鉴权逻辑
            spaceAssertionFailure("operation not in legacyFolderOperations should be filter")
            return false
        }
    }
}

extension PermissionRequest.Operation {
    static var legacyFolderOperations: [PermissionRequest.Operation] {
        [
            .view,
            .edit,
            .manageCollaborator,
            .managePermissionMeta,
            .inviteFullAccess,
            .inviteEdit,
            .inviteView,
            .moveThisNode,
            .moveToHere,
            .moveSubNode,
            .createSubNode
        ]
    }

    fileprivate var shouldHandleByLegacyFolderValidator: Bool {
        let result = Self.legacyFolderOperations.contains(self)
        if !result {
            PermissionSDKLogger.undefinedValidation(operation: self, validator: LegacyFolderUserPermissionValidator.name)
        }
        return result
    }
}
