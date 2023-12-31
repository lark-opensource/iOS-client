//
// Created by duanxiaochen.7 on 2020/5/15.
// Affiliated with SpaceKit.
//
// Description:
// swiftlint:disable file_length cyclomatic_complexity

import Foundation
import SwiftyJSON
import SKFoundation
import SKResource
import SwiftUI

// 旧版链接共享，不支持关联组织，待废弃
@available(*, deprecated, message: "Use LinkShareEntityV2 instead")
public enum LinkShareEntity: Int {
    case close                          // 关闭
    case tenantCanRead                  // 组织内获得链接可访问
    case tenantCanEdit                  // 组织内获得链接可编辑
    case anyoneCanRead                  // 任何人获得链接可访问
    case anyoneCanEdit                  // 任何人获得链接可编辑

    // 推荐使用这个初始化方法，统一收敛默认值
    init(_ value: Int) {
        self = LinkShareEntity(rawValue: value) ?? .close
    }

    public var canCrossTenant: Bool {
        switch self {
        case .anyoneCanRead, .anyoneCanEdit:
            return true
        default:
            return false
        }
    }
}

// 链接共享，支持关联组织
public enum LinkShareEntityV2: Int {
    case close = 1                      // 关闭
    case tenantCanRead                  // 组织内获得链接可访问
    case tenantCanEdit                  // 组织内获得链接可编辑
    case anyoneCanRead                  // 任何人获得链接可访问
    case anyoneCanEdit                  // 任何人获得链接可编辑
    case partnerTenantCanRead           // 关联组织获得链接可访问
    case partnerTenantCanEdit           // 关联组织获得链接可编辑

    // 推荐使用这个初始化方法，统一收敛默认值
    init(_ value: Int) {
        self = LinkShareEntityV2(rawValue: value) ?? .close
    }

    public var canCrossTenant: Bool {
        switch self {
        case .anyoneCanRead, .anyoneCanEdit,
             .partnerTenantCanRead, .partnerTenantCanEdit:
            return true
        default:
            return false
        }
    }

    public var canShareAnyone: Bool {
        switch self {
        case .anyoneCanRead, .anyoneCanEdit:
            return true
        default:
            return false
        }
    }
}

// 可搜索设置
public enum SearchEntity: Int {
    case tenantCanSearch = 1            // 组织内的人可搜索
    case linkCanSearch                  // 获得链接的人可搜索
    
    // 推荐使用这个初始化方法，统一收敛默认值
    init(_ value: Int) {
        self = SearchEntity(rawValue: value) ?? .tenantCanSearch
    }
}


// 评论设置
public enum CommentEntity: Int {
    case userCanRead                    // 可阅读此文档的用户
    case userCanEdit                    // 可编辑此文档的用户

    // 推荐使用这个初始化方法，统一收敛默认值
    init(_ value: Int) {
        self = CommentEntity(rawValue: value) ?? .userCanRead
    }
}

// 共享设置
public enum ShareEntity: Int {
    case onlyMe                         // 只有我
    case tenant                         // 组织内所有可阅读或编辑此文档的用户
    case anyone                         // 所有可阅读或编辑此文档的用户

    // 推荐使用这个初始化方法，统一收敛默认值
    init(_ value: Int) {
        self = ShareEntity(rawValue: value) ?? .anyone
    }
}

// 谁可以复制内容
public enum CopyEntity: Int {
    case userCanRead                    // 可阅读此文档的用户
    case userCanEdit                    // 可编辑此文档的用户
    case onlyMe                         //只有我

    // 推荐使用这个初始化方法，统一收敛默认值
    init(_ value: Int) {
        self = CopyEntity(rawValue: value) ?? .userCanRead
    }
}

// 安全设置: 复制、导出、打印
public enum SecurityEntity: Int {
    case userCanRead                    // 可阅读此文档的用户
    case userCanEdit                    // 可编辑此文档的用户
    case onlyMe                         //只有我

    // 推荐使用这个初始化方法，统一收敛默认值
    init(_ value: Int) {
        self = SecurityEntity(rawValue: value) ?? .userCanRead
    }
}

//谁可以查看文档协同头像和点赞头像
public enum ShowCollaboratorInfoEntity: Int {
    /// 拥有可阅读权限的用户
    case userCanRead = 1
    /// 拥有可编辑权限的用户
    case userCanEdit
    /// 拥有可管理权限(包括我)的用户
    case userCanManager

    // 推荐使用这个初始化方法，统一收敛默认值
    init(_ value: Int) {
        self = ShowCollaboratorInfoEntity(rawValue: value) ?? .userCanRead
    }
}

// 对外共享状态
public enum ExternalAccessEntity: Int {
    case open = 1                   // 可对所有外部用户共享
    case close                      // 关闭对外共享
    case partnerTenant              // 可对关联组织外部用户共享

    // 推荐使用这个初始化方法，统一收敛默认值
    init(_ value: Int) {
        self = ExternalAccessEntity(rawValue: value) ?? .close
    }
}


// 权限设置的类型
public struct PermTypeValue {
    //权限设置类型
    public enum PermType: Int {
        case defaultType = 0   //默认权限
        case container                    // 容器权限
        case singlePage                    // 单页面权限

        init(_ value: Int) {
            self = PermType(rawValue: value) ?? .container
        }
    }

    var linkShareEntity: PermType = .defaultType    //链接分享
    var externalAccessSwitch: PermType = .defaultType //对外开关
    var searchEntity: PermType = .defaultType    //可搜索设置
    public init(dict: [String: Any]) {
        if let linkShareEntity = dict["link_share_entity"] as? Int {
            self.linkShareEntity = PermType(linkShareEntity)
        }
        if let externalAccessSwitch = dict["external_access_switch"] as? Int {
            self.externalAccessSwitch = PermType(externalAccessSwitch)
        }
        if let searchEntity = dict["search_entity"] as? Int {
            self.searchEntity = PermType(searchEntity)
        }
    }
}

public struct BlockOptions {

    public enum BlockType: Int {
        case none = 0                          // 无约束
        case containerLimit                 // 受容器约束
        case parentLimit                    // 受父节点约束
        case currentLimit                   //当前节点约束
        case tenantLimit                    //租户约束
        case secretControl                  //密级管控
        case dlpControl                     //dlp管控

        init(_ value: Int) {
            self = BlockType(rawValue: value) ?? .none
        }

        @available(*, deprecated, message: "文案不适用于所有场景，建议按需使用不同的文案")
        public func title(isWiki: Bool) -> String {
            switch self {
            case .containerLimit:
                ///"无法修改此项设置，如需修改，请联系知识空间管理员"
                return BundleI18n.SKResource.CreationMobile_Wiki_DocsMigration_page_NoPermission_ContactAdmin_tips
            case .parentLimit:
                if isWiki {
                    ///"无法修改此项设置，如需修改，请联系父页面所有者"
                    return BundleI18n.SKResource.CreationMobile_Wiki_DocsMigration_page_NoPermission_ContactOwner_tips
                } else {
                    ///"无法选择此选项，如需选择，请联系父级文件夹所有者"
                    return BundleI18n.SKResource.CreationMobile_Docs_NoPermissionToChange_ParentFolder
                }
            case .currentLimit:
                ///"无法修改此项设置，如需修改，请联系知识空间管理员"
                return BundleI18n.SKResource.CreationMobile_Wiki_DocsMigration_page_NoPermission_ContactAdmin_tips
            case .tenantLimit:
                ///企业或组织已关闭页面对外分享
                return BundleI18n.SKResource.CreationMobile_Wiki_SharePanel_ExternalOffOrg
            case .secretControl:
                ///受文档密级管控，无法选择
                return BundleI18n.SKResource.CreationMobile_SecureLabel_PermSettings_RestrictedSelect
            case .dlpControl:
                /// dlp管控，native没有用到
                return ""
            case .none:
                ///"无法修改此项设置，如需修改，请联系知识空间管理员"
                return BundleI18n.SKResource.CreationMobile_Wiki_DocsMigration_page_NoPermission_ContactAdmin_tips
            }
        }

        public func linkShareEntityBlockReason(isWiki: Bool, isFolder: Bool, externalAccessType: ExternalAccessSwitchType) -> String {
            switch (self, externalAccessType, isWiki, isFolder) {
            case (.none, _, _, _):
                return BundleI18n.SKResource.CreationMobile_Wiki_DocsMigration_page_NoPermission_ContactAdmin_tips
            case (.secretControl, _, _, _):
                return BundleI18n.SKResource.CreationMobile_SecureLabel_PermSettings_RestrictedSelect
            case (.tenantLimit, _, _, _):
                return BundleI18n.SKResource.CreationMobile_Wiki_SharePanel_ExternalOffOrg
            case (.currentLimit, .open, _, false):
                return BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_SwitchOption_Enable_toast
            case (.currentLimit, .open, _, true):
                return BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_SwitchOption_Enable_folder_toast
            case (.currentLimit, .partnerTenant, _, false):
                return BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_SwitchOption_EnableTrustParty_toast
            case (.currentLimit, .partnerTenant, _, true):
                return BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_SwitchOption_EnableTrustParty_folder_toast
            case(.currentLimit, .close, _, _):
                return BundleI18n.SKResource.CreationMobile_Wiki_DocsMigration_page_NoPermission_ContactAdmin_tips
            case (.parentLimit, _, true, _):
                return BundleI18n.SKResource.CreationMobile_Wiki_DocsMigration_page_NoPermission_ContactOwner_tips
            case (.parentLimit, _, false, _):
                return BundleI18n.SKResource.CreationMobile_Docs_NoPermissionToChange_ParentFolder
            case (.containerLimit, _, _, _):
                return BundleI18n.SKResource.CreationMobile_Wiki_DocsMigration_page_NoPermission_ContactAdmin_tips
            case (.dlpControl, _, _, _):
                ///dlp管控，native没有用到
                return ""
            }
        }

//        public func externalAccessBlockReason(isWiki: Bool, isFolder: Bool, externalAccessType: ExternalAccessSwitchType) -> String {
//            switch (self, externalAccessType) {
//            case (.containerLimit, .open):
//                ///知识空间已关闭页面对外分享
//                return BundleI18n.SKResource.CreationMobile_Wiki_SharePanel_ExternalOffSpace
//            case (.containerLimit, .partnerTenant):
//                return BundleI18n.SKResource.CreationMobile_ECM_Security_ExternalSharing_Off_Tooltips
//            default:
//                // 其他和链接分享一样
//                return linkShareEntityBlockReason(isWiki: isWiki, isFolder: isFolder, externalAccessType: externalAccessType)
//            }
//        }
    }

    public enum CopyType: Int {
        case read = 1                 // 可阅读此文档的用户
        case edit                    // 可编辑此文档的用户
        case fullAccess                         //只有我/所有权限

        init(_ value: Int) {
            self = CopyType(rawValue: value) ?? .fullAccess
        }
    }
    
    public enum SecurityType: Int {
        case read = 1                 // 可阅读此文档的用户
        case edit                    // 可编辑此文档的用户
        case fullAccess                         //只有我/所有权限

        init(_ value: Int) {
            self = SecurityType(rawValue: value) ?? .fullAccess
        }
    }
    
    public enum ShowCollaboratorInfoEntityType: Int {
        case read = 1                 // 可阅读此文档的用户
        case edit                    // 可编辑此文档的用户
        case fullAccess                         //只有我/所有权限

        init(_ value: Int) {
            self = ShowCollaboratorInfoEntityType(rawValue: value) ?? .fullAccess
        }
    }

    public enum CommentType: Int {
        case read = 1                 // 可阅读此文档的用户
        case edit                    // 可编辑此文档的用户

        init(_ value: Int) {
            self = CommentType(rawValue: value) ?? .edit
        }
    }

    public typealias ExternalAccessSwitchType = ExternalAccessEntity

    public typealias LinkShareEntityType = LinkShareEntityV2
    
    public typealias SearchEntityType = SKCommon.SearchEntity

    public struct CopyEntity {
        let value: CopyType
        let blockType: BlockType
    }
    
    public struct Security {
        let value: SecurityType
        let blockType: BlockType
    }
    
    public struct ShowCollaboratorInfoEntity {
        let value: ShowCollaboratorInfoEntityType
        let blockType: BlockType
    }

    public struct Comment {
        let value: CommentType
        let blockType: BlockType
    }

    public struct ExternalAccessSwitch {
        let value: ExternalAccessSwitchType
        let blockType: BlockType
    }

    public struct LinkShareEntity {
        let value: LinkShareEntityType
        let blockType: BlockType
    }
    
    public struct SearchEntity {
        let value: SearchEntityType
        let blockType: BlockType
    }

    public struct WoCanManageCollaboratorsByOrganizationEntity {
        let value: WoCanManageCollaboratorsByOrganization
        let blockType: BlockType
    }

    public struct WoCanManageCollaboratorsByPermissionEntity {
        let value: WoCanManageCollaboratorsByPermission
        let blockType: BlockType
    }

    public struct WoCanExternalShareByPermissionEntity {
        let value: WoCanExternalShareByPermission
        let blockType: BlockType
    }

    public struct WoCanApplyEmbedEntity {
        let value: WoCanFastApplyPermission
        let blockType: BlockType
    }
    
    var copyEntity: [CopyEntity] = []
    var security: [Security] = []
    var showCollaboratorInfoEntity: [ShowCollaboratorInfoEntity] = []
    var comment: [Comment] = []
    var externalAccessSwitch: [ExternalAccessSwitch] = []
    var linkShareEntity: [LinkShareEntity] = []
    var searchEntity: [SearchEntity] = []
    var woCanManageCollaboratorsByOrganizationEntity: [WoCanManageCollaboratorsByOrganizationEntity] = []
    var woCanManageCollaboratorsByPermissionEntity: [WoCanManageCollaboratorsByPermissionEntity] = []
    var woCanExternalShareByPermissionEntity: [WoCanExternalShareByPermissionEntity] = []
    var woCanApplyEmbedEntity: [WoCanApplyEmbedEntity] = []

    public init(dict: [String: Any]) {
        if let copyArray = dict["copy_entity"] as? [[String: Int]] {
            copyEntity = copyArray.compactMap { dic in
                if let value = dic["value"],
                   let blockTypeValue = dic["block_type"],
                   let valueType = CopyType(rawValue: value),
                   let blockType = BlockType(rawValue: blockTypeValue) {
                    return CopyEntity(value: valueType, blockType: blockType)
                }
                return nil
            }
        }
        
        if let securityArray = dict["security"] as? [[String: Int]] {
            security = securityArray.compactMap { dic in
                if let value = dic["value"],
                   let blockTypeValue = dic["block_type"],
                   let valueType = SecurityType(rawValue: value),
                   let blockType = BlockType(rawValue: blockTypeValue) {
                    return Security(value: valueType, blockType: blockType)
                }
                return nil
            }
        }

        if let commentArray = dict["comment"] as? [[String: Int]] {
            comment = commentArray.compactMap { dic in
                if let value = dic["value"],
                   let blockTypeValue = dic["block_type"],
                   let valueType = BlockOptions.CommentType(rawValue: value),
                   let blockType = BlockOptions.BlockType(rawValue: blockTypeValue) {
                    return Comment(value: valueType, blockType: blockType)
                }
                return nil
            }
        }
        
        if let showCollabortorInfoEntityArray = dict["show_collaborator_info_entity"] as? [[String: Int]] {
            showCollaboratorInfoEntity = showCollabortorInfoEntityArray.compactMap { dic in
                if let value = dic["value"],
                   let blockTypeValue = dic["block_type"],
                   let valueType = BlockOptions.ShowCollaboratorInfoEntityType(rawValue: value),
                   let blockType = BlockOptions.BlockType(rawValue: blockTypeValue) {
                    return ShowCollaboratorInfoEntity(value: valueType, blockType: blockType)
                }
                return nil
            }
        }

        if let externalAccessSwitchArray = dict["external_access_switch"] as? [[String: Int]] {
            externalAccessSwitch = externalAccessSwitchArray.compactMap { dic in
                if let value = dic["value"],
                   let blockTypeValue = dic["block_type"],
                   let valueType = BlockOptions.ExternalAccessSwitchType(rawValue: value),
                   let blockType = BlockOptions.BlockType(rawValue: blockTypeValue) {
                    return ExternalAccessSwitch(value: valueType, blockType: blockType)
                }
                return nil
            }
        }

        if let linkShareEntityArray = dict["link_share_entity"] as? [[String: Int]] {
            linkShareEntity = linkShareEntityArray.compactMap { dic in
                if let value = dic["value"],
                   let blockTypeValue = dic["block_type"],
                   let valueType = BlockOptions.LinkShareEntityType(rawValue: value),
                   let blockType = BlockOptions.BlockType(rawValue: blockTypeValue) {
                    return LinkShareEntity(value: valueType, blockType: blockType)
                }
                return nil
            }
        }
        
        if let searchEntityArray = dict["search_entity"] as? [[String: Int]] {
            searchEntity = searchEntityArray.compactMap { dic in
                if let value = dic["value"],
                   let blockTypeValue = dic["block_type"],
                   let valueType = BlockOptions.SearchEntityType(rawValue: value),
                   let blockType = BlockOptions.BlockType(rawValue: blockTypeValue) {
                    return SearchEntity(value: valueType, blockType: blockType)
                }
                return nil
            }
        }

        if let woCanManageCollaboratorsByOrganizationEntityArray = dict["share_entity"] as? [[String: Int]] {
            woCanManageCollaboratorsByOrganizationEntity = woCanManageCollaboratorsByOrganizationEntityArray.compactMap { dic in
                if let value = dic["value"],
                   let blockTypeValue = dic["block_type"],
                   let valueType = WoCanManageCollaboratorsByOrganization(rawValue: value),
                   let blockType = BlockOptions.BlockType(rawValue: blockTypeValue) {
                    return WoCanManageCollaboratorsByOrganizationEntity(value: valueType, blockType: blockType)
                }
                return nil
            }
        }

        if let woCanManageCollaboratorsByPermissionEntityArray = dict["manage_collaborator_entity"] as? [[String: Int]] {
            woCanManageCollaboratorsByPermissionEntity = woCanManageCollaboratorsByPermissionEntityArray.compactMap { dic in
                if let value = dic["value"],
                   let blockTypeValue = dic["block_type"],
                   let valueType = WoCanManageCollaboratorsByPermission(rawValue: value),
                   let blockType = BlockOptions.BlockType(rawValue: blockTypeValue) {
                    return WoCanManageCollaboratorsByPermissionEntity(value: valueType, blockType: blockType)
                }
                return nil
            }
        }

        if let woCanExternalShareByPermissionEntityArray = dict["share_external_entity"] as? [[String: Int]] {
            woCanExternalShareByPermissionEntity = woCanExternalShareByPermissionEntityArray.compactMap { dic in
                if let value = dic["value"],
                   let blockTypeValue = dic["block_type"],
                   let valueType = WoCanExternalShareByPermission(rawValue: value),
                   let blockType = BlockOptions.BlockType(rawValue: blockTypeValue) {
                    return WoCanExternalShareByPermissionEntity(value: valueType, blockType: blockType)
                }
                return nil
            }
        }

        if let woCanApplyEmbedEntityArray = dict["apply_embed_entity"] as? [[String: Int]] {
            woCanApplyEmbedEntity = woCanApplyEmbedEntityArray.compactMap { dic in
                if let value = dic["value"],
                   let blockTypeValue = dic["block_type"],
                   let valueType = WoCanFastApplyPermission(rawValue: value),
                   let blockType = BlockOptions.BlockType(rawValue: blockTypeValue) {
                    return WoCanApplyEmbedEntity(value: valueType, blockType: blockType)
                }
                return nil
            }
        }
    }

    func woCanManageCollaboratorsByOrganization(with value: WoCanManageCollaboratorsByOrganization) -> BlockType {
        return woCanManageCollaboratorsByOrganization(with: value.rawValue)
    }

    func woCanManageCollaboratorsByOrganization(with rawValue: Int) -> BlockType {
        return woCanManageCollaboratorsByOrganizationEntity.first {
            $0.value == WoCanManageCollaboratorsByOrganization(rawValue: rawValue)
        }?.blockType ?? .none
    }


    func woCanManageCollaboratorsByPermission(with value: WoCanManageCollaboratorsByPermission) -> BlockType {
        return woCanManageCollaboratorsByPermission(with: value.rawValue)
    }

    func woCanManageCollaboratorsByPermission(with rawValue: Int) -> BlockType {
        return woCanManageCollaboratorsByPermissionEntity.first {
            $0.value == WoCanManageCollaboratorsByPermission(rawValue: rawValue)
        }?.blockType ?? .none
    }

    func woCanExternalShareByPermission(with value: WoCanExternalShareByPermission) -> BlockType {
        return woCanExternalShareByPermission(with: value.rawValue)
    }

    func woCanExternalShareByPermission(with rawValue: Int) -> BlockType {
        return woCanExternalShareByPermissionEntity.first {
            $0.value == WoCanExternalShareByPermission(rawValue: rawValue)
        }?.blockType ?? .none
    }


    func woCanFastApplyPermission(with value: WoCanFastApplyPermission) -> BlockType {
        return woCanFastApplyPermission(with: value.rawValue)
    }

    func woCanFastApplyPermission(with rawValue: Int) -> BlockType {
        return woCanApplyEmbedEntity.first {
            $0.value == WoCanFastApplyPermission(rawValue: rawValue)
        }?.blockType ?? .none
    }
    
    func copy(with value: CopyType) -> BlockType {
        return copy(with: value.rawValue)
    }

    func copy(with rawValue: Int) -> BlockType {
        return copyEntity.first {
            $0.value == CopyType(rawValue: rawValue)
        }?.blockType ?? .none
    }

    func security(with value: SecurityType) -> BlockType {
        return security(with: value.rawValue)
    }

    func security(with rawValue: Int) -> BlockType {
        return security.first {
            $0.value == SecurityType(rawValue: rawValue)
        }?.blockType ?? .none
    }
    
    func showCollabortorInfo(with value: ShowCollaboratorInfoEntityType) -> BlockType {
        return showCollabortorInfo(with: value.rawValue)
    }
    
    func showCollabortorInfo(with rawValue: Int) -> BlockType {
        return showCollaboratorInfoEntity.first {
            $0.value == ShowCollaboratorInfoEntityType(rawValue: rawValue)
        }?.blockType ?? .none
    }

    func comment(with value: CommentType) -> BlockType {
        return comment(with: value.rawValue)
    }
    func comment(with rawValue: Int) -> BlockType {
        return comment.first {
            $0.value == CommentType(rawValue: rawValue)
        }?.blockType ?? .none
    }

    func externalAccessSwitch(with rawValue: Int) -> BlockType {
        return externalAccessSwitch.first {
            $0.value == ExternalAccessSwitchType(rawValue: rawValue)
        }?.blockType ?? .none
    }

    func linkShareEntity(with value: LinkShareEntityType) -> BlockType {
        return linkShareEntity(with: value.rawValue)
    }
    func linkShareEntity(with rawValue: Int) -> BlockType {
        return linkShareEntity.first {
            $0.value == LinkShareEntityType(rawValue: rawValue)
        }?.blockType ?? .none
    }
    
    func searchEntity(with rawValue: Int) -> BlockType {
        return searchEntity.first {
            $0.value == SearchEntityType(rawValue: rawValue)
        }?.blockType ?? .none
    }
}


/// 由于 文档公共权限 和 共享文件夹的权限 使用的 model 高度重合，且 share 入口是通用的导航栏内逻辑，所以采用同一个
/// 接口文档：https://bytedance.feishu.cn/docs/NuM5adQ91RnB4BbOw7HwAe#7bslEW
public struct PublicPermissionMeta: Equatable {
    /// 是否是文档、共享文件夹的所有者
    public var isOwner: Bool = false

    /// 租户管理员后台配置，如果是 true 代表租户内的成员可以将文档分享到外部
    ///
    /// 它决定着:
    /// 1. 是否要在 **权限设置页** 显示顶部“允许文档被分享到组织外”的开关
    /// 2. 是否要在 **链接共享页** 显示“获得链接的任何人可阅读、编辑”两个选项
    ///
    /// 仅在不支持统一权限的类型上才应该使用（表单、妙记、1.0 文件夹等）
    @available(*, deprecated, message: "Use .adminExternalAccess instead")
    public var canCross: Bool = true

    /// 租户管理员后台配置，如果是 true 代表租户内的成员可以将文档分享到外部
    ///
    /// 它决定着:
    /// 1. 是否要在 **权限设置页** 显示顶部“允许文档被分享到组织外”或“允许文档被分享到关联组织”的开关
    /// 2. 是否要在 **链接共享页** 显示“获得链接的任何人可阅读、编辑”或“关联组织获得链接的任何人可阅读、编辑”两个选项
    public var adminExternalAccess: ExternalAccessEntity?

    /// 决定“允许文档被分享到组织外"开关状态，不支持关联组织，待废弃
    /// 仅在不支持统一权限的类型上才应该使用（表单、妙记、1.0 文件夹等）
    @available(*, deprecated, message: "Use .externalAccessEntity insteal")
    public var externalAccess: Bool = false

    // 决定“允许文档被分享到外部"开关状态，分为所有外部和关联组织范围
    public var externalAccessEntity: ExternalAccessEntity?

    /// 决定着能够邀请多大范围的用户成为协作者
    ///
    /// 对于 owner 来说，这个值不起约束作用，因为 owner 可以随便邀请任何人成为协作者。
    ///
    /// 对于非 owner 来说，在"允许文档被分享到组织外"开关打开时（externalAccess 和 canCross 是 true）：
    ///
    /// 如果只是有访问权限的同租户用户才能在管理协作者，
    /// 添加协作者的时候 false: 只能邀请同租户用户为协作者 true: 可以邀请所有租户用户为协作者
    public var inviteExternal: Bool = false

    /// 旧版链接设置，待废弃
    /// 仅在不支持统一权限的类型上才应该使用（表单、妙记、1.0 文件夹等）
    @available(*, deprecated, message: "use linkShareEntityV2 instead")
    public var linkShareEntity: LinkShareEntity = .close

    /// 新版链接设置，支持关联组织
    public var linkShareEntityV2: LinkShareEntityV2?
    
    /// 可搜索设置
    public var searchEntity: SearchEntity = .tenantCanSearch

    /// 评论设置
    public var commentEntity: CommentEntity = .userCanRead

    /// 共享设置
    public var shareEntity: ShareEntity = .onlyMe

    /// 复制设置
    public var copyEntity: CopyEntity = .userCanRead
    
    /// 安全设置
    public var securityEntity: SecurityEntity = .userCanRead
    
    /// 查看协作者信息设置
    public var showCollaboratorInfoEntity: ShowCollaboratorInfoEntity = .userCanRead

    /// 为 true 时，在设置“获得链接的任何人可阅读、编辑”时，会出现一个 Alert 弹窗
    public var remindAnyoneLink: Bool = false

    /// 分享密码相关
    public var hasLinkPassword: Bool = false
    public var linkPassword: String = ""
    
    /**** 单容器版增加字段 **** */
    /// 加锁状态 false表示未加锁、true表示加锁
    public var lockState: Bool = false
    
    /// 是否可以解锁，true则展示解锁入口，false则不展示解锁入口
    public var canUnlock: Bool = false
    
    /// 是否有「链接分享」配置选项
    ///文件V2通过这个判断在分享面板是否显示链接分享入口
    public var hasLinkShare: Bool = false
    
    /// 是否是共享文件夹
    public var isShareFolder: Bool = false

    /// 权限设置的类型
    public var permTypeValue: PermTypeValue?

    ///owner类型
    public var ownerPermType: PermTypeValue.PermType = .defaultType

    /// 不可选选项及其说明
    public var blockOptions: BlockOptions?

    ///对外开关权限类型
    public var externalAccessPermType: PermTypeValue.PermType {
        return permTypeValue?.externalAccessSwitch ?? .defaultType
    }

    /// 链接分享权限类型
    public var linkShareEntityType: PermTypeValue.PermType {
        return permTypeValue?.linkShareEntity ?? .defaultType
    }
    
    /// 可搜设置权限类型
    public var searchEntityType: PermTypeValue.PermType {
        return permTypeValue?.linkShareEntity ?? .defaultType
    }

    public var partnerTenantIds: [String] = []

    /// data原始数据
    public var rawValue: String = ""


    /**** 文档权限设置面板改版 增加字段 **** */
    ///谁可以管理协作者——组织维度
    public var woCanManageCollaboratorsByOrganization: WoCanManageCollaboratorsByOrganization = .sameTenant
    ///谁可以管理协作者——权限维度
    public var woCanManageCollaboratorsByPermission: WoCanManageCollaboratorsByPermission = .fullAccess
    /// 谁可对外分享
    public var woCanExternalShareByPermission: WoCanExternalShareByPermission = .fullAccess
    /// 谁能快捷访问无权限的引用文档和快捷申请权限
    public var woCanFastApplyPermission: WoCanFastApplyPermission = .read



    /// Initialize a public permission meta structure.
    public init(
        isOwner: Bool = false,
        canCross: Bool = true,
        adminExternalAccess: ExternalAccessEntity? = .open,
        externalAccess: Bool = false,
        externalAccessEntity: ExternalAccessEntity? = .close,
        inviteExternal: Bool = false,
        remindAnyoneLink: Bool = false,
        hasLinkPassword: Bool = false,
        linkPassword: String = "",
        linkShareEntity: LinkShareEntity = .close,
        linkShareEntityV2: LinkShareEntityV2? = .close,
        searchEntity: SearchEntity = .tenantCanSearch,
        commentEntity: CommentEntity = .userCanEdit,
        shareEntity: ShareEntity = .onlyMe,
        copyEntity: CopyEntity = .userCanEdit,
        securityEntity: SecurityEntity = .userCanEdit,
        woCanManageCollaboratorsByOrganization: WoCanManageCollaboratorsByOrganization = .sameTenant,
        woCanManageCollaboratorsByPermission: WoCanManageCollaboratorsByPermission = .fullAccess,
        woCanExternalShareByPermission: WoCanExternalShareByPermission = .fullAccess,
        woCanFastApplyPermission: WoCanFastApplyPermission = .read,
        lockState: Bool = false,
        canUnlock: Bool = false,
        partnerTenantIds: [String] = []
    ) {
        self.isOwner = isOwner
        self.canCross = canCross
        self.adminExternalAccess = adminExternalAccess
        self.externalAccess = externalAccess
        self.externalAccessEntity = externalAccessEntity
        self.inviteExternal = inviteExternal
        self.remindAnyoneLink = remindAnyoneLink
        self.hasLinkPassword = hasLinkPassword
        self.linkPassword = linkPassword
        self.linkShareEntity = linkShareEntity
        self.linkShareEntityV2 = linkShareEntityV2
        self.searchEntity = searchEntity
        self.commentEntity = commentEntity
        self.shareEntity = shareEntity
        self.copyEntity = copyEntity
        self.securityEntity = securityEntity
        self.lockState = lockState
        self.canUnlock = canUnlock
        self.woCanFastApplyPermission = woCanFastApplyPermission
        self.partnerTenantIds = partnerTenantIds
    }

    /// Initialize a public permission meta structure.
    /// - Parameter json: A JSON object containing the data for the public permission meta.
    public init?(json: JSON) {
        guard !json.isEmpty else {
            DocsLogger.warning("Empty JSON cannot initialize PublicPermissionMeta")
            return nil
        }
        self.rawValue = json.dictionaryObject?.toJSONString() ?? ""
        guard let isOwner = json["is_owner"].bool,
            let canCross = json["admin_can_cross"].bool,
            let externalAccess = json["external_access"].bool
        else {
            spaceAssertionFailure("failed to init a PublicPermissionMeta from \(json)")
            return nil
        }
        self.isOwner = isOwner
        self.canCross = canCross
        self.externalAccess = externalAccess
        if let inviteExternal = json["invite_external"].bool {
            self.inviteExternal = inviteExternal
        }
        if let linkShareEntity = json["link_share_entity"].int {
            self.linkShareEntity = LinkShareEntity(linkShareEntity)
        }
        if let commentEntity = json["comment_entity"].int {
            self.commentEntity = CommentEntity(commentEntity)
        }
        if let shareEntity = json["share_entity"].int {
            self.shareEntity = ShareEntity(shareEntity)
        }
        if let copyEntity = json["copy_entity"].int {
            self.copyEntity = CopyEntity(copyEntity)
        }
        if let securityEntity = json["security_entity"].int {
            self.securityEntity = SecurityEntity(securityEntity)
        }
        if let lockState = json["lock_state"].bool {
            self.lockState = lockState
        }
        if let canUnlock = json["can_unlock"].bool {
            self.canUnlock = canUnlock
        }
        if let hasLinkShare = json["has_link_share"].bool {
            self.hasLinkShare = hasLinkShare
        }
        if let isShareFolder = json["is_share_folder"].bool {
            self.isShareFolder = isShareFolder
        }
        json["has_link_password"].bool.map { self.hasLinkPassword = $0 }
        json["link_password"].string.map { self.linkPassword = $0 }
        json["remind_anyone_link"].bool.map { self.remindAnyoneLink = $0 }
    }

    /// 文件夹V1初始化
    init?(shareFolderJSON: JSON) {
        guard !shareFolderJSON.isEmpty else {
            DocsLogger.warning("empty dic to init PublicPermissionMeta")
            return nil
        }
        self.rawValue = shareFolderJSON.dictionaryObject?.toJSONString() ?? ""
        guard let linkPerm = shareFolderJSON["link_perm"].int,
            let isOwner = shareFolderJSON["is_owner"].bool,
            let canCross = shareFolderJSON["admin_allow_cross"].bool,
            let externalAccess = shareFolderJSON["allow_cross_tenant"].bool,
            let hasLinkPassword = shareFolderJSON["exist_password"].bool else {
                DocsLogger.error("failed to init a PublicPermissionMeta from \(shareFolderJSON)")
                spaceAssertionFailure("failed to init a PublicPermissionMeta from \(shareFolderJSON)")
                return nil
            }
        // V1文件夹链接分享设置是0/1/2/4，文档和V2文件夹是0/1/2/3/4，这里特殊处理，需要把4转成3
        var linkShareEntity = linkPerm
        if linkPerm == 4 {
            linkShareEntity = 3
        }
        self.linkShareEntity = LinkShareEntity(linkShareEntity)
        self.isOwner = isOwner
        self.canCross = canCross
        self.externalAccess = externalAccess
        self.hasLinkPassword = hasLinkPassword
        self.linkPassword = shareFolderJSON["password"].stringValue
        self.remindAnyoneLink = shareFolderJSON["remind_anyone_link"].boolValue
    }

    /// form表单初始化
    public init?(formJSON: JSON) {
        let json = formJSON
        guard !json.isEmpty else {
            DocsLogger.warning("empty dic to init PublicPermissionMeta")
            return nil
        }
        self.rawValue = json.dictionaryObject?.toJSONString() ?? ""
        guard let linkShareEntity = json["linkShareEntity"].int else {
            DocsLogger.error("failed to init a PublicPermissionMeta from \(json)")
            spaceAssertionFailure("failed to init a PublicPermissionMeta from \(json)")
            return nil
        }
        //form表单的情况下，这里是填写限制
        self.linkShareEntity = LinkShareEntity(linkShareEntity)
    }


    /// 文档权限设置面板改版 https://bytedance.feishu.cn/docs/doccnhxXNak4UvAxn1eMSX4F75c#eYrovg
    public init?(newJson: JSON) {
        let json = newJson
        guard !json.isEmpty else {
            DocsLogger.warning("Empty JSON cannot initialize PublicPermissionMeta")
            return nil
        }
        self.rawValue = json.dictionaryObject?.toJSONString() ?? ""
        json["is_owner"].bool.map { self.isOwner = $0 }
        json["admin_can_cross"].bool.map { self.canCross = $0 }
        json["admin_external_access"].int.map { adminExternalAccess = ExternalAccessEntity($0) }
        json["can_unlock"].bool.map { self.canUnlock = $0 }
        json["owner_perm_type"].int.map { self.ownerPermType = PermTypeValue.PermType(rawValue: $0) ?? .defaultType }


        let permPublic = json["perm_public"]
        if let permTypeValue = permPublic["perm_type"].dictionaryObject {
            self.permTypeValue = PermTypeValue(dict: permTypeValue)
        }

        if let blockOptions = permPublic["block_options"].dictionaryObject {
            self.blockOptions = BlockOptions(dict: blockOptions)
        }

        permPublic["share_entity"].int.map { self.woCanManageCollaboratorsByOrganization = WoCanManageCollaboratorsByOrganization($0) }
        permPublic["manage_collaborator_entity"].int.map { self.woCanManageCollaboratorsByPermission = WoCanManageCollaboratorsByPermission($0) }
        permPublic["copy_entity"].int.map { self.copyEntity = CopyEntity($0 - 1) }
        permPublic["security_entity"].int.map { self.securityEntity = SecurityEntity($0 - 1) }
        permPublic["show_collaborator_info_entity"].int.map { self.showCollaboratorInfoEntity = ShowCollaboratorInfoEntity($0) }
        permPublic["comment_entity"].int.map { self.commentEntity = CommentEntity($0 - 1) }
        permPublic["link_share_entity"].int.map { self.linkShareEntity = LinkShareEntity($0 - 1) }
        permPublic["link_share_entity_v2"].int.map { linkShareEntityV2 = LinkShareEntityV2($0) }
        permPublic["search_entity"].int.map { self.searchEntity = SearchEntity($0) }
        permPublic["share_external_entity"].int.map { self.woCanExternalShareByPermission = WoCanExternalShareByPermission($0) }
        permPublic["apply_embed_entity"].int.map { self.woCanFastApplyPermission = WoCanFastApplyPermission($0) }
        permPublic["link_password_switch"].bool.map { self.hasLinkPassword = $0 }
        permPublic["link_password"].string.map { self.linkPassword = $0 }
        permPublic["external_access_switch"].bool.map { self.externalAccess = $0 }
        permPublic["external_access_entity"].int.map { externalAccessEntity = ExternalAccessEntity($0) }
        permPublic["lock_switch"].bool.map { self.lockState = $0 }
        partnerTenantIds = json["partner_tenant_ids"].arrayValue.compactMap({ json in
            return json.string
        })
    }

    ///文件夹统一管控新增 https://bytedance.feishu.cn/docs/doccn4eFq5aLXoAcVmWGrX6Xueh#
    public init?(v2FolderJson: JSON) {
        let json = v2FolderJson
        guard !json.isEmpty else {
            DocsLogger.warning("Empty JSON cannot initialize PublicPermissionMeta")
            return nil
        }
        self.rawValue = json.dictionaryObject?.toJSONString() ?? ""
        json["is_owner"].bool.map { self.isOwner = $0 }
        json["admin_can_cross"].bool.map { self.canCross = $0 }
        json["admin_external_access"].int.map { adminExternalAccess = ExternalAccessEntity($0) }
        json["can_unlock"].bool.map { self.canUnlock = $0 }
        json["is_share_folder"].bool.map { self.isShareFolder = $0 }

        let permPublic = json["perm_public"]
        if let blockOptions = permPublic["block_options"].dictionaryObject {
            self.blockOptions = BlockOptions(dict: blockOptions)
        }
        permPublic["share_entity"].int.map { self.woCanManageCollaboratorsByOrganization = WoCanManageCollaboratorsByOrganization($0) }
        permPublic["manage_collaborator_entity"].int.map { self.woCanManageCollaboratorsByPermission = WoCanManageCollaboratorsByPermission($0) }
        permPublic["security_entity"].int.map { self.securityEntity = SecurityEntity($0 - 1) }
        permPublic["comment_entity"].int.map { self.commentEntity = CommentEntity($0 - 1) }
        permPublic["link_share_entity"].int.map { self.linkShareEntity = LinkShareEntity($0 - 1) }
        permPublic["link_share_entity_v2"].int.map { linkShareEntityV2 = LinkShareEntityV2($0) }
        permPublic["share_external_entity"].int.map { self.woCanExternalShareByPermission = WoCanExternalShareByPermission($0) }
        permPublic["apply_embed_entity"].int.map { self.woCanFastApplyPermission = WoCanFastApplyPermission($0) }
        permPublic["link_password_switch"].bool.map { self.hasLinkPassword = $0 }
        permPublic["link_password"].string.map { self.linkPassword = $0 }
        permPublic["external_access_switch"].bool.map { self.externalAccess = $0 }
        permPublic["external_access_entity"].int.map { externalAccessEntity = ExternalAccessEntity($0) }
        permPublic["lock_switch"].bool.map { self.lockState = $0 }

        /// 新接口后端默认不返回，为了兼容旧逻辑，这里不返回就是true
        hasLinkShare = permPublic["has_link_share"].bool ?? true
    }

    public static func == (lhs: PublicPermissionMeta, rhs: PublicPermissionMeta) -> Bool {
        return lhs.canCross == rhs.canCross
            && lhs.adminExternalAccess == rhs.adminExternalAccess
            && lhs.commentEntity.rawValue == rhs.commentEntity.rawValue
            && lhs.externalAccess == rhs.externalAccess
            && lhs.externalAccessEntity == rhs.externalAccessEntity
            && lhs.hasLinkPassword == rhs.hasLinkPassword
            && lhs.inviteExternal == rhs.inviteExternal
            && lhs.isOwner == rhs.isOwner
            && lhs.linkPassword.elementsEqual(rhs.linkPassword)
            && lhs.linkShareEntity.rawValue == rhs.linkShareEntity.rawValue
            && lhs.linkShareEntityV2 == rhs.linkShareEntityV2
            && lhs.remindAnyoneLink == rhs.remindAnyoneLink
            && lhs.securityEntity.rawValue == rhs.securityEntity.rawValue
            && lhs.shareEntity.rawValue == rhs.shareEntity.rawValue
            && lhs.lockState == rhs.lockState
            && lhs.canUnlock == rhs.canUnlock
            && lhs.woCanManageCollaboratorsByOrganization == rhs.woCanManageCollaboratorsByOrganization
            && lhs.woCanManageCollaboratorsByPermission == rhs.woCanManageCollaboratorsByPermission
            && lhs.woCanExternalShareByPermission == rhs.woCanExternalShareByPermission
            && lhs.woCanFastApplyPermission == rhs.woCanFastApplyPermission
    }
}

//谁可以管理协作者——组织维度
public enum WoCanManageCollaboratorsByOrganization: Int {
    case sameTenant = 1                      // 组织内
    case anyone                         // 所有人

    // 推荐使用这个初始化方法，统一收敛默认值
    init(_ value: Int) {
        self = WoCanManageCollaboratorsByOrganization(rawValue: value) ?? .anyone
    }
}

// 谁可以管理协作者——权限维度
public enum WoCanManageCollaboratorsByPermission: Int {
    case read = 1                       // 可阅读
    case edit                         // 可编辑
    case fullAccess                         // 只有我/所有权限

    // 推荐使用这个初始化方法，统一收敛默认值
    init(_ value: Int) {
        self = WoCanManageCollaboratorsByPermission(rawValue: value) ?? .fullAccess
    }
}

// 谁可对外分享
public enum WoCanExternalShareByPermission: Int {
    case read = 1                 // 可阅读此文档的用户
    case edit                    // 可编辑此文档的用户 (移动端没用)
    case fullAccess                         //只有我/所有权限

    // 推荐使用这个初始化方法，统一收敛默认值
    init(_ value: Int) {
        self = WoCanExternalShareByPermission(rawValue: value) ?? .fullAccess
    }
}

// 谁能快捷访问无权限的引用文档和快捷申请权限
public enum WoCanFastApplyPermission: Int {
    case read = 1                 // 可阅读此文档的用户
    case edit                    // 可编辑此文档的用户 (移动端没用)
    case fullAccess                         //只有我/所有权限

    // 推荐使用这个初始化方法，统一收敛默认值
    init(_ value: Int) {
        self = WoCanFastApplyPermission(rawValue: value) ?? .read
    }
}

// 收敛关联组织需求导致的对外共享逻辑变化
// https://bytedance.feishu.cn/docx/doxcnt1z0fmcxetuFhwfajwVYGh
public extension PublicPermissionMeta {

    var partnerTenantPermissionEnabled: Bool {
        if adminExternalAccess != nil,
           externalAccessEntity != nil {
            // 后端返回了新的字段，才可使用新的字段与后端交互
            return true
        } else {
            return false
        }
    }

    // 是否允许邀请外部协作者
    var allowInviteExternalCollaborator: Bool {
        if let adminExternalAccess = adminExternalAccess,
           let externalAccessEntity = externalAccessEntity {
            // admin 允许对外或对关联组织共享，且文档允许对外或关联组织共享
            return adminExternalAccess != .close && externalAccessEntity != .close
        } else {
            return canCross && externalAccess
        }
    }

    // 是否仅允许邀请外部人，禁止邀请外部群等其他类型协作者，关联组织共享状态的特化逻辑
    var allowInviteExternalUserOnly: Bool {
        guard let adminExternalAccess = adminExternalAccess,
              let externalAccessEntity = externalAccessEntity else {
                  // 旧逻辑不禁止邀请外部群、会议等非用户协作者
                  return false
              }
        return adminExternalAccess != .close && externalAccessEntity == .partnerTenant
    }

    // 是否被用户而非 admin 禁止分享给外部协作者
    var forbiddenExternalCollaboratorByUser: Bool {
        guard let adminExternalAccess = adminExternalAccess,
              let externalAccessEntity = externalAccessEntity else {
            return canCross && !externalAccess
        }
        return adminExternalAccess != .close && externalAccessEntity == .close
    }

    func externalCollaboratorForbiddenReason(isFolder: Bool, isWiki: Bool) -> String {

        guard let adminExternalAccess = adminExternalAccess,
              let externalAccessEntity = externalAccessEntity else {
                  if !canCross {
                      return BundleI18n.SKResource.CreationMobile_Wiki_SharePanel_ExternalOffOrg
                  }
                  if isFolder {
                      return BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_Enable_folder_toast
                  } else {
                      if isWiki && blockOptions?.externalAccessSwitch(with: ExternalAccessEntity.open.rawValue) == .containerLimit {
                          return BundleI18n.SKResource.CreationMobile_Wiki_Permission_CannotShareExternally_Toast
                      } else {
                          return BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_Enable_toast
                      }
                  }
              }

        switch (adminExternalAccess, externalAccessEntity) {
        case (.close, _):
            return BundleI18n.SKResource.CreationMobile_Wiki_SharePanel_ExternalOffOrg
        case (.partnerTenant, .close):
            if isFolder {
                return BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_EnableTrustParty_folder_toast
            } else {
                return BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_EnableTrustParty_toast
            }
        case (.open, .close):
            if isFolder {
                return BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_Enable_folder_toast
            } else {
                if isWiki && blockOptions?.externalAccessSwitch(with: ExternalAccessEntity.open.rawValue) == .containerLimit {
                    return BundleI18n.SKResource.CreationMobile_Wiki_Permission_CannotShareExternally_Toast
                } else {
                    return BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_Enable_toast
                }
            }
        default:
            spaceAssertionFailure("unknown forbidden reason")
            return BundleI18n.SKResource.CreationMobile_Wiki_SharePanel_ExternalOffOrg
        }
    }

    //权限设置添加协作者选项为：组织内所有可阅读或编辑此文档的用户（仅可邀请组织内用户） 或 只有我可以时，若邀请的协作者中存在外部用户，需要ask owner
    // TODO: 确认下关联组织分享状态下的表现
    var shouldAskOwnerWhenInviteExternal: Bool {
        guard let adminExternalAccess = adminExternalAccess,
              let externalAccessEntity = externalAccessEntity else {
                  return canCross && (inviteExternal || externalAccess)
              }
        return adminExternalAccess != .close && externalAccessEntity != .close
    }

    // MARK: UI
    // 对外共享开关以及链接分享选项是否可见
    var canShowExternalAccessSwitch: Bool {
        guard let adminExternalAccess = adminExternalAccess else {
                  return canCross
              }
        return adminExternalAccess == .open
    }

    // 对外共享开关状态
    var externalAccessEnable: Bool {
        guard let adminExternalAccess = adminExternalAccess,
              let externalAccessEntity = externalAccessEntity else {
                  return canCross && externalAccess
              }
        return adminExternalAccess == .open && externalAccessEntity == .open
    }

    mutating func update(externalAccessEnable: Bool) {
        externalAccess = true
        if externalAccessEntity != nil {
            externalAccessEntity = .open
        }
    }

    var canShowPartnerTenantAccessSwitch: Bool {
        guard let adminExternalAccess = adminExternalAccess,
              let externalAccessEntity = externalAccessEntity else {
                  return false
              }
        switch (adminExternalAccess, externalAccessEntity) {
        case (.close, _),
            (.open, .open),
            (.open, .close):
            return false
        case (.partnerTenant, _),
            (.open, .partnerTenant):
            return true
        }
    }

    var partnerTenantAccessEnable: Bool {
        guard let adminExternalAccess = adminExternalAccess,
              let externalAccessEntity = externalAccessEntity else {
                  return false
              }
        return adminExternalAccess != .close && externalAccessEntity == .partnerTenant
    }
}
