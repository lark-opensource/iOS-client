//
//  LegacyFolderUserPermission.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/19.
//

import Foundation
import SpaceInterface
import SKFoundation

typealias LegacyFolderUserPermissionService = UserPermissionServiceImpl<LegacyFolderUserPermission>
extension LegacyFolderUserPermissionService {
    convenience init(userID: String, folderInfo: SpaceV1FolderInfo, permissionSDK: PermissionSDKInterface, sessionID: String) {
        let permissionAPI = LegacyFolderUserPermissionAPI(userID: userID,
                                                          folderInfo: folderInfo,
                                                          sessionID: sessionID)
        self.init(permissionAPI: permissionAPI,
                  validatorType: LegacyFolderUserPermissionValidator.self,
                  permissionSDK: permissionSDK,
                  sessionID: sessionID)
    }
}

/// Space 1.0 共享文件夹用户权限模型
struct LegacyFolderUserPermission: Equatable {
    let folderInfo: SpaceV1FolderInfo
    let isOwner: Bool
    let role: PermissionRole
    /// 判断是否满足所需的最低权限角色
    func satisfy(role: PermissionRole) -> Bool {
        self.role >= role
    }
}

extension LegacyFolderUserPermission {
    // Space 1.0 没有权限点位概念，只有角色概念
    enum PermissionRole: Int, Comparable, CaseIterable, Equatable {
        case none = 0
        case viewer = 1
        case editor = 2

        static func < (lhs: PermissionRole, rhs: PermissionRole) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

struct LegacyFolderUserPermissionContainer: UserPermissionContainer {

    let userPermission: LegacyFolderUserPermission
    // 文件夹目前不支持 leader 自动授权
    var grantedViewPermissionByLeader: Bool { false }

    // 文件夹在有权限时不提供 statusCode，因为文件夹通过列表接口判断是否需要申诉
    var statusCode: UserPermissionResponse.StatusCode {
        spaceAssertionFailure("legacy folder status code is invalid")
        return .normal
    }

    var isOwner: Bool { userPermission.isOwner }

    var shareControlByCAC: Bool { false }

    var previewControlByCAC: Bool { false }

    var previewBlockByAdmin: Bool { false }

    var viewBlockByAudit: Bool { false }
}
