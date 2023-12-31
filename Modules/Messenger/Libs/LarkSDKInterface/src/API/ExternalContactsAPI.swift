//
//  ContactsAPI.swift
//  LarkSDKInterface
//
//  Created by 姚启灏 on 2018/8/14.
//

import Foundation
import RxSwift
import LarkModel
import LarkContainer
import RustPB

public final class Contact {
    public typealias PBModel = RustPB.Basic_V1_Contact

    public var id: String
    public var chatterId: String
    public var isDeleted: Bool
    public var chatter: Chatter?

    public init(id: String,
                chatterId: String,
                isDeleted: Bool) {
        self.id = id
        self.chatterId = chatterId
        self.isDeleted = isDeleted
    }

    public static func transform(pb: PBModel) -> Contact {
        return Contact(id: pb.id,
                       chatterId: pb.chatterID,
                       isDeleted: pb.isDeleted)
    }
}

extension Contact: Equatable {
    public static func == (lhs: Contact, rhs: Contact) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct ExternalContacts {
    public var contacts: [Contact]
    public var hasMore: Bool

    public init(contacts: [Contact], hasMore: Bool) {
        self.contacts = contacts
        self.hasMore = hasMore
    }
}

/// 导致IM会话的引导banner状态发生变化的实时事件的推送
public struct PushContactApplicationBannerAffectEvent: PushMessage {
    public let targetUserIds: [String]

    public init(targetUserIds: [String]) {
        self.targetUserIds = targetUserIds
    }
}

public struct PushContactsInfo: PushMessage {
    public let contactInfo: RustPB.Basic_V1_ContactInfo

    public init(contactInfo: RustPB.Basic_V1_ContactInfo) {
        self.contactInfo = contactInfo
    }
}

public struct PushBlockStatus: PushMessage {
    public var blockedUserID: String
    public var blockStatus: Bool
    public init(blockedUserID: String, blockStatus: Bool) {
        self.blockedUserID = blockedUserID
        self.blockStatus = blockStatus
    }
}

///  用于选人外部联系人
public struct ExternalContactsWithChatterIds {
    public let externalContacts: ExternalContacts
    /// 当前会话中的id
    public let chatterIDs: [String]
    /// 鉴权未过原因
    public let deniedReasons: [String: RustPB.Basic_V1_Auth_DeniedReason]

    public init(externalContacts: ExternalContacts, chatterIDs: [String], deniedReasons: [String: RustPB.Basic_V1_Auth_DeniedReason]) {
        self.externalContacts = externalContacts
        self.chatterIDs = chatterIDs
        self.deniedReasons = deniedReasons
    }
}

public struct NewExternalContacts {
    public var contactInfos: [ContactInfo]

    public init(contactInfos: [ContactInfo]) {
        self.contactInfos = contactInfos
    }
}

public struct ExternalContactPushInfo {
    public var contactInfo: ContactInfo
    public let isDeleted: Bool

    public init(contactInfo: ContactInfo, isDeleted: Bool? = false) {
        self.contactInfo = contactInfo
        self.isDeleted = isDeleted ?? false
    }
}

public struct PushNewExternalContacts {
    public var contactPushInfos: [ExternalContactPushInfo]

    public init(contactPushInfos: [ExternalContactPushInfo]) {
        self.contactPushInfos = contactPushInfos
    }
}

public struct NewSelectExternalContact {
    public let contactInfo: ContactInfo
    public var chatter: Chatter?
    public var deniedReason: RustPB.Basic_V1_Auth_DeniedReason?

    public init(
        contactInfo: ContactInfo,
        chatter: Chatter? = nil,
        deniedReason: RustPB.Basic_V1_Auth_DeniedReason? = nil
    ) {
        self.contactInfo = contactInfo
        self.chatter = chatter
        self.deniedReason = deniedReason
    }
}

///选人外部联系人（chatterIDs为已在chat中的人）
public struct NewExternalContactsWithChatterIds {
    public let selectExternalContacts: [NewSelectExternalContact]
    public let chatterIDs: [String]
    /// 鉴权未过原因
    public let hasMore: Bool

    public init(
        selectExternalContacts: [NewSelectExternalContact],
        chatterIDs: [String],
        hasMore: Bool
    ) {
        self.selectExternalContacts = selectExternalContacts
        self.chatterIDs = chatterIDs
        self.hasMore = hasMore
    }
}

public struct ContactsGroupInfo {
    // 分组标题
    public var groupTitle: String
    // 每组的联系人
    public var contacts: [ContactInfo]
    public init(groupTitle: String,
                contacts: [ContactInfo]) {
        self.groupTitle = groupTitle
        self.contacts = contacts
    }
}

public final class ContactInfo {

    // swiftlint:disable identifier_name
    public var userID: String
    public var userName: String
    public var nameWithAnotherName: String
    public var avatarKey: String
    public var namePy: String
    public var alias: String
    public var tenantName: String
    public var tenantID: String
    // 成为好友的时间戳，单位秒
    public var agreeTime: Int
    public var description_p: String
    public var isSpecialFocus: Bool
    public var tenantNameStatus: RustPB.Basic_V1_TenantNameStatus
    public var certificationInfo: RustPB.Basic_V1_CertificationInfo

    public init(userID: String,
                userName: String,
                nameWithAnotherName: String,
                avatarKey: String,
                namePy: String,
                alias: String,
                tenantName: String,
                tenantID: String,
                agreeTime: Int,
                isSpecialFocus: Bool = false,
                description_p: String,
                tenantNameStatus: RustPB.Basic_V1_TenantNameStatus,
                certificationInfo: RustPB.Basic_V1_CertificationInfo) {
        self.userID = userID
        self.userName = userName
        self.nameWithAnotherName = nameWithAnotherName
        self.avatarKey = avatarKey
        self.namePy = namePy
        self.alias = alias
        self.tenantName = tenantName
        self.tenantID = tenantID
        self.agreeTime = agreeTime
        self.description_p = description_p
        self.tenantNameStatus = tenantNameStatus
        self.isSpecialFocus = isSpecialFocus
        self.certificationInfo = certificationInfo
    }

    public static func transform(contactInfoPB: RustPB.Basic_V1_ContactInfo) -> ContactInfo {
        let userInfo = contactInfoPB.userInfo
        return ContactInfo(userID: userInfo.userID,
                           userName: userInfo.userName,
                           nameWithAnotherName: userInfo.nameWithAnotherName,
                           avatarKey: userInfo.avatarKey,
                           namePy: userInfo.namePy,
                           alias: userInfo.alias,
                           tenantName: userInfo.tenantName,
                           tenantID: userInfo.tenantID,
                           agreeTime: 2,
                           isSpecialFocus: userInfo.isSpecialFocus,
                           description_p: userInfo.description_p,
                           tenantNameStatus: userInfo.tenantNameStatus,
                           certificationInfo: userInfo.certificationInfo)
    }
    // swiftlint:enable identifier_name
}

extension ContactInfo: Equatable {
    public static func == (lhs: ContactInfo, rhs: ContactInfo) -> Bool {
        return lhs.userID == rhs.userID
    }
}

public typealias SetupBlockUserResponse = RustPB.Contact_V2_SetupBlockUserResponse

public typealias IgnoreContactApplyResponse = RustPB.Contact_V2_IgnoreContactApplyResponse

public typealias MSendContactApplicationResponse = RustPB.Contact_V2_MSendContactApplicationResponse

public typealias FetchUserRelationResponse = RustPB.Contact_V2_GetUserRelationResponse

public typealias FetchAuthChattersResponse = RustPB.Contact_V2_GetAuthChattersResponse

public typealias CheckP2PChatsExistByUserResponse = RustPB.Im_V1_CheckP2PChatsExistByUserResponse

public protocol ExternalContactsAPI {
    /// 拉取外部联系人列表
    func fetchExternalContacts(cursor: String, count: Int) -> Observable<ExternalContacts>

    /// 删除外部联系人
    func deleteContact(userId: String) -> Observable<Void>

    /// 拉取tenantx信息
    func fetchTenant(tenantIds: [String]) -> Observable<[Tenant]>

    /// 先尝试从本地拉取 tenant 信息
    func getTenant(tenantIds: [String]) -> Observable<[Tenant]>

    /// 拉取选人外部联系人
    func fetchExternalContacts(with chatID: String?, businessScene: RustPB.Basic_V1_Auth_ActionType?, cursor: String, count: Int) -> Observable<ExternalContactsWithChatterIds>

    /// 获取外部联系人列表
    /// @params strategy: 数据拉取策略，支持 local 和 forceServer
    /// @params offset: 从哪个偏移位置开始拉取, 默认从 0 开始拉
    /// @params limitCount: 一次取多少条数据
    func getNewExternalContactList(strategy: RustPB.Basic_V1_SyncDataStrategy?,
                                offset: Int?,
                                limitCount: Int?) -> Observable<NewExternalContacts>

    /// 拉取选人外部联系人列表（带协作权限信息）
    func fetchExternalContactsWithCollaborationAuth(
        with chatID: String?,
        actionType: RustPB.Basic_V1_Auth_ActionType?,
        offset: Int?,
        count: Int?
    ) -> Observable<NewExternalContactsWithChatterIds>

    /// 屏蔽/取消屏蔽
    func setupUserBlockUserRequest(blockUserId: String, blockStatus: Bool) -> Observable<SetupBlockUserResponse>

    /// 关闭联系人的好友申请 Banner
    func ignoreContactApplyRequest(userId: String) -> Observable<IgnoreContactApplyResponse>

    // 获取外部用户的关系
    func fetchUserRelationRequest(userId: String) -> Observable<FetchUserRelationResponse>

    /// 批量发送好友申请
    func mSendContactApplicationRequest(userIds: [String],
                                        extraMessage: String?,
                                        sourceInfos: [String: RustPB.Contact_V2_SourceInfo]
    ) -> Observable<MSendContactApplicationResponse>

    // 批量查询外部联系人的chatId
    func checkP2PChatsExistByUserRequest(chatterIds: [String]) -> Observable<CheckP2PChatsExistByUserResponse>

}

public final class Tenant {
    public typealias PBModel = RustPB.Basic_V1_Tenant

    public var id: String
    public var name: String
    public var contactName: String
    public var contactMobile: String
    public var contactEmail: String
    public var address: String
    public var domain: String
    public var postCode: String
    public var remark: String
    public var telephone: String
    public var iconUrl: String
    public var unitLeague: String

    public init(
        id: String,
        name: String,
        contactName: String,
        contactMobile: String,
        contactEmail: String,
        address: String,
        domain: String,
        postCode: String,
        remark: String,
        telephone: String,
        iconUrl: String,
        unitLeague: String) {
        self.id = id
        self.name = name
        self.contactName = contactName
        self.contactMobile = contactMobile
        self.contactEmail = contactEmail
        self.address = address
        self.domain = domain
        self.postCode = postCode
        self.remark = remark
        self.telephone = telephone
        self.iconUrl = iconUrl
        self.unitLeague = unitLeague
    }

    public static func transform(pb: PBModel) -> Tenant {
        return Tenant(
            id: pb.id,
            name: pb.name,
            contactName: pb.contactName,
            contactMobile: pb.contactMobile,
            contactEmail: pb.contactEmail,
            address: pb.address,
            domain: pb.domain,
            postCode: pb.postCode,
            remark: pb.remark,
            telephone: pb.telephone,
            iconUrl: pb.iconURL,
            unitLeague: pb.unitLeague)
    }
}

public enum UserGroupSceneType: Int {
    /// 未知场景，强制要求业务显式传入具体业务
    case unknown = 0
    /// 云文档
    case ccm = 1
    /// 日历
    case calendar = 2
    /// 服务台
    case helpDesk = 3
    /// 审批
    case approval = 4
    /// 订阅号
    case subscriptions = 5
    /// OKR
    case okr = 6
    /// 开放平台
    case openPlatform = 7
    /// 词典
    case dictionary = 8
    /// 工作台
    case appCenter = 9
}

public enum UserGroupType: Int32 {
    /// 静态用户组
    case normal = 1
    /// 动态用户组
    case dynamic = 2
}

public struct SelectVisibleUserGroup {
    public let groupType: UserGroupType
    public var id: String
    public var name: String

    public init(
        id: String,
        name: String,
        groupType: UserGroupType
    ) {
        self.id = id
        self.name = name
        self.groupType = groupType
    }
}
