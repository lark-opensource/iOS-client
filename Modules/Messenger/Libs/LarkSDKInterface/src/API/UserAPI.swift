//
//  UserAPI.swift
//  Lark
//
//  Created by zc09v on 2017/9/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import RustPB
import ServerPB
import LarkRustClient

public protocol UserAPI {

    func getSubordinateDepartments() -> Observable<([RustPB.Basic_V1_Department], Int32?, Bool)>

    func getUserProfileInfomation(userId: String) -> Observable<UserProfile>

    func isAdministrator() -> Observable<Bool>

    func isSuperAdministrator() -> Observable<Bool>

    func isSuperOrDepartmentAdministrator() -> Observable<Bool>

    func pullOncalls(offset: Int32, count: Int32) -> Observable<(oncalls: [Oncall], hasMore: Bool)>

    func pullOncallsByTag(tagIds: [String], offset: Int32, count: Int32) -> Observable<(oncalls: [Oncall], hasMore: Bool)>

    func pullOncallTags() -> Observable<[OnCallTag]>

    func pullBots(offset: Int32, count: Int32) -> Observable<(bots: [LarkModel.Chatter], hasMore: Bool)>

    func fetchDepartmentStructure(departmentId: String,
                                  offset: Int,
                                  count: Int,
                                  extendParam: RustPB.Contact_V1_ExtendParam) -> Observable<DepartmentWithExtendFields>

    func getAnotherNameFormat() -> Observable<Contact_V1_GetAnotherNameFormatResponse.FormatRule>

    func fetchCollaborationDepartmentStructure(
                     tenantId: String,
                     departmentId: String,
                     offset: Int,
                     count: Int,
                     extendParam: RustPB.Contact_V1_CollaborationExtendParam) -> Observable<CollaborationDepartmentWithExtendFields>

    func fetchCollaborationTenant(offset: Int, count: Int, isInternal: Bool?, query: String?) -> Observable<CollaborationTenantModel>

    func fetchUserProfileInfomation(userId: String) -> Observable<UserProfile>

    func fetchUserMoiblePhonenumber(userId: String) -> Observable<(mobilePhoneNumber: String, hasPermission: Bool)>

    func getMyGroup(type: MyGroupType, nextCursor: Int, count: Int, strategy: SyncDataStrategy) -> Observable<FetchMyGroupResult>

    func fetchMyGroup(type: MyGroupType, nextCursor: Int, count: Int) -> Observable<FetchMyGroupResult>

    func fetchUserSecurityConfig() -> Observable<RustPB.Settings_V1_GetUserSecurityConfigResponse>

    func pullUserTypingTranslateSettings() -> Observable<RustPB.Contact_V1_PullUserTypingTranslateSettingsResponse>
}

public typealias SyncDataStrategy = RustPB.Basic_V1_SyncDataStrategy
public typealias ContactUserInfo = RustPB.Basic_V1_ContactInfo
public typealias ContactPointUserInfo = RustPB.Contact_V2_ContactPointUserInfo
public typealias UserContactStatus = RustPB.Contact_V2_UserContactStatus
public typealias RecentVisitTargetsResponse = RustPB.Feed_V1_GetRecentVisitTargetsResponse

public protocol RecentForwardFilterParameterType {
    var includeGroupChat: Bool { get set }
    var includeP2PChat: Bool { get set }
    var includeThreadChat: Bool { get set }
    var includeOuterChat: Bool { get set }
    var includeSelf: Bool { get set }
}

public protocol ContactAPI {

    func uploadContactPoints(contactPoints: [String], timelineMark: Int64?,
                             successCallBack: @escaping ((_ newTimelineMark: Double) -> Void),
                             failedCallBack: @escaping (Error) -> Void)

    func getUserInfoByContactPointsRequest(contactPoints: [String]) -> Observable<[ContactPointUserInfo]>

    func fetchExternalContactListRequest(strategy: RustPB.Basic_V1_SyncDataStrategy?,
                              offset: Int?,
                              limitCount: Int?) -> Observable<[ContactInfo]>

    // 批量拉群联系人权限
    func fetchAuthChattersRequest(actionType: RustPB.Basic_V1_Auth_ActionType,
                                  isFromServer: Bool,
                                  chattersAuthInfo: [String: String]) -> Observable<FetchAuthChattersResponse>

    func getAuthChattersRequestFromLocal(actionType: RustPB.Basic_V1_Auth_ActionType,
                                         chattersAuthInfo: [String: String]) -> Observable<FetchAuthChattersResponse>

    func fetchAuthChattersWithLocalAndServer(actionType: RustPB.Basic_V1_Auth_ActionType,
                                             chattersAuthInfo: [String: String]) -> Observable<FetchAuthChattersResponse>

    // 可能想要at的人
    func getWantToMentionChatters(topCount: Int32) -> Observable<RustPB.Contact_V1_GetWantToMentionChattersResponse>
    // 获取最近访问列表本地数据
    func getForwardList() -> Observable<RustPB.Feed_V1_GetForwardListResponse>
    // 获取最近访问多端同步数据
    func getRemoteSyncForwardList(includeConfigs: [Feed_V1_GetRecentVisitTargetsRequest.IncludeItem], strategy: SyncDataStrategy, limit: Int32) -> Observable<RecentVisitTargetsResponse>
    // 获取邀请入口开关
    func getInvitationAccessInfo() -> Observable<RustPB.Contact_V1_GetInvitationAccessInfoResponse>
}

public typealias OnCallTag = RustPB.Helpdesk_V1_OncallTag

public typealias Coordinate = RustPB.Basic_V1_Coordinate

public typealias AdditionalData = RustPB.Helpdesk_V1_CreateOncallChatRequest.AdditionalData

public final class Oncall: ModelProtocol {
    public typealias PBModel = RustPB.Basic_V1_Oncall

    public var id: String
    public var name: String
    public var description: String
    public var avatar: ImageSet
    public var chatId: String
    public var phoneNumber: String
    public var reportLocation: Bool

    public var chat: Chat?

    public init(id: String,
                name: String,
                description: String,
                avatar: ImageSet,
                chatId: String,
                phoneNumber: String,
                reportLocation: Bool) {
        self.id = id
        self.name = name
        self.description = description
        self.avatar = avatar
        self.chatId = chatId
        self.phoneNumber = phoneNumber
        self.reportLocation = reportLocation
    }

    public static func transform(pb: PBModel) -> Oncall {
        return Oncall(
            id: pb.id,
            name: pb.name,
            description: pb.description_p,
            avatar: pb.avatar,
            chatId: pb.chatID,
            phoneNumber: pb.phoneNumber,
            reportLocation: pb.reportLocation)
    }
}

public typealias LeaderType = Contact_V1_LeaderType
public final class DepartmentLeader: ModelProtocol {
    public typealias PBModel = RustPB.Contact_V1_DepartmentLeader

    public var leaderType: LeaderType
    public var leader: Chatter

    public init(leaderType: LeaderType,
                leader: Chatter) {
        self.leaderType = leaderType
        self.leader = leader
    }

    public static func transform(pb: PBModel) -> DepartmentLeader {
        return DepartmentLeader(
            leaderType: pb.leaderType,
            leader: Chatter.transform(pb: pb.leader)
        )
    }

    public static func make(pb: PBModel, auths: Basic_V1_Auth_ChattersAuthResult? = nil) -> DepartmentLeader {
        return DepartmentLeader(
            leaderType: pb.leaderType,
            leader: Chatter.make(pb: pb.leader, auths: auths)
        )
    }

    public func transformJSONString() throws -> String {
        return ""
    }
}

public final class DepartmentStructure: ModelProtocol {
    public typealias PBModel = RustPB.Contact_V1_DepartmentStructure

    public var leader: Chatter
    public var deptLeaders: [DepartmentLeader]
    public var department: RustPB.Basic_V1_Department
    public var subDepartments: [RustPB.Basic_V1_Department]
    public var chatters: [Chatter]
    public var hasMore: Bool
    public var chatInfo: RustPB.Contact_V1_ChatInfo
    public var superAdministrator: Set<String>
    public var administrator: Set<String>
    public var hasMoreDepartment: Bool

    public init(leader: Chatter,
                deptLeaders: [DepartmentLeader],
                department: RustPB.Basic_V1_Department,
                subDepartments: [RustPB.Basic_V1_Department],
                chatters: [Chatter],
                hasMore: Bool,
                chatInfo: RustPB.Contact_V1_ChatInfo,
                superAdministrator: Set<String>,
                administrator: Set<String>,
                hasMoreDepartment: Bool) {
        self.leader = leader
        self.deptLeaders = deptLeaders
        self.department = department
        self.subDepartments = subDepartments
        self.chatters = chatters
        self.hasMore = hasMore
        self.chatInfo = chatInfo
        self.superAdministrator = superAdministrator
        self.administrator = administrator
        self.hasMoreDepartment = hasMoreDepartment
    }

    public static func transform(pb: Contact_V1_DepartmentStructure) -> DepartmentStructure {
        return make(pb: pb, auths: nil)
    }

    public static func make(pb: PBModel, auths: Basic_V1_Auth_ChattersAuthResult? = nil) -> DepartmentStructure {
        return DepartmentStructure(
            leader: Chatter.make(pb: pb.leader, auths: auths),
            deptLeaders: pb.deptLeaders.map { DepartmentLeader.make(pb: $0, auths: auths) },
            department: pb.department,
            subDepartments: pb.subDepartments,
            chatters: pb.chatters.map({ Chatter.make(pb: $0, auths: auths) }),
            hasMore: pb.hasMore_p,
            chatInfo: pb.chatInfo,
            superAdministrator: Set(pb.superAdministrator),
            administrator: Set(pb.administrator),
            hasMoreDepartment: pb.hasMoreDepartment_p
        )
    }

    public func transformJSONString() throws -> String {
        return ""
    }
}

public enum ContactDisplayModule: Int32 {
    case unknown = 0
    case leader = 1
    case department = 2
    case user = 3
}

public struct DepartmentWithExtendFields {
    public let departmentStructure: DepartmentStructure
    public let extendFields: Contact_V1_ExtendFields
    public let isShowMemberCount: Bool
    public let displayOrder: [ContactDisplayModule]
    public let parentDepartments: [Basic_V1_Department]
    public let isShowDepartmentPrimaryMemberCount: Bool

    public init(
        departmentStructure: DepartmentStructure,
        extendFields: Contact_V1_ExtendFields,
        isShowMemberCount: Bool = true,
        displayOrder: [ContactDisplayModule] = [],
        parentDepartments: [Basic_V1_Department] = [],
        isShowDepartmentPrimaryMemberCount: Bool = false
    ) {
        self.departmentStructure = departmentStructure
        self.extendFields = extendFields
        self.isShowMemberCount = isShowMemberCount
        self.displayOrder = displayOrder
        self.parentDepartments = parentDepartments
        self.isShowDepartmentPrimaryMemberCount = isShowDepartmentPrimaryMemberCount
    }
}

public final class CollaborationDepartmentStructure: ModelProtocol {
    public typealias PBModel = RustPB.Contact_V1_CollaborationDepartmentStructure

    public var department: RustPB.Basic_V1_Department
    public var subDepartments: [RustPB.Basic_V1_Department]
    public var chatters: [Chatter]
    public var hasMore: Bool
    public var hasMoreDepartment: Bool

    public init(department: RustPB.Basic_V1_Department,
                subDepartments: [RustPB.Basic_V1_Department],
                chatters: [Chatter],
                hasMore: Bool,
                hasMoreDepartment: Bool) {
        self.department = department
        self.subDepartments = subDepartments
        self.chatters = chatters
        self.hasMore = hasMore
        self.hasMoreDepartment = hasMoreDepartment
    }

    public static func transform(pb: PBModel) -> CollaborationDepartmentStructure {
        return make(pb: pb, auths: nil)
    }

    public static func make(pb: PBModel, auths: Basic_V1_Auth_ChattersAuthResult? = nil) -> CollaborationDepartmentStructure {
        return CollaborationDepartmentStructure(
            department: pb.department,
            subDepartments: pb.subDepartments,
            chatters: pb.chatters.map({ Chatter.make(pb: $0, auths: auths) }),
            hasMore: pb.hasMore_p,
            hasMoreDepartment: pb.hasMoreDepartment_p
        )
    }

    public func transformJSONString() throws -> String {
        return ""
    }
}

public struct CollaborationDepartmentWithExtendFields {
    public let departmentStructure: CollaborationDepartmentStructure
    public let extendFields: Contact_V1_CollaborationExtendFields
    public let isShowMemberCount: Bool
    public let parentDepartments: [Basic_V1_Department]
    public let tenant: Contact_V1_CollaborationTenant?

    public init(
        departmentStructure: CollaborationDepartmentStructure,
        extendFields: Contact_V1_CollaborationExtendFields,
        isShowMemberCount: Bool = true,
        parentDepartments: [Basic_V1_Department] = [],
        tenant: Contact_V1_CollaborationTenant? = nil
    ) {
        self.departmentStructure = departmentStructure
        self.extendFields = extendFields
        self.isShowMemberCount = isShowMemberCount
        self.parentDepartments = parentDepartments
        self.tenant = tenant
    }
}

final public class CollaborationTenantModel: LarkModel.ModelProtocol {
    public typealias PBModel = RustPB.Contact_V1_GetCollaborationTenantResponse
    public var tenants: [RustPB.Contact_V1_CollaborationTenant]
    public var hasMore: Bool

    public init(tenants: [RustPB.Contact_V1_CollaborationTenant], hasMore: Bool) {
        self.tenants = tenants
        self.hasMore = hasMore
    }

    public static func transform(pb: LarkSDKInterface.CollaborationTenantModel.PBModel) -> LarkSDKInterface.CollaborationTenantModel {
        return CollaborationTenantModel(
            tenants: pb.tenants,
            hasMore: pb.hasMore_p
        )
    }

    public func transformJSONString() throws -> String {
        return ""
    }
}
