// 
// Created by duanxiaochen.7 on 2020/5/14.
// Affiliated with SpaceKit.
// Description:

// swiftlint:disable file_length operator_usage_whitespace

import Foundation
import SKResource
import SwiftyJSON
import SKFoundation


/// 用户权限类型
@available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
public enum UserPermissionType: Int {
    /// 文档
    case file = 0
    /// 文件夹
    case folder = 1
    /// 文件夹V2（单容器）
    case folderV2 = 2
    /// 文档v2(wiki单页面新增)
    case fileV2 = 3
}


///权限角色
@available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
public enum UserPermissionRoleType: Int, CaseIterable {
    case noAccess = 0

    case viewer = 1
    case editor = 2
    case fullAccess = 3
    case linkEditor
    case linkViewer
    
    case singlePageViewer
    case singlePageEditor
    case singlePageFullAccess
    case singlePageLinkEditor
    case singlePageLinkViewer


    public var titleText: String {
        switch self {
        case .noAccess:
            return BundleI18n.SKResource.CreationMobile_Wiki_Permission_NoAccess_Options
        case .viewer, .linkViewer, .singlePageViewer, .singlePageLinkViewer:
            return BundleI18n.SKResource.Doc_Share_Readable
        case .editor, .linkEditor, .singlePageEditor, .singlePageLinkEditor:
            return BundleI18n.SKResource.Doc_Share_Editable
        case .fullAccess, .singlePageFullAccess:
            return BundleI18n.SKResource.CreationMobile_Wiki_Permission_FullAccess_Options
        }
    }
}

@available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
public protocol UserPermissionAbility {
    var rawValue: Int { get }
    var permRoleValue: Int { get }
    var permRoleType: UserPermissionRoleType { get }
    var userPermissionType: UserPermissionType { get }
    var reportData: [String: Any] { get }
    var actions: [UserPermissionEnum : UserPermissionAction] { get }
    // 注意，owner 区分单页面 owner or 单容器 owner，做好区分
    var isOwner: Bool { get }
    var rawData: [String: Any] { get }


    func equalTo(anOther: UserPermissionAbility) -> Bool
    func updatePermRoleType(permRoleType: UserPermissionRoleType) -> UserPermissionAbility

    func canView() -> Bool
    func canEdit() -> Bool
    func canComment() -> Bool
    func canManageCollaborator() -> Bool
    func canManageMeta() -> Bool
    func canCreateSubNode() -> Bool
    func canCopy() -> Bool
    func canManageHistoryRecord() -> Bool
    func canDownload() -> Bool
    func canCollect() -> Bool
    func canOperateFromDusbin() -> Bool
    func canOperateEntity() -> Bool
    func canInviteFullAccess() -> Bool
    func canInviteCanEdit() -> Bool
    func canInviteCanView() -> Bool
    func canBeMoved() -> Bool
    func canMoveFrom() -> Bool
    func canMoveTo() -> Bool
    func canExport() -> Bool
    func canPrint() -> Bool
    func canSinglePageManageCollaborator() -> Bool
    func canSinglePageManageMeta() -> Bool
    func canSinglePageInviteFullAccess() -> Bool
    func canSinglePageInviteCanEdit() -> Bool
    func canSinglePageInviteCanView() -> Bool
    func canVisitSecretLevel() -> Bool
    func canModifySecretLevel() -> Bool
    func canApplyEmbed() -> Bool
    func canShowCollaboratorInfo() -> Bool
    func canPreview() -> Bool //内容预览
    func canPerceive() -> Bool //文档可见
    func canRenameVersion() -> Bool // 重命名版本
    func canDeleteVersion() -> Bool // 删除版本
    func canDuplicate() -> Bool

    ///cac管控
    func shareControlByCAC() -> Bool /// cac分享管控
    func previewControlByCAC() -> Bool /// cac预览管控
    func canExportlByCAC() -> Bool ///cac导出管控


    /// canApply
    func canApply() -> Bool

    func canShareExternal() -> Bool
    func canSharePartnerTenant() -> Bool
}

extension UserPermissionAbility {
    public func canShare() -> Bool {
        return canManageCollaborator() || canSinglePageManageCollaborator()
    }
    public func adminBlocked() -> Bool { ///被admin精细化管控
        return canPerceive() && !canView()
    }
}

extension UserPermissionAbility {
    /// 是否为 FA（容器 FA 或者 单页面 FA）
    public var isFA: Bool {
        if canManageMeta() || canSinglePageManageMeta() {
            return true
        }
        return false
    }
}


// 权限能力点位
public enum UserPermissionEnum: String, CaseIterable {
    case view
    case edit
    case comment
    case manageCollaborator = "manage_collaborator"
    case manageMeta = "manage_meta"
    case createSubNode = "create_sub_node"
    case copy
    case manageHistoryRecord = "manage_history_record"
    case download
    case collect
    case operateFromDusbin = "operate_from_dusbin"
    case operateEntity = "operate_entity"
    case inviteFullAccess = "invite_full_access"
    case inviteCanEdit = "invite_can_edit"
    case inviteCanView = "invite_can_view"
    case beMoved = "be_moved"
    case moveFrom = "move_from"
    case moveTo = "move_to"
    case print
    case export

    //单页面
    case singlePageManageCollaborator = "manage_single_page_collaborator"
    case singlePageManageMeta = "manage_single_page_meta"
    case singlePageInviteFullAccess = "invite_single_page_full_access"
    case singlePageInviteCanEdit = "invite_single_page_can_edit"
    case singlePageInviteCanView = "invite_single_page_can_view"

    //密级
    case visitSecretLevel = "visit_secret_level"
    case modifySecretLevel = "modify_secret_level"

    //谁能快捷访问无权限的引用文档和快捷申请权限
    case applyEmbed = "apply_embed"
    /// 查看协作者信息
    case showCollaboratorInfo = "show_collaborator_info"
    
    // 内容预览和查看
    case preview = "preview"
    case perceive = "perceive"
    
    // 版本管理
    case manageVersion = "manage_version"
    
    // 创建副本
    case duplicate = "duplicate"

    // 对外分享
    case shareExternal = "share_external"
    // 对关联组织分享
    case sharePartnerTenant = "share_partner_tenant"
}


public typealias UserPermissionRequestInfo = (mask: UserPermissionAbility?, code: PermissionStatusCode?)

/// v1文档 v2文档  v1共享文件夹 - 请求userV3接口
@available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
public struct UserPermissionMask: OptionSet {
    public static let read    = UserPermissionMask(rawValue: 1 << 0)
    public static let comment = UserPermissionMask(rawValue: 1 << 1)
    public static let edit    = UserPermissionMask(rawValue: 1 << 2)
    public static let share   = UserPermissionMask(rawValue: 1 << 3)
    public static let copy    = UserPermissionMask(rawValue: 1 << 4)
    public static let export  = UserPermissionMask(rawValue: 1 << 5)
    public static let print   = UserPermissionMask(rawValue: 1 << 6)
    public static let inport  = UserPermissionMask(rawValue: 1 << 7)
    public static let upload  = UserPermissionMask(rawValue: 1 << 8)
    public static let download  = UserPermissionMask(rawValue: 1 << 9)
    public static let fullAccess   = UserPermissionMask(rawValue: 1 << 10) //仅v2文档返回fullAcess
    public static let preview = UserPermissionMask(rawValue: 1 << 11)
    public static let perceive = UserPermissionMask(rawValue: 1 << 12)
    public let rawValue: Int // Protocol requirement
    public var userPermissionType: UserPermissionType = .file
    public var isOwner: Bool = false
    public let rawData: [String: Any]

    public init(rawValue: Int) {
        self.rawValue = rawValue
        self.rawData = [:]
    }

    public static func mockPermisson() -> Self {
        return [.read, comment, edit, share, .copy, .export, .print, .fullAccess, .preview, .perceive]
    }

    /// 初始化文档用户权限
    public static func create(withValue value: Int) -> Self {
        var raw = UserPermissionMask(rawValue: value)
        raw.updateReadable()
        raw.userPermissionType = .file
        return raw
    }
    
    /// 初始化文件夹用户权限
    public static func create(withPermRole value: Int) -> Self {
        var raw: Self = []
        if UserPermissionRoleType.fullAccess.rawValue == value {
            raw = [.edit, .read, .share, .fullAccess]
        } else if UserPermissionRoleType.editor.rawValue == value {
            raw = [.edit, .read]
        } else if UserPermissionRoleType.viewer.rawValue == value {
            raw = [.read]
        } else {
            raw = create(withValue: value)
        }
        raw.userPermissionType = .folder
        return raw
    }


    /// 返回权限角色值
    public var permRoleValue: Int {
        return permRoleType.rawValue
    }

    /// 返回权限角色类型
    public var permRoleType: UserPermissionRoleType {
        if contains(.fullAccess) {
            return .fullAccess
        } else if contains(.edit) {
            return .editor
        } else if contains(.read) {
            return .viewer
        } else {
            return .noAccess
        }
    }


    /// Apply `.read` option when commentable, editable, shareable, copyable, exportable or printable.
    public mutating func updateReadable() {
        if rawValue >= 2 {
            insert(.read)
        }
    }
}


extension UserPermissionMask: UserPermissionAbility {

    public var actions: [UserPermissionEnum : UserPermissionAction] {
        [:]
    }
    
    public var reportData: [String: Any] {
        [:]
    }

    public func updatePermRoleType(permRoleType: UserPermissionRoleType) -> UserPermissionAbility {
        var newMask: UserPermissionMask = []
        switch permRoleType {
        case .fullAccess:
            newMask = [.edit, .read, .share, .fullAccess]
        case .editor:
            newMask = [.edit, .read]
        case .viewer:
            newMask = [.read]
        case .noAccess:
            newMask = []
        default:
            break
        }
        return newMask
    }


    public func equalTo(anOther: UserPermissionAbility) -> Bool {
        guard let other = anOther as? UserPermissionMask else {
            return false
        }
        return self == other
    }

    public func canExport() -> Bool {
        return contains(.export)
    }

    public func canView() -> Bool {
        return contains(.read)
    }

    public func canEdit() -> Bool {
        return contains(.edit)
    }

    public func canComment() -> Bool {
        return contains(.comment)
    }

    public func canManageCollaborator() -> Bool {
        return contains(.share)
    }

    public func canManageMeta() -> Bool {
        return contains(.fullAccess) || isOwner == true
    }

    public func canCreateSubNode() -> Bool {
        return contains(.edit)
    }

    public func canCopy() -> Bool {
        return contains(.copy)
    }

    public func canManageHistoryRecord() -> Bool {
        return contains(.edit)
    }

    public func canDownload() -> Bool {
        return contains(.download)
    }

    public func canCollect() -> Bool {
        return contains(.read)
    }

    public func canOperateFromDusbin() -> Bool {
        return contains(.fullAccess) || isOwner == true
    }

    public func canOperateEntity() -> Bool {
        return contains(.fullAccess) || isOwner == true
    }

    public func canInviteFullAccess() -> Bool {
        return contains(.fullAccess) || isOwner == true
    }

    public func canInviteCanEdit() -> Bool {
        return contains(.edit)
    }

    public func canInviteCanView() -> Bool {
        return contains(.read)
    }

    public func canBeMoved() -> Bool {
        return contains(.fullAccess) || isOwner == true
    }

    public func canMoveFrom() -> Bool {
        return contains(.edit)
    }

    public func canMoveTo() -> Bool {
        return contains(.edit)
    }

    public func canPrint() -> Bool {
        return contains(.print)
    }

    public func canSinglePageManageCollaborator() -> Bool {
        return false
    }

    public func canSinglePageManageMeta() -> Bool {
        return false
    }

    public func canSinglePageInviteFullAccess() -> Bool {
        return false
    }

    public func canSinglePageInviteCanEdit() -> Bool {
        return false
    }

    public func canSinglePageInviteCanView() -> Bool {
        return false
    }
    public func canVisitSecretLevel() -> Bool {
        return false
    }
    public func canModifySecretLevel() -> Bool {
        return false
    }
    public func canApplyEmbed() -> Bool {
        return true
    }
    public func canShowCollaboratorInfo() -> Bool {
        return true
    }
    
    public func canPreview() -> Bool {
        return contains(.preview)
    }
    public func canPerceive() -> Bool {
        return contains(.perceive)
    }
    
    public func canRenameVersion() -> Bool {
        return false
    }
    
    public func canDeleteVersion() -> Bool {
        return false
    }
    
    public func canDuplicate() -> Bool {
        return true
    }
    public func shareControlByCAC() -> Bool {
        return false
    }
    public func previewControlByCAC() -> Bool {
        return false
    }
    
    public func canApply() -> Bool {
        return false
    }
    
    public func canExportlByCAC() -> Bool {
        return false
    }

    public func canShareExternal() -> Bool {
        return false
    }

    public func canSharePartnerTenant() -> Bool {
        return false
    }
}

// V2文件夹权限点位，返回数据模型 https://bytedance.feishu.cn/docs/doccnbl2it4upSXxQ6mcgGVdhPf
@available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
public final class ShareFolderV2UserPermission: UserPermissionAbility {
    public var actions: [UserPermissionEnum : UserPermissionAction] = [:]
    
    internal(set) public var isOwner: Bool
    public let rawData: [String: Any]
    var view: Int
    var edit: Int
    var manageCollaborator: Int
    var manageMeta: Int
    var createSubNode: Int
    var download: Int
    var collect: Int
    var operateFromDusbin: Int
    var operateEntity: Int
    var inviteFullAccess: Int
    var inviteCanEdit: Int
    var inviteCanView: Int
    var beMoved: Int
    var moveFrom: Int
    var moveTo: Int
    
    public init(json: JSON) {
        self.rawData = json.dictionaryObject ?? [:]
        let data = json["data"]
        self.isOwner = data["is_owner"].bool ?? false
        let action = data["actions"]
        self.view = action["view"].int ?? wrongCode
        self.edit = action["edit"].int ?? wrongCode
        self.manageCollaborator = action["manage_collaborator"].int ?? wrongCode
        self.manageMeta = action["manage_meta"].int ?? 0
        self.createSubNode = action["create_sub_node"].int ?? wrongCode
        self.download = action["download"].int ?? wrongCode
        self.collect = action["collect"].int ?? wrongCode
        self.operateFromDusbin = action["operate_from_dusbin"].int ?? wrongCode
        self.operateEntity = action["operate_entity"].int ?? wrongCode
        self.inviteFullAccess = action["invite_full_access"].int ?? wrongCode
        self.inviteCanEdit = action["invite_can_edit"].int ?? wrongCode
        self.inviteCanView = action["invite_can_view"].int ?? wrongCode
        self.beMoved = action["be_moved"].int ?? wrongCode
        self.moveFrom = action["move_from"].int ?? wrongCode
        self.moveTo = action["move_to"].int ?? wrongCode
    }

    public var rawValue: Int {
        if canManageMeta() {
            return 1 << 10
        }
        if canEdit() {
            return 1 << 2
        }
        if canView() {
            return 1 << 1
        }
        return 1 << 0
    }

    public var userPermissionType: UserPermissionType {
        .folderV2
    }
    public var reportData: [String: Any] {
        (rawData["data"] as? [String: Any]) ?? [:]
    }

    /// 返回权限角色类型
    public var permRoleType: UserPermissionRoleType {
        if canManageMeta() {
            return .fullAccess
        } else if canEdit() {
            return .editor
        } else if canView() {
            return .viewer
        } else {
            return .noAccess
        }
    }

    public func updatePermRoleType(permRoleType: UserPermissionRoleType) -> UserPermissionAbility {
        let new: ShareFolderV2UserPermission = self
        switch permRoleType {
        case .fullAccess:
            new.manageMeta = rightCode
            new.edit = rightCode
            new.view = rightCode
        case .editor:
            new.manageMeta = wrongCode
            new.edit = rightCode
            new.view = rightCode
        case .viewer:
            new.manageMeta = wrongCode
            new.edit = wrongCode
            new.view = rightCode
        default:
            break
        }
        return new
    }


    /// 返回权限角色值
    public var permRoleValue: Int {
        return permRoleType.rawValue
    }

    public func equalTo(anOther: UserPermissionAbility) -> Bool {
        return true
    }

    /// 可阅读
    public func canView() -> Bool {
        return view == rightCode
    }
    
    /// 可编辑
    public func canEdit() -> Bool {
        return edit == rightCode
    }
    
    /// 可管理协作者
    public func canManageCollaborator() -> Bool {
        return manageCollaborator == rightCode
    }
    
    /// 可修改节点配置，链接分享&对外分享
    public func canManageMeta() -> Bool {
        return manageMeta == rightCode
    }
    
    /// 新建子节点，上传&新建
    public func canCreateSubNode() -> Bool {
        return createSubNode == rightCode
    }
    
    /// 可下载
    public func canDownload() -> Bool {
        return download == rightCode
    }
    
    /// 添加到收藏或快速访问
    public func canCollect() -> Bool {
        return collect == rightCode
    }
    
    /// 从回收站查看、删除、恢复
    public func canOperateFromDusbin() -> Bool {
        return operateFromDusbin == rightCode
    }
    
    /// 操作实体
    public func canOperateEntity() -> Bool {
        return operateEntity == rightCode
    }
    
    public func canRenameVersion() -> Bool {
        return false
    }
    
    public func canDeleteVersion() -> Bool {
        return false
    }
    
    /// 可邀请/删除FullAccess
    public func canInviteFullAccess() -> Bool {
        return inviteFullAccess == rightCode
    }
    
    /// 可邀请/删除CanEdit
    public func canInviteCanEdit() -> Bool {
        return inviteCanEdit == rightCode
    }
    
    /// 可邀请/删除CanView
    public func canInviteCanView() -> Bool {
        return inviteCanView == rightCode
    }
    
    /// 本节点被移动
    public func canBeMoved() -> Bool {
        return beMoved == rightCode
    }
    
    /// 移动本节点的子节点
    public func canMoveFrom() -> Bool {
        return moveFrom == rightCode
    }
    
    /// 将节点移动到本节点下
    public func canMoveTo() -> Bool {
        return moveTo == rightCode
    }

    public func canComment() -> Bool {
        return false
    }

    public func canCopy() -> Bool {
        return false
    }

    public func canManageHistoryRecord() -> Bool {
        return false
    }

    public func canExport() -> Bool {
        return false
    }

    public func canPrint() -> Bool {
        return false
    }

    public func canSinglePageManageCollaborator() -> Bool {
        return false
    }

    public func canSinglePageManageMeta() -> Bool {
        return false
    }

    public func canSinglePageInviteFullAccess() -> Bool {
        return false
    }

    public func canSinglePageInviteCanEdit() -> Bool {
        return false
    }

    public func canSinglePageInviteCanView() -> Bool {
        return false
    }
    public func canVisitSecretLevel() -> Bool {
        return false
    }
    public func canModifySecretLevel() -> Bool {
        return false
    }
    public func canApplyEmbed() -> Bool {
        return true
    }
    public func canShowCollaboratorInfo() -> Bool {
        return true
    }
    public func canPreview() -> Bool {
        return true
    }
    public func canPerceive() -> Bool {
        return true
    }
    public func canDuplicate() -> Bool {
        return true
    }
    public func shareControlByCAC() -> Bool {
        return view == cacCode
    }
    public func previewControlByCAC() -> Bool {
        return false
    }
    public func canApply() -> Bool {
        return false
    }
    public func canExportlByCAC() -> Bool {
        false
    }

    public func canShareExternal() -> Bool {
        return false
    }

    public func canSharePartnerTenant() -> Bool {
        return false
    }
}


@available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
public final class UserPermission {
    internal(set) public var isOwner: Bool
    public let rawData: [String: Any]
    public var actions: [UserPermissionEnum : UserPermissionAction] = [:]
    public let json: JSON
    var view: Int
    var edit: Int
    let comment: Int
    let manageCollaborator: Int
    var manageMeta: Int
    let createSubNode: Int
    let copy: Int
    let manageHistoryRecord: Int
    let download: Int
    let collect: Int
    let operateFromDusbin: Int
    let operateEntity: Int
    let inviteFullAccess: Int
    let inviteCanEdit: Int
    let inviteCanView: Int
    let beMoved: Int
    let moveFrom: Int
    let moveTo: Int
    let print: Int
    let export: Int

    //单页面
    let singlePageManageCollaborator: Int
    var singlePageManageMeta: Int
    let singlePageInviteFullAccess: Int
    let singlePageInviteCanEdit: Int
    let singlePageInviteCanView: Int

    //密级
    let visitSecretLevel: Int
    let modifySecretLevel: Int

    //谁能快捷访问无权限的引用文档和快捷申请权限
    let applyEmbed: Int
    /// 谁可以查看文档协同头像和点赞头像
    let showCollaboratorInfo: Int
    
    // 文档预览和文档可见
    let preview: Int
    let perceive: Int
    
    // 版本管理
    let managerVersion: Int
    
    //创建副本
    let duplicate: Int

    // 对外分享
    let shareExternal: Int
    // 对关联组织分享
    let sharePartnerTenant: Int


    public init(json: JSON) {
        self.json = json
        self.rawData = json.dictionaryObject ?? [:]
        let data = json["data"]
        self.isOwner = data["is_owner"].boolValue
        let actions = data["actions"]
        self.view = actions[UserPermissionEnum.view.rawValue].int ?? wrongCode
        self.edit = actions[UserPermissionEnum.edit.rawValue].int ?? wrongCode
        self.comment = actions[UserPermissionEnum.comment.rawValue].int ?? wrongCode
        self.manageCollaborator = actions[UserPermissionEnum.manageCollaborator.rawValue].int ?? wrongCode
        self.manageMeta = actions[UserPermissionEnum.manageMeta.rawValue].int ?? wrongCode
        self.createSubNode = actions[UserPermissionEnum.createSubNode.rawValue].int ?? wrongCode
        self.copy = actions[UserPermissionEnum.copy.rawValue].int ?? wrongCode
        self.manageHistoryRecord = actions[UserPermissionEnum.manageHistoryRecord.rawValue].int ?? wrongCode
        self.download = actions[UserPermissionEnum.download.rawValue].int ?? wrongCode
        self.collect = actions[UserPermissionEnum.collect.rawValue].int ?? wrongCode
        self.operateFromDusbin = actions[UserPermissionEnum.operateFromDusbin.rawValue].int ?? wrongCode
        self.operateEntity = actions[UserPermissionEnum.operateEntity.rawValue].int ?? wrongCode
        self.inviteFullAccess = actions[UserPermissionEnum.inviteFullAccess.rawValue].int ?? wrongCode
        self.inviteCanEdit = actions[UserPermissionEnum.inviteCanEdit.rawValue].int ?? wrongCode
        self.inviteCanView = actions[UserPermissionEnum.inviteCanView.rawValue].int ?? wrongCode
        self.beMoved = actions[UserPermissionEnum.beMoved.rawValue].int ?? wrongCode
        self.moveFrom = actions[UserPermissionEnum.moveFrom.rawValue].int ?? wrongCode
        self.moveTo = actions[UserPermissionEnum.moveTo.rawValue].int ?? wrongCode
        self.print = actions[UserPermissionEnum.print.rawValue].int ?? wrongCode
        self.export = actions[UserPermissionEnum.export.rawValue].int ?? wrongCode

        self.singlePageManageCollaborator = actions[UserPermissionEnum.singlePageManageCollaborator.rawValue].int ?? wrongCode
        self.singlePageManageMeta = actions[UserPermissionEnum.singlePageManageMeta.rawValue].int ?? wrongCode
        self.singlePageInviteFullAccess = actions[UserPermissionEnum.singlePageInviteFullAccess.rawValue].int ?? wrongCode
        self.singlePageInviteCanEdit = actions[UserPermissionEnum.singlePageInviteCanEdit.rawValue].int ?? wrongCode
        self.singlePageInviteCanView = actions[UserPermissionEnum.singlePageInviteCanView.rawValue].int ?? wrongCode

        //密级
        self.visitSecretLevel = actions[UserPermissionEnum.visitSecretLevel.rawValue].int ?? wrongCode
        self.modifySecretLevel = actions[UserPermissionEnum.modifySecretLevel.rawValue].int ?? wrongCode

        //快捷访问无权限的引用文档和快捷申请权限
        self.applyEmbed = actions[UserPermissionEnum.applyEmbed.rawValue].int ?? wrongCode
        self.showCollaboratorInfo = actions[UserPermissionEnum.showCollaboratorInfo.rawValue].int ?? wrongCode
        
        self.preview = actions[UserPermissionEnum.preview.rawValue].int ?? wrongCode
        self.perceive = actions[UserPermissionEnum.perceive.rawValue].int ?? wrongCode

        self.managerVersion = actions[UserPermissionEnum.manageVersion.rawValue].int ?? wrongCode
        
        self.duplicate = actions[UserPermissionEnum.duplicate.rawValue].int ?? wrongCode

        self.shareExternal = actions[UserPermissionEnum.shareExternal.rawValue].int ?? wrongCode
        self.sharePartnerTenant = actions[UserPermissionEnum.sharePartnerTenant.rawValue].int ?? wrongCode
        
        let authReason = data["auth_reasons"]
        actions.dictionary?.forEach { key, json in
            if let type = UserPermissionEnum(rawValue: key) {
                let reasonCode = authReason[key].intValue
                let action = UserPermissionAction(type: type, rawValue: json.intValue, reasonCode: reasonCode)
                self.actions[type] = action
            }
        }
    }
}

private let rightCode = 1
private let wrongCode = 2
private let cacCode = 2002
/// 对外分享被密级管控
private let secLabelCode = 432
/// 对外分享开关被关
private let shareExternal = 133

extension UserPermission: UserPermissionAbility {
    
    public func updatePermRoleType(permRoleType: UserPermissionRoleType) -> UserPermissionAbility {
        let new: UserPermission = self
        switch permRoleType {
        case .fullAccess:
            new.manageMeta = rightCode
            new.singlePageManageMeta = rightCode
            new.edit = rightCode
            new.view = rightCode
        case .editor:
            new.manageMeta = wrongCode
            new.singlePageManageMeta = wrongCode
            new.edit = rightCode
            new.view = rightCode
        case .viewer:
            new.manageMeta = wrongCode
            new.singlePageManageMeta = wrongCode
            new.edit = wrongCode
            new.view = rightCode
        case .singlePageFullAccess:
            new.manageMeta = wrongCode
            new.singlePageManageMeta = rightCode
            new.edit = wrongCode
            new.view = wrongCode
        default:
            break
        }
        return new
    }

    public var userPermissionType: UserPermissionType {
        return .fileV2
    }

    public var permRoleType: UserPermissionRoleType {
        if canManageMeta() {
            return .fullAccess
        } else if canEdit() {
            return .editor
        } else if canView() {
            return .viewer
        } else if canSinglePageManageMeta() {
            return .singlePageFullAccess
        } else {
            return .noAccess
        }
    }

    public var reportData: [String: Any] {
        (rawData["data"] as? [String: Any]) ?? [:]
    }

    public func equalTo(anOther: UserPermissionAbility) -> Bool {
        return true
    }

    public var permRoleValue: Int {
        return permRoleType.rawValue
    }

    public var rawValue: Int {
        if canManageMeta() {
            return 1 << 10
        }
        if canEdit() {
            return 1 << 2
        }
        if canView() {
            return 1 << 1
        }
        return 1 << 0
    }

    public func canExport() -> Bool {
        export == rightCode
    }

    public func canView() -> Bool {
        view == rightCode
    }

    public func canEdit() -> Bool {
        edit == rightCode
    }

    public func canComment() -> Bool {
        comment == rightCode
    }

    public func canManageCollaborator() -> Bool {
        manageCollaborator == rightCode
    }

    public func canManageMeta() -> Bool {
        manageMeta == rightCode
    }

    public func canCreateSubNode() -> Bool {
        createSubNode == rightCode
    }

    public func canCopy() -> Bool {
        copy == rightCode
    }

    public func canManageHistoryRecord() -> Bool {
        manageHistoryRecord == rightCode
    }

    public func canDownload() -> Bool {
        download == rightCode
    }

    public func canCollect() -> Bool {
        collect == rightCode
    }

    public func canOperateFromDusbin() -> Bool {
        operateFromDusbin == rightCode
    }

    public func canOperateEntity() -> Bool {
        operateEntity == rightCode
    }

    public func canInviteFullAccess() -> Bool {
        inviteFullAccess == rightCode
    }

    public func canInviteCanEdit() -> Bool {
        inviteCanEdit == rightCode
    }

    public func canInviteCanView() -> Bool {
        inviteCanView == rightCode
    }

    public func canBeMoved() -> Bool {
        beMoved == rightCode
    }

    public func canMoveFrom() -> Bool {
        moveFrom == rightCode
    }

    public func canMoveTo() -> Bool {
        moveTo == rightCode
    }

    public func canPrint() -> Bool {
        print == rightCode
    }

    public func canSinglePageManageCollaborator() -> Bool {
        singlePageManageCollaborator == rightCode
    }

    public func canSinglePageManageMeta() -> Bool {
        singlePageManageMeta == rightCode
    }

    public func canSinglePageInviteFullAccess() -> Bool {
        singlePageInviteFullAccess == rightCode
    }

    public func canSinglePageInviteCanEdit() -> Bool {
        singlePageInviteCanEdit == rightCode
    }

    public func canSinglePageInviteCanView() -> Bool {
        singlePageInviteCanView == rightCode
    }
    public func canVisitSecretLevel() -> Bool {
        visitSecretLevel == rightCode
    }
    public func canModifySecretLevel() -> Bool {
        modifySecretLevel == rightCode
    }

    public func canApplyEmbed() -> Bool {
        return applyEmbed == rightCode
    }
    
    public func canShowCollaboratorInfo() -> Bool {
        return showCollaboratorInfo == rightCode
    }
    
    public func canPreview() -> Bool {
        preview == rightCode
    }
    public func canPerceive() -> Bool {
        perceive == rightCode
    }
    
    public func canRenameVersion() -> Bool {
        managerVersion == rightCode
    }
    
    public func canDeleteVersion() -> Bool {
        operateEntity == rightCode
    }
    
    public func canDuplicate() -> Bool {
        return duplicate == rightCode
    }
    public func shareControlByCAC() -> Bool {
        return perceive == cacCode && view == cacCode
    }
    public func previewControlByCAC() -> Bool {
        return perceive != cacCode && view == cacCode
    }
    public func canApply() -> Bool {
        return json["meta"]["owner"]["can_apply_perm"].boolValue
    }
    public func canExportlByCAC() -> Bool {
        export == cacCode
    }

    public func canShareExternal() -> Bool {
        return shareExternal == rightCode
    }

    public func canSharePartnerTenant() -> Bool {
        return sharePartnerTenant == rightCode
    }
}

@available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
public class UserPermissionAction {
    
    /// 权限来源
    public enum AuthReason: Int {
        /// 无权限
        case none = 0
        /// 上级可复制
        case leaderCopy = 100000
        /// 上级可管理
        case leaderManager = 100003
        /// 链接分享
        case linkShare = 150000
    }

    /// 鉴权结果
    public enum AuthResult: Int {
        /// 通过
        case allow = 1
        /// 拒绝
        case forbidden = 2
        /// 未知（一般是鉴权异常返回）
        case unknow = 3
        /// 文档对外分享关闭
        case externalAccessClose = 133
        /// 密级关闭对外分享
        case secLabel = 432
        /// 当share_partner_tenant为此值时，代表对外分享被admin降为关联组织分享
        case specialSharePartnerTenant = 131
        /// 当share_external为此值，允许从关联组织分享升为对外分享
        case specialShareExternal = 132
        /// 当share_external为此值，admin管控不允许打开对外分享，但允许打开关联组织分享
        case adminSharePartnerTenantClose = 2132
        /// 当share_external为此值，wiki空间不允许打开对外分享，但允许打开关联组织分享
        case wikiSharePartnerTenantClose = 1632
        /// 当share_external为此值，密级管控不允许打开对外分享，但允许打开关联组织分享
        case secLabelSharePartnerTenantClose = 434
    }
    
    public let type: UserPermissionEnum
    public let rawValue: Int
    public var isEnabled: Bool {
        return authResult == .allow
    }
    public let authReason: AuthReason?
    public let authResult: AuthResult
    
    init(type: UserPermissionEnum, rawValue: Int, reasonCode: Int) {
        self.type = type
        self.rawValue = rawValue
        self.authReason = UserPermissionAction.AuthReason(rawValue: reasonCode)
        self.authResult = AuthResult(rawValue: rawValue) ?? .unknow
    }
}
