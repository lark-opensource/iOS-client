//
//  DriveThirdPartyAttachmentPermissionAPI.swift
//  SKDrive
//
//  Created by Weston Wu on 2023/8/23.
//

import Foundation
import SpaceInterface
import SKFoundation
import RxSwift
import SwiftyJSON
import SKCommon
import SKInfra

class DriveThirdPartyAttachmentPermissionAPI: UserPermissionAPI {
    typealias UserPermissionModel = DriveThirdPartyAttachmentPermission

    let fileToken: String
    let mountPoint: String
    let authExtra: String?

    let entity: PermissionRequest.Entity

    var offlineUserPermission: UserPermissionModel? {
        return cache.userPermission(for: fileToken)
    }

    let sessionID: String
    let cache: DriveThirdPartyAttachmentPermissionCache

    init(fileToken: String,
         mountPoint: String,
         authExtra: String?,
         sessionID: String,
         cache: DriveThirdPartyAttachmentPermissionCache) {
        self.fileToken = fileToken
        self.mountPoint = mountPoint
        self.authExtra = authExtra
        entity = .ccm(token: fileToken, type: .file)
        self.sessionID = sessionID
        self.cache = cache
    }

    func updateUserPermission() -> Single<PermissionResult> {
        var params = [
            "file_token": fileToken,
            "mount_point": mountPoint
        ]
        if let authExtra {
            params["extra"] = authExtra
        }
        let sessionID = self.sessionID
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.attachmentPermission,
                                        params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        return request.rxResponse().map { [weak self] json, error in
            if let error {
                DocsLogger.error("request attachment permission failed", extraInfo: ["sessionID": sessionID], error: error)
                throw error
            }
            guard let json,
                  let code = json["code"].int else {
                DocsLogger.error("parse attachment permission code failed", extraInfo: ["sessionID": sessionID])
                throw DriveError.permissionError
            }
            guard code == 0 else {
                DocsLogger.error("request attachment permission code failed with code: \(code)", extraInfo: ["sessionID": sessionID])
                throw DriveError.serverError(code: code)
            }
            let result = Self.parsePermission(json: json)
            self?.saveUserPermission(with: result)
            DocsLogger.error("request attachment permission success", extraInfo: ["sessionID": sessionID, "permission": result])
            return result
        }
    }

    func parseUserPermission(data: Data) throws -> PermissionResult {
        let json = try JSON(data: data)
        let result = Self.parsePermission(json: json)
        saveUserPermission(with: result)
        return result
    }

    func saveUserPermission(with result: PermissionResult?) {
        guard let userPermission = result?.userPermission else { return }
        cache.set(userPermission: userPermission, token: fileToken)
    }

    func container(for result: PermissionResult) -> PermissionContainerResponse {
        switch result {
        case let .success(permission):
            let container = DriveThirdPartyAttachmentPermissionContainer(userPermission: permission)
            return .success(container: container)
        case let .noPermission(permission, statusCode, applyUserInfo):
            if let permission {
                let container = DriveThirdPartyAttachmentPermissionContainer(userPermission: permission)
                return .noPermission(container: container, statusCode: statusCode, applyUserInfo: applyUserInfo)
            } else {
                return .noPermission(container: nil, statusCode: statusCode, applyUserInfo: applyUserInfo)
            }
        }
    }

    private typealias Action = DriveThirdPartyAttachmentPermission.Action
    private typealias Status = DriveThirdPartyAttachmentPermission.Status

    private static func parsePermission(json: JSON) -> PermissionResult {
        let v2Data = json["data"]["perm_v2"].dictionaryObject
        let permissionInfo = json["data"].dictionaryObject ?? [:]
        var actions = [Action: Status]()
        Action.allCases.forEach { action in
            let code = v2Data?[action.rawValue] as? Int
            if code == DriveThirdPartyAttachmentPermission.blockByCACCode {
                actions[action] = .blockByCAC
                return
            }
            if code == DriveThirdPartyAttachmentPermission.blockByAudit {
                actions[action] = .blockByAudit
                return
            }
            let allow = permissionInfo[action.rawValue] as? Bool ?? false
            actions[action] = allow ? .allow : .forbidden(code: code)
        }
        let permission = DriveThirdPartyAttachmentPermission(actions: actions, bizExtraInfo: v2Data)
        return .success(permission: permission)
    }
}
