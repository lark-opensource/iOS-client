//
//  ChatApplicationAPI.swift
//  LarkSDKInterface
//
//  Created by 姚启灏 on 2018/8/14.
//

import Foundation
import RxSwift
import LarkModel
import RustPB
import ServerPB
import LarkContainer

public typealias AddressBookContactList = Contact_V2_GetAddressBookContactListResponse

public struct MobileCode {
    public let key: Int
    public let name: String
    public let enName: String
    public let code: String

    public init(key: Int, name: String, enName: String, code: String) {
        self.key = key
        self.name = name
        self.enName = enName
        self.code = code
    }
}

public struct MobileCodeData {
    public let hotKeys: [Int]
    public let mobileCodes: [MobileCode]

    public init(hotKeys: [Int], mobileCodes: [MobileCode]) {
        self.hotKeys = hotKeys
        self.mobileCodes = mobileCodes
    }
}

/// 添加好友的来源
public struct Source {
    public var sender: String = ""
    public var senderID: String = ""
    public var sourceName: String = ""
    public var sourceID: String = ""
    public var subSourceType: String = ""
    public var sourceType: Basic_V1_ContactSource = .unknownSource
    public init() {}
}

public enum GetType: Int {
    case before = 1
    case after = 2
}

public final class ChatApplication {
    public typealias PBModel = RustPB.Basic_V1_ChatApplication

    public typealias PBModelType = RustPB.Basic_V1_ChatApplication.TypeEnum

    public var id: String
    public var type: RustPB.Basic_V1_ChatApplication.TypeEnum
    public var chatId: String
    public var applyTime: Int64
    public var processedTime: Int64
    public var status: RustPB.Basic_V1_ChatApplication.Status
    public var isRead: Bool
    public var extraMessage: String
    public var contactSummary: ContactSummary

    public init(id: String,
                type: RustPB.Basic_V1_ChatApplication.TypeEnum,
                chatId: String,
                applyTime: Int64,
                processedTime: Int64,
                status: RustPB.Basic_V1_ChatApplication.Status,
                isRead: Bool,
                extraMessage: String,
                contactSummary: ContactSummary) {
        self.id = id
        self.type = type
        self.chatId = chatId
        self.applyTime = applyTime
        self.processedTime = processedTime
        self.status = status
        self.isRead = isRead
        self.extraMessage = extraMessage
        self.contactSummary = contactSummary
    }

    public static func transform(pb: PBModel) -> ChatApplication {
        let contactSummary = ContactSummary.transform(pb: pb.contactSummary)

        return ChatApplication(id: pb.id,
                               type: pb.type,
                               chatId: pb.chatID,
                               applyTime: pb.applyTime,
                               processedTime: pb.processedTime,
                               status: pb.status,
                               isRead: pb.isRead,
                               extraMessage: pb.extraMessage,
                               contactSummary: contactSummary)
    }
}

public final class ContactSummary {
    public typealias PBModel = RustPB.Basic_V1_ContactSummary

    public var userId: String
    public var userName: String
    public var userEnName: String
    public var localName: String
    public var departmentName: String
    public var avatarKey: String
    public var tenantName: String
    public var tenantNameStatus: RustPB.Basic_V1_TenantNameStatus
    public var certificationInfo: RustPB.Basic_V1_CertificationInfo

    public init(userId: String,
                userName: String,
                userEnName: String,
                localName: String,
                departmentName: String,
                avatarKey: String,
                tenantName: String,
                tenantNameStatus: RustPB.Basic_V1_TenantNameStatus,
                certificationInfo: RustPB.Basic_V1_CertificationInfo) {
        self.userId = userId
        self.userName = userName
        self.userEnName = userEnName
        self.localName = localName
        self.departmentName = departmentName
        self.avatarKey = avatarKey
        self.tenantName = tenantName
        self.tenantNameStatus = tenantNameStatus
        self.certificationInfo = certificationInfo
    }

    public static func transform(pb: PBModel) -> ContactSummary {
        return ContactSummary(userId: pb.userID,
                              userName: pb.userName,
                              userEnName: pb.userEnName,
                              localName: pb.userNameI18N,
                              departmentName: pb.departmentName,
                              avatarKey: pb.avatarKey,
                              tenantName: pb.tenantName,
                              tenantNameStatus: pb.tenantNameStatus,
                              certificationInfo: pb.certificationInfo)
    }
}

// ChatApplications
public typealias PushChatApplicationGroup = ChatApplicationGroup
public struct ChatApplicationGroup: PushMessage {
    public var applications: [ChatApplication]
    public var hasMore: Bool

    public init(applications: [ChatApplication], hasMore: Bool) {
        self.applications = applications
        self.hasMore = hasMore
    }
}

public struct ChatApplicationBadege {
    public let chatBadge: Int
    public let friendBadge: Int

    public init(chatBadge: Int, friendBadge: Int) {
        self.chatBadge = chatBadge
        self.friendBadge = friendBadge
    }
}

public protocol ChatApplicationAPI {
    /// 拉取好友申请
    func getChatApplications(cursor: String,
                               count: Int,
                               type: RustPB.Basic_V1_ChatApplication.TypeEnum,
                               getType: GetType,
                               chatId: String) -> Observable<ChatApplicationGroup>

    /// 发送好友申请
    /// - useAction: 是否指定要求返回TnS自定义（品牌互通）提示
    func sendChatApplication(token: String?,
                             chatID: String?,
                             reason: String?,
                             userID: String?,
                             userAlias: String?,
                             source: Source?,
                             useAction: Bool?) -> Observable<RustPB.Im_V1_SendChatApplicationResponse>

    /// 处理好友申请
    func processChatApplication(id: String, result: RustPB.Basic_V1_ChatApplication.Status, authSync: Bool) -> Observable<Void>

    func processChatApplication(userId: String, result: RustPB.Basic_V1_ChatApplication.Status) -> Observable<Void>

    /// 好友申请已读，默认全部已读
    func updateChatApplicationMeRead() -> Observable<Void>

    /// 好友申请badge
    func getChatApplicationBadge() -> Observable<ChatApplicationBadege>

    /// 根据分享人信息获取邀请链接（服务端）
    func fetchInviteLinkInfoFromServer() -> Observable<RustPB.Im_V2_GetContactTokenResponse>

    /// 根据分享人信息获取邀请链接（本地）
    func fetchInviteLinkInfoFromLocal() -> Observable<RustPB.Im_V2_GetContactTokenResponse>

    /// 获取外部联系人邀请引导上下文
    func fetchInviteGuideContext() -> Observable<ServerPB.ServerPB_Flow_TrySetUGEventStateResponse>

    /// 刷新token
    func resetContactToken() -> Observable<String>

    /// 手机号或邮箱搜索
    func searchUser(contactContent: String) -> Observable<[UserProfile]>

    /// 带推荐账户的手机号或邮箱搜索
    func searchUserWithActiveUser(contactContent: String) -> Observable<([UserProfile], String)>

    /// 邀请好友
    func invitationUser(invitationType: RustPB.Contact_V1_SendUserInvitationRequest.TypeEnum, contactContent: String) -> Observable<InvitationResult>

    /// 获取电话号码
    func fetchMobileCode() -> Observable<MobileCodeData>

    /// 获取推广链接
    func getMyPromotionLink() -> Observable<String>

    /// 获取推广规则
    func getPromotionRule() -> Observable<String>

    /// 定向推广好友
    func invitationTenant(invitationType: RustPB.Contact_V1_SetBusinessInvitationRequest.TypeEnum, contactContent: String) -> Observable<TenantInvitationResult>

    /// 获取通讯录联系人列表
    func getAddressBookContactList(timelineMark: Int64?, contactPoints: [String], strategy: SyncDataStrategy) -> Observable<AddressBookContactList>
}

public final class UserProfile: ModelProtocol {
    public typealias PBModel = RustPB.Contact_V1_GetUserProfileResponse

    public typealias Status = RustPB.Basic_V1_Chatter.Description.TypeEnum
    public typealias FieldValue = RustPB.Contact_V1_GetUserProfileResponse.Personal.ProfileValue.FieldValue

    public typealias DepartmentMeta = RustPB.Contact_V1_GetUserProfileResponse.Company.DepartmentMeta

    public struct Leader {
        public let id: String
        public let localizedName: String
        public let profileUrl: URL?
    }

    public struct Company {
        public let departmentName: String
        public let tenantName: String
        public let departments: [DepartmentMeta]
        public let position: String
        public let unit: String
        public let tenantNameStatus: Basic_V1_TenantNameStatus
        public let isTenantCertification: Bool
        public let certificationInfo: Contact_V1_GetUserProfileResponse.Company.CertificationInfo
    }

    public var name: String
    public var enName: String
    public var localizedName: String
    /// 备注名
    public var alias: String
    public var description: String
    public var email: String
    public var gender: String
    public var profileUrl: URL?
    public var city: String
    public var status: Status
    public var employeeId: String
    public var isFriend: Bool
    public var requestUserApply: Bool
    public var targetUserApply: Bool
    public var contactToken: String
    public var contactApplicationId: String
    public var applicationReason: String
    public var userId: String
    public var tenantId: String
    public var avatarKey: String
    public var isResigned: Bool
    public var workStatus: WorkStatus
    public var accessInfo: Chatter.AccessInfo
    public var microappProfileURL: String
    /// 字段排序
    public var profileFieldsOrder: [RustPB.Contact_V1_GetUserProfileResponse.Personal.ProfileField]
    /// 字段内容
    public var customFieldValuesV2: [String: FieldValue]
    /// 性别
    public var genderEnum: RustPB.Contact_V1_GetUserProfileResponse.Personal.ProfileValue.Gender
    /// 勿扰模式截止ntp时间
    public var doNotDisturbEndTime: Int64
    public var adminInfo: RustPB.Contact_V1_GetUserProfileResponse.AdminInfo

    public var leader: Leader
    public var company: Company

    public init(name: String,
                enName: String,
                localizedName: String,
                alias: String,
                description: String,
                email: String,
                gender: String,
                profileUrl: String,
                city: String,
                status: Status,
                employeeId: String,
                isFriend: Bool,
                requestUserApply: Bool,
                targetUserApply: Bool,
                contactToken: String,
                contactApplicationId: String,
                applicationReason: String,
                userId: String,
                tenantId: String,
                avatarKey: String,
                isResigned: Bool,
                leader: Leader,
                company: Company,
                workStatus: WorkStatus,
                accessInfo: Chatter.AccessInfo,
                microappProfileURL: String,
                profileFieldsOrder: [RustPB.Contact_V1_GetUserProfileResponse.Personal.ProfileField],
                customFieldValuesV2: [String: FieldValue],
                genderEnum: RustPB.Contact_V1_GetUserProfileResponse.Personal.ProfileValue.Gender,
                doNotDisturbEndTime: Int64,
                adminInfo: RustPB.Contact_V1_GetUserProfileResponse.AdminInfo) {
        self.name = name
        self.enName = enName
        self.localizedName = localizedName
        self.alias = alias
        self.description = description
        self.email = email
        self.gender = gender
        self.profileUrl = URL(string: profileUrl)
        self.city = city
        self.status = status
        self.employeeId = employeeId
        self.isFriend = isFriend
        self.requestUserApply = requestUserApply
        self.targetUserApply = targetUserApply
        self.contactToken = contactToken
        self.contactApplicationId = contactApplicationId
        self.applicationReason = applicationReason
        self.userId = userId
        self.tenantId = tenantId
        self.avatarKey = avatarKey
        self.isResigned = isResigned
        self.leader = leader
        self.company = company
        self.workStatus = workStatus
        self.accessInfo = accessInfo
        self.microappProfileURL = microappProfileURL
        self.profileFieldsOrder = profileFieldsOrder
        self.customFieldValuesV2 = customFieldValuesV2
        self.genderEnum = genderEnum
        self.doNotDisturbEndTime = doNotDisturbEndTime
        self.adminInfo = adminInfo
    }

    public static func transform(pb: RustPB.Contact_V1_GetUserProfileResponse) -> UserProfile {
        let leader = Leader(id: pb.leader.id,
                            localizedName: pb.leader.localizedName,
                            profileUrl: URL(string: pb.leader.profileURL)
        )

        let company = Company(departmentName: pb.company.departmentName,
                              tenantName: pb.company.tenantName,
                              departments: pb.company.departments.deptMetas,
                              position: pb.company.position.name,
                              unit: pb.company.orgUnit.name,
                              tenantNameStatus: pb.company.tenantNameStatus,
                              isTenantCertification: pb.company.isTenantCertification,
                              certificationInfo: pb.company.certificationInfo
        )

        return UserProfile(
            name: pb.personal.name,
            enName: pb.personal.enName,
            localizedName: pb.personal.localizedName,
            alias: pb.personal.alias,
            description: pb.personal.description_p,
            email: pb.personal.email,
            gender: pb.personal.gender,
            profileUrl: pb.personal.malaitaProfileURL,
            city: pb.personal.city,
            status: pb.personal.descriptionType,
            employeeId: pb.personal.employeeID,
            isFriend: pb.personal.isFriend,
            requestUserApply: pb.personal.requestUserApply,
            targetUserApply: pb.personal.targetUserApply,
            contactToken: pb.personal.contactToken,
            contactApplicationId: pb.personal.contactApplicationID,
            applicationReason: pb.personal.applicationReason,
            userId: pb.personal.userID,
            tenantId: pb.personal.tenantID,
            avatarKey: pb.personal.avatarKey,
            isResigned: pb.personal.isResigned,
            leader: leader,
            company: company,
            workStatus: pb.workStatus,
            accessInfo: pb.accessInfo,
            microappProfileURL: pb.personal.microappProfileURL,
            profileFieldsOrder: pb.personal.profileValue.profileFieldsOrder,
            customFieldValuesV2: pb.personal.profileValue.customFieldValuesV2,
            genderEnum: pb.personal.profileValue.genderEnum,
            doNotDisturbEndTime: pb.doNotDisturbEndTime,
            adminInfo: pb.adminInfo)
    }
}

public struct InvitationResult {
    public var success: Bool
    public var user: UserProfile?

    public init(success: Bool, user: UserProfile?) {
        self.success = success
        self.user = user
    }
}

public struct TenantInvitationResult {
    public var success: Bool
    public var url: String

    public init(success: Bool, url: String) {
        self.success = success
        self.url = url
    }
}
