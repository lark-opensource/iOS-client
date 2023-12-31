//  Created by Da Lei on 2018/3/28.

import Foundation
import SKResource

class CollaboratorCellModel: NSObject {
    var collaborator: Collaborator
    var cellHeight: CGFloat
    init(collaborator: Collaborator, cellHeight: CGFloat) {
        self.collaborator = collaborator
        self.cellHeight = cellHeight
    }
}

class PermissionSectionData {
    var models: [CollaboratorCellModel]
    var identifier: String = ""
    static let CollaboratorIdentifier = "CollaboratorIdentifier"

    init(models: [CollaboratorCellModel], identifier: String) {
        self.models = models
        self.identifier = identifier
    }

    func diffIdentifier() -> NSObjectProtocol {
        return self.identifier as NSObjectProtocol
    }
}

struct PublicPermissionModel {
    var isGray: Bool = false
    let title: String
    let entityValue: Int?
    var submodels: [InviteExternalCellModel]?
    init(title: String, entityValue: Int? = nil) {
        self.title = title
        self.entityValue = entityValue
    }
}

struct InviteExternalCellModel {
    var isGray: Bool = false
    let title: String
    var isSelected = false
    var inviteExternal: Bool
}

public enum PublicPermissionSectionType {
    case crossTenant                        // 是否允许文档被分享到组织外
    case comment                            // 评论
    case share                              // 分享
    case security                           // 安全设置：创建副本

    var requestJSONKey: String {
        switch self {
        case .crossTenant:
            return "external_access"
        case .comment:
            return "comment_entity"
        case .share:
            return "share_entity"
        case .security:
            return "security_entity"
        }
    }
}

public final class PublicPermissionSectionData {
    var type: PublicPermissionSectionType
    var title: String
    var models: [PublicPermissionModel]
    var selectedIndex: Int?

    init(type: PublicPermissionSectionType,
         title: String,
         models: [PublicPermissionModel],
         selectedIndex: Int?) {
        self.type = type
        self.title = title
        self.models = models
        self.selectedIndex = selectedIndex
    }
}

public struct PermissonCopywriting {
    // 拥有所有权限(包含我)的协作者
    static let fullAccessCollaboratorText = BundleI18n.SKResource.CreationMobile_ECM_Permission_AddCollaborator_option(BundleI18n.SKResource.CreationMobile_ECM_Permission_fullaccess)
    //拥有编辑权限的协作者
    static let editCollaboratorText = BundleI18n.SKResource.CreationMobile_ECM_Permission_AddCollaborator_option(BundleI18n.SKResource.CreationMobile_ECM_Permission_edit)
    //拥有阅读权限的协作者
    static let viewCollaboratorText = BundleI18n.SKResource.CreationMobile_ECM_Permission_AddCollaborator_option(BundleI18n.SKResource.CreationMobile_ECM_Permission_view)


    // 拥有所有权限(包含我)的用户
    static let fullAccessUserText = BundleI18n.SKResource.CreationMobile_ECM_Permission_Comment_option(BundleI18n.SKResource.CreationMobile_ECM_Permission_fullaccess)
    //拥有编辑权限的用户
    static let editUserText = BundleI18n.SKResource.CreationMobile_ECM_Permission_Comment_option(BundleI18n.SKResource.CreationMobile_ECM_Permission_edit)
    //拥有阅读权限的用户
    static let viewUserText = BundleI18n.SKResource.CreationMobile_ECM_Permission_Comment_option(BundleI18n.SKResource.CreationMobile_ECM_Permission_view)

    //只有我
    static let onlyMeText = BundleI18n.SKResource.CreationMobile_ECM_Permission_OnlyMe
    //谁可以添加协作者
    static let woCanAddCollaboratorText = BundleI18n.SKResource.CreationMobile_ECM_Permission_AddCollaborator_title
    // 仅组织内用户可以添加协作者
    static let onlyTenatCanAddCollaboratorText = BundleI18n.SKResource.CreationMobile_ECM_Permission_AddCollaborator_internal
}
