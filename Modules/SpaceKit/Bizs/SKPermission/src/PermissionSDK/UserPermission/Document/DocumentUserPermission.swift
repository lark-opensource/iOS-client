//
//  DocumentUserPermission.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation
import SpaceInterface
import SKFoundation
import LarkCache

typealias DocumentUserPermissionService = UserPermissionServiceImpl<DocumentUserPermission>
extension DocumentUserPermissionService {
    convenience init(meta: SpaceMeta, parentMeta: SpaceMeta?, permissionSDK: PermissionSDKInterface, sessionID: String, userID: String, extraInfo: PermissionExtraInfo?) {
        let cache = DocumentUserPermissionCache(userID: userID)
        let permissionAPI = DocumentUserPermissionAPI(meta: meta, parentMeta: parentMeta, sessionID: sessionID, cache: cache)
        self.init(permissionAPI: permissionAPI,
                  validatorType: DocumentUserPermissionValidator.self,
                  permissionSDK: permissionSDK,
                  sessionID: sessionID,
                  extraInfo: extraInfo)
    }
}

/// 文档用户权限模型，供 CCM 文档使用，对应后端接口 document/action/state
struct DocumentUserPermission: Codable {

    typealias DenyReason = PermissionResponse.DenyType.UserPermissionDenyReason

    let actions: [String: Int]
    let authReasons: [String: Int]
    let isOwner: Bool
    // 有权限时可能也需要用到 statusCode
    let statusCode: UserPermissionResponse.StatusCode

    func check(action: Action) -> Bool {
        guard let actionCode = actions[action.rawValue] else { return false }
        return actionCode == Self.rightCode
    }

    enum DocumentPermissionDenyReason: Equatable {
        case normal(denyReason: DenyReason)
        case previewBlockBySecurityAudit
    }

    func denyReason(for action: Action) -> DocumentPermissionDenyReason? {
        guard let actionCode = actions[action.rawValue] else { return .normal(denyReason: .unknown) }
        switch actionCode {
        case Self.rightCode:
            return nil
        case Self.blockByCACCode:
            return .normal(denyReason: .blockByCAC)
        case Self.blockByAudit:
            return .normal(denyReason: .blockByAudit)
        default:
            if action == .preview, previewBlockByAdmin {
                return .previewBlockBySecurityAudit
            }
            return .normal(denyReason: .blockByServer(code: actionCode))
        }
    }

    func authReason(for action: Action) -> AuthReason? {
        // 不一定有
        guard let authReasonCode = authReasons[action.rawValue] else { return nil }
        return AuthReason(rawValue: authReasonCode)
    }
}

extension DocumentUserPermission {
    /// 文档权限模型的后端点位
    enum Action: String, CaseIterable {
        case view
        case edit
        case comment
        case createSubNode = "create_sub_node"
        case copy
        case download
        case collect
        case operateEntity = "operate_entity"
        case beMoved = "be_moved"
        case moveFrom = "move_from"
        case moveTo = "move_to"
        case print
        case export
        // 容器相关
        case manageContainerCollaborator = "manage_collaborator"
        case manageContainerMeta = "manage_meta"
        case inviteContainerFullAccess = "invite_full_access"
        case inviteContainerCanEdit = "invite_can_edit"
        case inviteContainerCanView = "invite_can_view"
        // 单页面相关
        case manageSinglePageCollaborator = "manage_single_page_collaborator"
        case manageSinglePageMeta = "manage_single_page_meta"
        case inviteSinglePageFullAccess = "invite_single_page_full_access"
        case inviteSinglePageCanEdit = "invite_single_page_can_edit"
        case inviteSinglePageCanView = "invite_single_page_can_view"

        // 密级相关
        case visitSecretLevel = "visit_secret_level"
        case modifySecretLevel = "modify_secret_level"

        /// 谁能快捷访问无权限的引用文档和快捷申请权限
        case applyEmbed = "apply_embed"
        /// 查看协作者信息
        case showCollaboratorInfo = "show_collaborator_info"

        // 内容预览和查看
        case preview = "preview"
        case perceive = "perceive"

        /// 版本管理
        case manageVersion = "manage_version"

        /// 创建副本
        case duplicate = "duplicate"

        // 对外分享
        case shareExternal = "share_external"
        // 对关联组织分享
        case sharePartnerTenant = "share_partner_tenant"

        static func &(lhs: Action, rhs: Action) -> ComposeAction {
            .and(lhs: .single(action: lhs), rhs: .single(action: rhs))
        }

        static func |(lhs: Action, rhs: Action) -> ComposeAction {
            .or(lhs: .single(action: lhs), rhs: .single(action: rhs))
        }
    }

    /// 有权限时点位的值
    static let rightCode = 1
    /// 受 CAC 管控无权限时点位的值
    static let blockByCACCode = 2002
    /// 受文档审计管控时点位的值
    static let blockByAudit = 202

    /// 是否被 Admin 精细化管控预览点位，canPerceive 且 ！canView 场景触发
    var previewBlockByAdmin: Bool {
        return check(action: .perceive)
        && !check(action: .view)
    }
}

extension DocumentUserPermission {
    /// 权限点位判断原因
    enum AuthReason: Equatable {
        /// 协作者权限
        case collaborator
        /// 上级可复制点位设置: 100000
        case leaderCanCopyPreference
        /// 上级可管理点位设置: 100003
        case leaderCanManagePreference
        /// 链接分享: 150000
        case shareByLink

        case unknown(code: Int)

        // nolint: magic number
        var rawValue: Int {
            switch self {
            case .collaborator:
                return 0
            case .leaderCanCopyPreference:
                return 100000
            case .leaderCanManagePreference:
                return 100003
            case .shareByLink:
                return 150000
            case let .unknown(code):
                return code
            }
        }

        // nolint: magic number
        init(rawValue: Int) {
            switch rawValue {
            case 0:
                self = .collaborator
            case 100000:
                self = .leaderCanCopyPreference
            case 100003:
                self = .leaderCanManagePreference
            case 150000:
                self = .shareByLink
            default:
                self = .unknown(code: rawValue)
            }
        }
    }
}

struct DocumentUserPermissionContainer: UserPermissionContainer {
    let userPermission: DocumentUserPermission
    /// 是否因为 leader 授权获取 view 权限
    var grantedViewPermissionByLeader: Bool {
        // "可阅读"且 authReason 是 "leader 可管理"
        return userPermission.check(action: .view)
        && userPermission.authReason(for: .view) == .leaderCanManagePreference
    }

    var statusCode: UserPermissionResponse.StatusCode { userPermission.statusCode }

    var isOwner: Bool { userPermission.isOwner }
    
    /// 是否被 CAC 管控分享能力，perceive 与 preview 点位同时控制场景
    var shareControlByCAC: Bool {
        return userPermission.denyReason(for: .perceive) == .normal(denyReason: .blockByCAC)
        && userPermission.denyReason(for: .view) == .normal(denyReason: .blockByCAC)
    }
    /// 是否被 CAC 管控预览点位，仅 preview 点位被 CAC 管控，perceive 点位不被 CAC 管控
    var previewControlByCAC: Bool {
        return userPermission.denyReason(for: .view) == .normal(denyReason: .blockByCAC)
        && userPermission.denyReason(for: .perceive) != .normal(denyReason: .blockByCAC)
    }
    /// 是否被 Admin 精细化管控预览点位，canPerceive 且 ！canView 场景触发
    var previewBlockByAdmin: Bool {
        return userPermission.check(action: .perceive)
        && !userPermission.check(action: .view)
    }

    var viewBlockByAudit: Bool {
        guard let reason = userPermission.denyReason(for: .view) else { return false }
        return reason == .normal(denyReason: .blockByAudit)
    }
}
