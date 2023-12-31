//
//  FolderUserPermissionAPI.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/19.
//

import Foundation
import SpaceInterface
import SKFoundation
import RxSwift
import SwiftyJSON

import SKCommon
import SKInfra

/// Space 2.0 文件夹用户权限 API
class FolderUserPermissionAPI: UserPermissionAPI {
    typealias UserPermissionModel = FolderUserPermission

    let folderToken: String
    let entity: PermissionRequest.Entity
    var offlineUserPermission: FolderUserPermission? { return nil }
    // 打日志用，需要与所属 UserPermissionService 的值保持一致
    let sessionID: String

    init(folderToken: String, sessionID: String) {
        self.folderToken = folderToken
        entity = .ccm(token: folderToken, type: .folder)
        self.sessionID = sessionID
    }

    func updateUserPermission() -> Single<PermissionResult> {

        if folderToken.isEmpty {
            // 空字符串视为我的空间根节点，默认拥有所有用户权限
            return .just(.success(permission: FolderUserPermission.personalRootFolder))
        }

        let folderToken = self.folderToken

        // 与获取文档权限不同，文件夹 actions 传空表示获取所有点位
        let params: [String: Any] = [
            "token": folderToken,
            "actions": []
        ]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getFolderUserPermission, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)

        return request.rxResponse()
            .map { json, error in
                guard let json else {
                    throw error ?? DocsNetworkError.invalidData
                }
                return try Self.parseUserPermission(json: json, error: error, folderToken: folderToken)
            }
    }

    func parseUserPermission(data: Data) throws -> PermissionResult {
        let json = try JSON(data: data)
        return try Self.parseUserPermission(json: json, error: nil, folderToken: folderToken)
    }

    private static func parseUserPermission(json: JSON, error: Error?, folderToken: String) throws -> PermissionResult {
        let data = json["data"]
        let isOwner = data["is_owner"].bool ?? false
        let actions = data["actions"].dictionaryObject as? [String: Int] ?? [:]
        let permission = FolderUserPermission(actions: actions, isOwner: isOwner)

        if let noPermissionResult = try UserPermissionUtils.parseNoPermission(json: json, permission: permission, error: error) {
            return noPermissionResult
        }

        // 有大量业务逻辑隐式依赖了 PermissionManager 中的权限缓存，在新的 SDK 实现中需要暂时同步写入缓存，待后续对缓存的依赖去处后删掉这部分代码
        let legacyPermission = ShareFolderV2UserPermission(json: json)
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)
        permissionManager?.updateUserPermissions([
            folderToken: legacyPermission
        ])
        return .success(permission: permission)
    }

    func container(for permissionResult: PermissionResult) -> PermissionContainerResponse {
        switch permissionResult {
        case let .success(permission):
            let container = FolderUserPermissionContainer(userPermission: permission)
            return .success(container: container)
        case let .noPermission(permission, statusCode, applyUserInfo):
            if let permission {
                let container = FolderUserPermissionContainer(userPermission: permission)
                return .noPermission(container: container, statusCode: statusCode, applyUserInfo: applyUserInfo)
            } else {
                return .noPermission(container: nil, statusCode: statusCode, applyUserInfo: applyUserInfo)
            }
        }
    }
}
