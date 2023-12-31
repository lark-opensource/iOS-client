//
//  LegacyFolderUserPermissionAPI.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/19.
//

import Foundation
import SpaceInterface
import SKFoundation
import RxSwift
import SwiftyJSON

import SKInfra
import SKCommon

private extension SpaceV1FolderInfo {
    func isOwner(userID: String) -> Bool {
        switch folderType {
        case .personal:
            return true
        case let .share(_, _, ownerID):
            return userID == ownerID
        }
    }
}

class LegacyFolderUserPermissionAPI: UserPermissionAPI {
    typealias UserPermissionModel = LegacyFolderUserPermission

    private let userID: String
    private let folderInfo: SpaceV1FolderInfo
    let entity: PermissionRequest.Entity
    var offlineUserPermission: LegacyFolderUserPermission? { return nil }
    // 打日志用，需要与所属 UserPermissionService 的值保持一致
    let sessionID: String

    init(userID: String, folderInfo: SpaceV1FolderInfo, sessionID: String) {
        self.userID = userID
        self.folderInfo = folderInfo
        entity = .ccm(token: folderInfo.token, type: .folder)
        self.sessionID = sessionID
    }

    func updateUserPermission() -> Single<PermissionResult> {
        let folderInfo = self.folderInfo
        switch folderInfo.folderType {
        case .personal:
            // 非共享文件夹，默认有编辑权限
            let permission = LegacyFolderUserPermission(folderInfo: folderInfo,
                                                        isOwner: true,
                                                        role: .editor)
            return .just(.success(permission: permission))
        case let .share(spaceID, _, ownerID):
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getLegacyFolderUserPermission, params: ["space_id": spaceID])
                .set(method: .GET)
            let isOwner = userID == ownerID
            return request.rxResponse()
                .map { json, error in
                    guard let json else {
                        throw error ?? DocsNetworkError.invalidData
                    }
                    return try Self.parseUserPermission(json: json, error: error, folderInfo: folderInfo, isOwner: isOwner)
                }
        }
    }

    func parseUserPermission(data: Data) throws -> PermissionResult {
        let json = try JSON(data: data)
        let isOwner = folderInfo.isOwner(userID: userID)
        return try Self.parseUserPermission(json: json, error: nil, folderInfo: folderInfo, isOwner: isOwner)
    }

    private static func parseUserPermission(json: JSON,
                                            error: Error?,
                                            folderInfo: SpaceV1FolderInfo,
                                            isOwner: Bool) throws -> PermissionResult {
        let data = json["data"]
        let legacyPermission: UserPermissionMask
        let permission: LegacyFolderUserPermission
        if let roleValue = data["perm"].int {
            legacyPermission = UserPermissionMask.create(withPermRole: roleValue)
            let permissionRole = {
                if let role = LegacyFolderUserPermission.PermissionRole(rawValue: roleValue) {
                    return role
                }

                if roleValue > 2 {
                    return .editor
                } else {
                    return .none
                }
            }()
            permission = LegacyFolderUserPermission(folderInfo: folderInfo,
                                                    isOwner: isOwner,
                                                    role: permissionRole)
        } else {
            legacyPermission = []
            permission = LegacyFolderUserPermission(folderInfo: folderInfo,
                                                    isOwner: false,
                                                    role: .none)
        }
        if let noPermissionResult = try UserPermissionUtils.parseNoPermission(json: json, permission: permission, error: error) {
            return noPermissionResult
        }

        // 有大量业务逻辑隐式依赖了 PermissionManager 中的权限缓存，在新的 SDK 实现中需要暂时同步写入缓存，待后续对缓存的依赖去处后删掉这部分代码
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)
        permissionManager?.updateUserPermissions([
            folderInfo.token: legacyPermission
        ])
        return .success(permission: permission)
    }

    func container(for permissionResult: PermissionResult) -> PermissionContainerResponse {
        switch permissionResult {
        case let .success(permission):
            let container = LegacyFolderUserPermissionContainer(userPermission: permission)
            return .success(container: container)
        case let .noPermission(permission, statusCode, applyUserInfo):
            if let permission {
                let container = LegacyFolderUserPermissionContainer(userPermission: permission)
                return .noPermission(container: container, statusCode: statusCode, applyUserInfo: applyUserInfo)
            } else {
                return .noPermission(container: nil, statusCode: statusCode, applyUserInfo: applyUserInfo)
            }
        }
    }
}
