//
//  DocumentUserPermissionService.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation
import SpaceInterface
import SKFoundation
import RxSwift
import SwiftyJSON

import SKCommon
import SKInfra

class DocumentUserPermissionAPI: UserPermissionAPI {
    typealias UserPermissionModel = DocumentUserPermission

    let objToken: String
    let objType: DocsType

    let parentMeta: SpaceMeta?

    let entity: PermissionRequest.Entity
    var offlineUserPermission: UserPermissionModel? {
        return cache.userPermission(for: objToken)
    }
    // 打日志用，需要与所属 UserPermissionService 的值保持一致
    let sessionID: String

    private let cache: DocumentUserPermissionCache

    init(meta: SpaceMeta, parentMeta: SpaceMeta?, sessionID: String, cache: DocumentUserPermissionCache) {
        objToken = meta.objToken
        objType = meta.objType
        self.parentMeta = parentMeta
        entity = .ccm(token: meta.objToken, type: meta.objType, parentMeta: parentMeta)
        self.sessionID = sessionID
        self.cache = cache
    }

    func updateUserPermission() -> Single<PermissionResult> {
        let actions = DocumentUserPermission.Action.allCases.map(\.rawValue)
        let token = objToken
        var params: [String: Any] = [
            "token": objToken,
            "type": objType.rawValue,
            "actions": actions
        ]
        if let parentMeta {
            spaceAssert(parentMeta.objType != .wiki, "prefer using wiki content obj token and type")
            params["relation"] = [
                "entity_token": parentMeta.objToken,
                "entity_type": parentMeta.objType.rawValue,
                "relation_type": 1 // 1:父；2:子
            ]
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getDocumentUserPermission, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)

        return request.rxResponse()
            .map { [weak self] json, error in
                guard let json else {
                    throw error ?? DocsNetworkError.invalidData
                }

                let result = try Self.parseUserPermission(json: json, error: error, objToken: token)
                self?.saveUserPermission(with: result)
                return result
            }
    }

    func parseUserPermission(data: Data) throws -> PermissionResult {
        let json = try JSON(data: data)
        let result = try Self.parseUserPermission(json: json, error: nil, objToken: objToken)
        saveUserPermission(with: result)
        return result
    }

    func saveUserPermission(with result: PermissionResult?) {
        guard let userPermission = result?.userPermission else { return }
        cache.set(userPermission: userPermission, token: objToken)
    }

    private static func parseUserPermission(json: JSON, error: Error?, objToken: String) throws -> PermissionResult {
        if json["code"].int == DocsNetworkError.Code.entityDeleted.rawValue {
            return .noPermission(permission: nil, statusCode: .entityDeleted, applyUserInfo: nil)
        }
        let data = json["data"]
        let isOwner = data["is_owner"].boolValue
        let actions = data["actions"].dictionaryObject as? [String: Int] ?? [:]
        let authReasons = data["auth_reasons"].dictionaryObject as? [String: Int] ?? [:]
        let statusCodeValue = data["permission_status_code"].intValue
        let statusCode = UserPermissionResponse.StatusCode(rawValue: statusCodeValue)
        let permission = DocumentUserPermission(actions: actions,
                                                authReasons: authReasons,
                                                isOwner: isOwner,
                                                statusCode: statusCode)
        if let noPermission = try UserPermissionUtils.parseNoPermission(json: json, permission: permission, error: error) {
            return noPermission
        }
        // 有大量业务逻辑隐式依赖了 PermissionManager 中的权限缓存，在新的 SDK 实现中需要暂时同步写入缓存，待后续对缓存的依赖去处后删掉这部分代码
        let legacyPermission = UserPermission(json: json)
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)
        permissionManager?.updateUserPermissions([
            objToken: legacyPermission
        ])

        return .success(permission: permission)
    }

    func container(for permissionResult: PermissionResult) -> PermissionContainerResponse {
        switch permissionResult {
        case let .success(permission):
            let container = DocumentUserPermissionContainer(userPermission: permission)
            return .success(container: container)
        case let .noPermission(permission, statusCode, applyUserInfo):
            if let permission {
                let container = DocumentUserPermissionContainer(userPermission: permission)
                return .noPermission(container: container, statusCode: statusCode, applyUserInfo: applyUserInfo)
            } else {
                return .noPermission(container: nil, statusCode: statusCode, applyUserInfo: applyUserInfo)
            }
        }
    }
}
