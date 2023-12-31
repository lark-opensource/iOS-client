//  Created by Songwen Ding on 2018/4/9.

import Foundation
import SKResource

// nolint: magic_number 
public enum CollaboratorType: Int {
    case user = 0
    case larkUser = 1                               // 文档小助手机器人，这个一般用来告诉后台通过bot发消息给目标用户
    case group = 2                                  // Lark群
    case common = 4                                 // 公共
    case folder = 5                                 // 共享文件夹
    case meeting = 9                                // 会议纪要
    case knowledgeBase = 10                         // 老 wiki 成员
    case temporaryMeetingGroup = 14                 // 临时会议群组，UserPermissionType = 1
    case permanentMeetingGroup = 15                 // 永久会议群组（从会议群转成的通常群）
    case wikiUser = 16                              // 新 wiki 成员（在用）
    case organization = 18
    case app = 19                                   //应用
    case userGroup = 22                             // 用户组（动态）
    case newWikiAdmin = 23                          // wiki2.0知识空间管理员
    case newWikiMember = 24                         // wiki2.0空间内容阅读者
    case newWikiEditor = 28                         // wiki2.0空间内容编辑者
    case email = 29                                 // 邮箱协作者
    case userGroupAssign = 30                       // 静态用户组
    case hostDoc = 110                              // 宿主文档
    case ownerLeader = 111                          // 文档 Owner 上级协作者

    public init?(rawValue: Int) {
        switch rawValue {
        case 0, 1:
            self = .user
        case 2:
            self = .group
        case 4:
            self = .common
        case 5:
            self = .folder
        case 9:
            self = .meeting
        case 10:
            self = .knowledgeBase
        case 14:
            self = .temporaryMeetingGroup
        case 15:
            self = .permanentMeetingGroup
        case 16:
            self = .wikiUser
        case 18:
            self = .organization
        case 19:
            self = .app
        case 22:
            self = .userGroup
        case 23:
            self = .newWikiAdmin
        case 24:
            self = .newWikiMember
        case 28:
            self = .newWikiEditor
        case 29:
            self = .email
        case 30:
            self = .userGroupAssign
        case 110:
            self = .hostDoc
        case 111:
            self = .ownerLeader
        default:
            //spaceAssertionFailure("unknown collaboratorType \(rawValue)")
            return nil
        }
    }

    /// 共享文件夹的协作者类型解析
    /// (以前都统一用上面的init方法进行解析，有bug)
    /// - Parameter value:
    /// - Returns: 协作者类型
    public static func shareFolderType(_ value: Int) -> CollaboratorType {
        switch value {
        case 0:
            return .user
        case 1:
            return .group
        case 18:
            return .organization
        case 19:
            return .app
        case 22:
            return .userGroup
        case 30:
            return .userGroupAssign
        default:
            return .user
        }
    }
    
    public var isNewWikiAdminOrMemberType: Bool {
        self == .newWikiAdmin || self == .newWikiMember
    }
}

// 协作者之间的屏蔽关系
// 接口文档: https://bytedance.feishu.cn/docs/doccnC5loE86rWKeflX4mdOmqOf#
public enum BlockStatus: Int {
    case none                   // 0: 默认没有屏蔽
    case blockedByThisUser      // 1: 被当前这个用户屏蔽
    case blockThisUser          // 2: 搜索者把当前用户屏蔽了
    case privacySetting         // 3: 隐私设置
    case blockedByCac = 2002          // 2002: cac管控

    // 推荐使用这个初始化方法，统一收敛默认值
    init(_ value: Int) {
        self = BlockStatus(rawValue: value) ?? .none
    }
}


public final class Collaborator: Hashable {
    enum AccountType: String {
        /// 单品注册的用户_已注册
        case singleProductHasReg = "singleproduct_hasreg"
        /// 单品注册的用户_未注册
        case singleProductNoReg = "singleproduct_noreg"
        /// 套件注册的个人用户（小b)
        case suitePersonalUser = "suite_personal_user"
        /// 套件企业版的用户（B）
        case suiteEnterpriselUser = "suite_enterprisel_user"
        /// C端用户（C）
        case suiteTocUser = "suite_toc_user"
    }

    public var isRoleInherited: Bool?
    public var canModifyRole: Bool?

    public var type: CollaboratorType?
    public let rawValue: Int
    public let userID: String
    public var name: String
    public let avatarURL: String
    public let avatarImage: UIImage?
    public var imageKey: String
    public var iconToken: String
    public var extraInfo: ExtraInfo?
    public var userPermissions: UserPermissionAbility // 可同时拥有 评论、编辑 权限
    public var publicPermissions: PublicPermissionMeta?
    public var blockExternal: Bool = false
    public var blockStatus: BlockStatus
    public var isOwner: Bool = false
    public var groupDescription: String
    var wikiDescription: String?
    var emailDescription: String?
    var tooltipsType: Int = 0
    var departmentName: String?
//    var isFolderOwner: Int? //only collaborator in share folder will have this value
    public var isExternal: Bool
    var hasTips: Bool  // 协作者列表接口，新增共享文件夹提示字段（has_tips）
    public var isCrossTenant: Bool
    public var tenantID: String?
    /// 企业邮箱
    public var enterpriseEmail: String?
    var tenantName: String?
    var permissionValue: Int?
    var canModify = false
    var inviterID: String?
    var userType: SKUserType?
    var phoneNumber: String?
    var isFriend: Bool?
    var permSource: String?
    /// It is a LarkDcos User
    var isSingleProduct: Bool?
    /// This is false for unregistered users
    var isRealUser: Bool = true
    /// 搜索的判断是否已在协作者列表
    public var isExist: Bool = false
    public var userCount: Int = 1
    public var isUserCountVisible: Bool = true
    /// 后端下发自定义AdminTag文案
    public var organizationTagValue: String?

    public var v2SearchSubTitle: String?

    /// For statistical
    var accountType: AccountType? {
        guard let userType = self.userType, let isSingleProduct = self.isSingleProduct else { return nil }
        if !isRealUser {
            return .singleProductNoReg
        } else if isSingleProduct {
            return .singleProductHasReg
        } else if userType == .c {
            return .suiteTocUser
        } else if userType == .simple {
            return .suitePersonalUser
        } else if userType == .standard {
            return .suiteEnterpriselUser
        } else {
            return nil
        }
    }

    public init(rawValue: Int,
         userID: String,
         name: String,
         avatarURL: String,
         avatarImage: UIImage?,
         imageKey: String = "",
         iconToken: String = "",
         userPermissions: UserPermissionAbility,
         groupDescription: String?) {
        self.rawValue = rawValue
        self.type = CollaboratorType(rawValue: rawValue)
        self.userID = userID
        self.name = name
        self.avatarURL = avatarURL
        self.avatarImage = avatarImage
        self.imageKey = imageKey
        self.iconToken = iconToken
        self.userPermissions = userPermissions
        self.isExternal = false
        self.isCrossTenant = false
        self.hasTips = false
        self.blockStatus = .none
        if let str = groupDescription, str.isEmpty == false {
            self.groupDescription = str
        } else {
            self.groupDescription = BundleI18n.SKResource.Doc_Facade_NoGroupDesc
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(userID)
        if type?.isNewWikiAdminOrMemberType == true {
            // 「知识库管理员」和「知识库成员」的 uid 相同，所以 hash 还需要加上 type
            hasher.combine(rawValue)
        }
    }
}

extension Collaborator { //仅对共享文件夹协作者生效
    // 协作者类型是否是文件夹类型
    var isShareFolder: Bool {
        return self.type == .folder
    }
}

extension Collaborator {  //Docs添加协助者隐藏部门信息
    var cellDescription: String {
        if type == .email {
            return BundleI18n.SKResource.LarkCCM_Docs_InviteEmail_Note_Descrip()
        } else if isExternal {
            return tenantName ?? ""
        } else {
            switch type {
            case .group:
                return groupDescription
            case .newWikiAdmin, .newWikiMember, .newWikiEditor:
                return wikiDescription ?? ""
            default:
                return departmentName ?? ""
            }
        }
    }
}

extension Collaborator {
    var detail: String? {
        if let subTitleFromSearch = self.v2SearchSubTitle, !subTitleFromSearch.isEmpty {
            return subTitleFromSearch
        }
        switch self.type {
        case .user:
            return self.departmentName
        case .group:
            return self.groupDescription
        case .newWikiAdmin, .newWikiMember, .newWikiEditor:
            return self.wikiDescription
        case .email:
            return BundleI18n.SKResource.LarkCCM_Docs_InviteEmail_Note_Descrip()
        default:
            return nil
        }
    }
}

extension Collaborator: Equatable {
    public static func == (lhs: Collaborator, rhs: Collaborator) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension Collaborator {
    // 是否允许发通知
    var canSendNotification: Bool {
        switch type {
        case .userGroup, .userGroupAssign:
            return false
        default:
            return true
        }
    }
}

public struct ExtraInfo {
    var hostUrl: String?
}
