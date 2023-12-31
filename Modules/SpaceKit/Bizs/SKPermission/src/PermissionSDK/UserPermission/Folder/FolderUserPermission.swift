//
//  FolderUserPermission.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/19.
//

import Foundation
import SpaceInterface
import SKFoundation

typealias FolderUserPermissionService = UserPermissionServiceImpl<FolderUserPermission>
extension FolderUserPermissionService {
    convenience init(folderToken: String, permissionSDK: PermissionSDKInterface, sessionID: String) {
        let permissionAPI = FolderUserPermissionAPI(folderToken: folderToken, sessionID: sessionID)
        self.init(permissionAPI: permissionAPI,
                  validatorType: FolderUserPermissionValidator.self,
                  permissionSDK: permissionSDK,
                  sessionID: sessionID)
    }
}

// Space 2.0 文件夹用户权限模型，对应后端接口 /permission/space/collaborator/perm/
struct FolderUserPermission {

    typealias DenyReason = PermissionResponse.DenyType.UserPermissionDenyReason

    let actions: [String: Int]
    let isOwner: Bool

    func check(action: Action) -> Bool {
        guard let actionCode = actions[action.rawValue] else { return false }
        return actionCode == Self.rightCode
    }

    func denyReason(for action: Action) -> DenyReason? {
        guard let actionCode = actions[action.rawValue] else { return .unknown }
        switch actionCode {
        case Self.rightCode:
            return nil
        case Self.blockByCACCode:
            return .blockByCAC
        default:
            return .blockByServer(code: actionCode)
        }
    }
}


extension FolderUserPermission {
    /// 文件夹权限模型的后端点位
    enum Action: String, CaseIterable {
        case view
        case edit
        case manageCollaborator = "manage_collaborator"
        case manageMeta = "manage_meta"
        case createSubNode = "create_sub_node"
        case download
        case collect
        case operateEntity = "operate_entity"
        case inviteFullAccess = "invite_full_access"
        case inviteCanEdit = "invite_can_edit"
        case inviteCanView = "invite_can_view"
        case beMoved = "be_moved"
        case moveFrom = "move_from"
        case moveTo = "move_to"
    }


    /// 有权限时点位的值
    static let rightCode = 1
    /// 受 CAC 管控无权限时点位的值
    static let blockByCACCode = 2002
}

extension FolderUserPermission {
    static var personalRootFolder: Self {
        var actions: [String: Int] = [:]
        Action.allCases.forEach { action in
            actions[action.rawValue] = rightCode
        }
        return FolderUserPermission(actions: actions, isOwner: true)
    }
}

struct FolderUserPermissionContainer: UserPermissionContainer {
    let userPermission: FolderUserPermission
    // 文件夹目前不支持 leader 自动授权
    var grantedViewPermissionByLeader: Bool { false }
    // 文件夹在有权限时不提供 statusCode，因为文件夹通过列表接口判断是否需要申诉
    var statusCode: UserPermissionResponse.StatusCode {
        spaceAssertionFailure("folder status code is invalid")
        return .normal
    }

    var isOwner: Bool { userPermission.isOwner }

    /// 是否被 CAC 管控分享能力，文件夹只看 view 点位
    var shareControlByCAC: Bool {
        userPermission.denyReason(for: .view) == .blockByCAC
    }
    /// 是否被 CAC 管控预览点位，文件夹没有这个场景
    var previewControlByCAC: Bool {
        false
    }
    /// 是否被 Admin 精细化管控预览点位，文件夹没有这个场景
    var previewBlockByAdmin: Bool {
        false
    }

    var viewBlockByAudit: Bool { false }
}
