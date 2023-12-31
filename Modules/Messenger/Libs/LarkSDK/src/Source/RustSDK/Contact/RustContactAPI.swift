//
//  RustUserAPI.swift
//  Lark
//
//  Created by Sylar on 2017/11/3.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import RxSwift
import LKCommonsLogging
import LarkModel
import LarkSDKInterface
import ServerPB
import LarkSetting
import LarkMessengerInterface

final class RustUserAPI: LarkAPI, UserAPI, ContactAPI {

    let disposeBag = DisposeBag()
    let featureGatingService: FeatureGatingService

    static let logger = Logger.log(RustUserAPI.self, category: "RustSDK.User")
    static var log = RustUserAPI.logger

    init(client: SDKRustService,
         featureGatingService: FeatureGatingService,
         onScheduler: ImmediateSchedulerType? = nil) {
        self.featureGatingService = featureGatingService
        super.init(client: client, onScheduler: onScheduler)
    }

    // MARK: - Get UserModel with UserId

    func getSubordinateDepartments() -> Observable<([RustPB.Basic_V1_Department], Int32?, Bool)> {
        let loadFromLocal = self.loadSubordinateDepartments()
        let fetchFromServer = self.fetchSubordinateDepartments()
        return Observable.concat([loadFromLocal, fetchFromServer]).subscribeOn(MainScheduler.instance)
    }

    // MARK: - SubStructure
    func fetchDepartmentStructure(departmentId: String,
                                  offset: Int,
                                  count: Int,
                                  extendParam: RustPB.Contact_V1_ExtendParam) -> Observable<DepartmentWithExtendFields> {
        var request = RustPB.Contact_V1_GetDepartmentCombineChatRequest()
        request.departmentID = departmentId
        request.count = Int32(count)
        request.offset = Int32(offset)
        request.needPath = true
        request.subDepartmentPaging = true
        request.extendParam = extendParam
        request.useDisplayOrder = true
        return self.client.sendAsyncRequest(
            request,
            transform: { (response: GetDepartmentCombineChatResponse) -> DepartmentWithExtendFields in
                let departmentStructure = DepartmentStructure.make(pb: response.departmentStructure, auths: response.extendFields.authResult)
                return DepartmentWithExtendFields(
                    departmentStructure: departmentStructure,
                    extendFields: response.extendFields,
                    isShowMemberCount: response.isShowMemberCount,
                    displayOrder: response.displayOrder.map({
                        ContactDisplayModule(rawValue: $0) ?? .unknown
                    }),
                    parentDepartments: response.parentDepartments,
                    isShowDepartmentPrimaryMemberCount: response.isShowDepartmentPrimaryMemberCount
                )
            })
    }

    func getAnotherNameFormat() -> Observable<Contact_V1_GetAnotherNameFormatResponse.FormatRule> {
        let request = Contact_V1_GetAnotherNameFormatRequest()
        return self.client.sendAsyncRequest(request) { (response: Contact_V1_GetAnotherNameFormatResponse) -> Contact_V1_GetAnotherNameFormatResponse.FormatRule in
            return response.rule
        }
    }

    // MARK: - collaboration
      func fetchCollaborationDepartmentStructure(
                     tenantId: String,
                     departmentId: String,
                     offset: Int,
                     count: Int,
                     extendParam: RustPB.Contact_V1_CollaborationExtendParam) -> Observable<CollaborationDepartmentWithExtendFields> {
        var request = RustPB.Contact_V1_GetCollaborationStructureRequest()
        request.tenantID = tenantId
        request.departmentID = departmentId
        request.count = Int32(count)
        request.offset = Int32(offset)
        request.needPath = true
        request.extendParam = extendParam
        return self.client.sendAsyncRequest(
          request,
          transform: { (response: Contact_V1_GetCollaborationStructureResponse) -> CollaborationDepartmentWithExtendFields in
              let departmentStructure = CollaborationDepartmentStructure.make(pb: response.departmentStructure, auths: response.extendFields.authResult)
            return CollaborationDepartmentWithExtendFields(
              departmentStructure: departmentStructure,
              extendFields: response.extendFields,
              isShowMemberCount: response.showDepartmentCount,
              parentDepartments: response.departmentStructure.parentDepartments,
              tenant: response.tenant
            )
          })
      }

    func fetchCollaborationTenant(offset: Int, count: Int, isInternal: Bool?, query: String?) -> Observable<CollaborationTenantModel> {
        var request = RustPB.Contact_V1_GetCollaborationTenantRequest()
        request.count = Int32(count)
        request.offset = Int32(offset)
        // 外部internal=1,external=0，接口侧internal=1,external=2
        let enableInternalAssociationInvite = featureGatingService.staticFeatureGatingValue(with: "lark.admin.orm.b2b.high_trust_parties")
        if let isInternal = isInternal, enableInternalAssociationInvite {
            let showConnectType: Contact_V1_ShowConnectType
            if isInternal {
                showConnectType = .showInternalConnectType
            } else {
                showConnectType = .showExternalConnectType
            }
            request.showConnectType = showConnectType
        } else {
            request.showConnectType = .showAllConnectType
        }

        if let query = query {
            request.query = query
        }
        return self.client.sendAsyncRequest(
          request,
          transform: { (response: Contact_V1_GetCollaborationTenantResponse) -> CollaborationTenantModel in
            let result = CollaborationTenantModel.transform(pb: response)
            return result
          })
      }

    // MARK: - User

    func loadSubordinateDepartments() -> Observable<([RustPB.Basic_V1_Department], Int32?, Bool)> {
        let request = RustPB.Contact_V1_GetSubordinateDepartmentsRequest()
        return self.client.sendAsyncRequest(
            request,
            transform: { (response: GetSubordinateDepartmentsRequestResponse) -> ([RustPB.Basic_V1_Department], Int32?, Bool) in
                if response.isShowMemberCount {
                    return (response.departments, response.memberCount, true)
                }
                return (response.departments, nil, false)
            })
    }

    func fetchSubordinateDepartments() -> Observable<([RustPB.Basic_V1_Department], Int32?, Bool)> {
        let request = RustPB.Contact_V1_GetSubordinateDepartmentsRequest()
        return self.client.sendAsyncRequest(
            request,
            transform: { (response: GetSubordinateDepartmentsRequestResponse) -> ([RustPB.Basic_V1_Department], Int32?, Bool) in
                if response.isShowMemberCount {
                    return (response.departments, response.memberCount, true)
                }
                return (response.departments, nil, false)
            })
    }

    // MARK: - Oncall

    func pullOncalls(offset: Int32, count: Int32) -> Observable<(oncalls: [Oncall], hasMore: Bool)> {
        var request = GetOncallsRequest()
        request.offset = offset
        request.count = count
        return client.sendAsyncRequest(
            request,
            transform: { (response: GetOncallsResponse) -> (oncalls: [Oncall], hasMore: Bool) in
                let oncalls = response.oncalls.map({ (oncall) -> Oncall in
                    Oncall(
                        id: oncall.id,
                        name: oncall.name,
                        description: oncall.description_p,
                        avatar: oncall.avatar,
                        chatId: oncall.chatID,
                        phoneNumber: oncall.phoneNumber,
                        reportLocation: oncall.reportLocation)
                })
                return (oncalls, response.hasMore_p)
            })
    }

    func pullOncallsByTag(tagIds: [String], offset: Int32, count: Int32) -> Observable<(oncalls: [Oncall], hasMore: Bool)> {
        var request = PullOncallByTagsRequest()
        request.tagIds = tagIds
        request.offset = offset
        request.count = count
        return client.sendAsyncRequest(
            request,
            transform: { (response: PullOncallByTagsResponse) -> (oncalls: [Oncall], hasMore: Bool) in
                return (response.oncalls.map({ (oncall) -> Oncall in
                    return Oncall.transform(pb: oncall)
                }), response.hasMore_p)
            })
    }

    func pullOncallTags() -> Observable<[OnCallTag]> {
        let request = PullAllOncallTagsRequest()
        return client.sendAsyncRequest(request, transform: { (response: PullAllOncallTagsResponse) -> [OnCallTag] in
            return response.tags
        })
    }

    // MARK: - Robot

    func pullBots(offset: Int32, count: Int32) -> Observable<(bots: [LarkModel.Chatter], hasMore: Bool)> {
        var request = RustPB.Contact_V1_GetBotsRequest()
        request.offset = offset
        request.count = count

        return self.client.sendAsyncRequest(
            request,
            transform: {  (response: GetBotsResponse) -> (bots: [LarkModel.Chatter], hasMore: Bool) in
                let bots = response.bots.map({ (chatter) -> LarkModel.Chatter in
                    LarkModel.Chatter.transform(pb: chatter)
                })
                return (bots, response.hasMore_p)
            })
    }

    // MARK: - CellPhone Number

    func fetchUserMoiblePhonenumber(userId: String) -> Observable<(mobilePhoneNumber: String, hasPermission: Bool)> {
        var request = RustPB.Contact_V1_GetChatterMobileRequest()
        request.chatterID = userId
        return self.client.sendAsyncRequest(
            request,
            transform: { (response: GetChatterMobileResponse) -> (mobilePhoneNumber: String, hasPermission: Bool) in
                (response.mobile, !response.noPermission)
            })
    }

    func fetchUserProfileInfomation(userId: String) -> Observable<UserProfile> {
        var request = RustPB.Contact_V1_GetUserProfileRequest()
        request.userID = userId
        return self.client.sendAsyncRequest(
            request,
            transform: { (response: GetUserProfileResponse) -> UserProfile in
                UserProfile.transform(pb: response)
            })
    }

    func isAdministrator() -> Observable<Bool> {
        let request = ServerPB.ServerPB_Role_GetAdminPermissionInfoRequest()
        return self.client.sendPassThroughAsyncRequest(request,
                                                       serCommand: .getAdminPermissionInfo,
                                                       transform: { (response: ServerPB.ServerPB_Role_GetAdminPermissionInfoResponse) -> Bool in
                                                        return response.isAdministrator
                                                       })
    }

    func isSuperAdministrator() -> Observable<Bool> {
        let request = ServerPB.ServerPB_Role_GetAdminPermissionInfoRequest()
        return self.client.sendPassThroughAsyncRequest(request,
                                                       serCommand: .getAdminPermissionInfo,
                                                       transform: { (response: ServerPB.ServerPB_Role_GetAdminPermissionInfoResponse) -> Bool in
                                                        return response.isSuperAdministrator
                                                       })
    }

    /**
     服务端逻辑(v4.1.0)
     isSuperAdministrator=true时，成员与部门管理权限一定为false
     但是超级管理员一定有成员与部门管理权限，所以这里二者取或
     */
    func isSuperOrDepartmentAdministrator() -> Observable<Bool> {
        let request = ServerPB.ServerPB_Role_GetAdminPermissionInfoRequest()
        return self.client.sendPassThroughAsyncRequest(request,
                                                       serCommand: .getAdminPermissionInfo,
                                                       transform: { (response: ServerPB.ServerPB_Role_GetAdminPermissionInfoResponse) -> Bool in
                                                        return (response.isSuperAdministrator || response.isDepartmentAdministrator)
                                                       })
    }

    //同步接口
    func getUserProfileInfomation(userId: String) -> Observable<UserProfile> {
        var request = RustPB.Contact_V1_GetUserProfileRequest()
        request.userID = userId
        return self.client.sendSyncRequest(
            request,
            transform: { (response: GetUserProfileResponse) -> UserProfile in
                UserProfile.transform(pb: response)
            }
        )
    }

    // 批量拉群联系人权限
    func fetchAuthChattersRequest(actionType: RustPB.Basic_V1_Auth_ActionType,
                                  isFromServer: Bool = true,
                                  chattersAuthInfo: [String: String]) -> Observable<FetchAuthChattersResponse> {
        var request = FetchAuthChattersRequest()
        request.actionType = actionType
        request.chattersAuthInfo = chattersAuthInfo
        request.syncDataStrategy = isFromServer ? .forceServer : .tryLocal

        return self.client.sendAsyncRequest(request)
    }

    func getAuthChattersRequestFromLocal(actionType: RustPB.Basic_V1_Auth_ActionType,
                                         chattersAuthInfo: [String: String]) -> Observable<FetchAuthChattersResponse> {
        var request = FetchAuthChattersRequest()
        request.actionType = actionType
        request.chattersAuthInfo = chattersAuthInfo
        request.syncDataStrategy = .local
        return self.client.sendAsyncRequest(request)
    }

    func fetchAuthChattersWithLocalAndServer(actionType: RustPB.Basic_V1_Auth_ActionType,
                                             chattersAuthInfo: [String: String]) -> Observable<FetchAuthChattersResponse> {
        struct D: MergeDep {
            func isEmpty(response: FetchAuthChattersResponse) -> Bool {
                !response.hasAuthResult
            }
        }
        let localObservable = fetchAuthChattersRequest(actionType: actionType, isFromServer: false, chattersAuthInfo: chattersAuthInfo)
        let remoteObservable = fetchAuthChattersRequest(actionType: actionType, isFromServer: true, chattersAuthInfo: chattersAuthInfo)
        return mergedObservable(local: localObservable, remote: remoteObservable, delegate: D(), featureGatingService: featureGatingService).map({ $0.0 })
    }

    // MARK: - Group
    func getMyGroup(type: MyGroupType, nextCursor: Int, count: Int, strategy: SyncDataStrategy) -> Observable<FetchMyGroupResult> {
        var request = RustPB.Im_V1_GetMyGroupChatsRequest()
        request.type = RustPB.Im_V1_GetMyGroupChatsRequest.TypeEnum(rawValue: type.rawValue) ?? .manage
        request.time = Int64(nextCursor)
        request.count = Int32(count)
        request.strategy = strategy

        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_GetMyGroupChatsResponse) -> FetchMyGroupResult in
            let chats = res.chats.map { (chat) -> LarkModel.Chat in
                LarkModel.Chat.transform(pb: chat)
            }
            return FetchMyGroupResult(chats: chats, nextCursor: Int(res.minTime), hasMore: res.hasMore_p)
        }
    }

    func fetchMyGroup(type: MyGroupType, nextCursor: Int, count: Int) -> Observable<FetchMyGroupResult> {
        var request = RustPB.Im_V1_GetMyGroupChatsRequest()
        request.type = RustPB.Im_V1_GetMyGroupChatsRequest.TypeEnum(rawValue: type.rawValue) ?? .manage
        request.time = Int64(nextCursor)
        request.count = Int32(count)

        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_GetMyGroupChatsResponse) -> FetchMyGroupResult in
            let chats = res.chats.map { (chat) -> LarkModel.Chat in
                LarkModel.Chat.transform(pb: chat)
            }
            return FetchMyGroupResult(chats: chats, nextCursor: Int(res.minTime), hasMore: res.hasMore_p)
        }
    }

    func fetchUserSecurityConfig() -> Observable<RustPB.Settings_V1_GetUserSecurityConfigResponse> {
        let request = RustPB.Settings_V1_GetUserSecurityConfigRequest()
        return client.sendAsyncRequest(request, transform: { (res: RustPB.Settings_V1_GetUserSecurityConfigResponse) -> RustPB.Settings_V1_GetUserSecurityConfigResponse in
            return res
        })
    }

    func pullUserTypingTranslateSettings() -> Observable<RustPB.Contact_V1_PullUserTypingTranslateSettingsResponse> {
        let request = RustPB.Contact_V1_PullUserTypingTranslateSettingsRequest()
        return client.sendAsyncRequest(request)
    }

    // MARK: - Contacts 联系人

    /// 上传通讯录CP
    func uploadContactPoints(contactPoints: [String], timelineMark: Int64?,
                             successCallBack: @escaping ((_ newTimelineMark: Double) -> Void),
                             failedCallBack: @escaping (Error) -> Void) {
        var request = RustPB.Contact_V2_UploadContactPointsRequest()
        request.contactPoints = contactPoints
        if let timelineMark = timelineMark {
            request.timelineMark = timelineMark
            RustUserAPI.logger.debug("SDK uploadContactPoints timelineMark = \(timelineMark)")
        }
        RustUserAPI.logger.debug("SDK uploadContactPoints contactPoints count = \(contactPoints.count)")
        client
            .sendAsyncRequest(request,
                              transform: { (res: RustPB.Contact_V2_UploadContactPointsResponse) -> Double in
                                return Double(res.newTimelineMark)
            })
            .subscribe(onNext: { newTimelineMark in
                successCallBack(newTimelineMark)
                RustUserAPI.logger.debug("[NewContactBadge] SDK uploadContactPoints success newTimelineMark = \(newTimelineMark)")
            }, onError: { error in
                failedCallBack(error)
                RustUserAPI.logger.error("[NewContactBadge] SDK uploadContactPoints", error: error)
            }).disposed(by: self.disposeBag)
    }

    /// 获取推荐联系人列表
    /// 飞书品牌下，仅获取推荐人列表，user_infos 只会存在一个元素；
    /// Lark 品牌下，会自动添加推荐人列表中的 user，返回 cp_user_infos 为空
    func getUserInfoByContactPointsRequest(contactPoints: [String]) -> Observable<[ContactPointUserInfo]> {
        var request = RustPB.Contact_V2_MGetUserInfoByCpsRequest()
        request.contactPoints = contactPoints
        RustUserAPI.logger.debug("getUserInfoByContactPointsRequest contactPoints count = \(contactPoints.count)")
        return client.sendAsyncRequest(
            request,
            transform: { (res: RustPB.Contact_V2_MGetUserInfoByCpsResponse) -> [ContactPointUserInfo] in
                return res.cpUserInfos
            })
    }

    /// 获取外部联系人列表
    /// @params strategy: 数据拉取策略，支持 local 和 forceServer
    /// @params offset: 从哪个偏移位置开始拉取, 默认从 0 开始拉
    /// @params limitCount: 一次取多少条数据
    func fetchExternalContactListRequest(strategy: RustPB.Basic_V1_SyncDataStrategy? = .forceServer,
                              offset: Int? = nil,
                              limitCount: Int? = nil) -> Observable<[ContactInfo]> {
        var request = RustPB.Contact_V2_GetExternalContactListRequest()
        if let strategy = strategy {
            request.strategy = strategy
        }
        if let offset = offset {
            request.offset = Int64(offset)
        }
        if let limitCount = limitCount {
            request.limit = Int64(limitCount)
        }
        return client.sendAsyncRequest(
            request,
            transform: { (res: RustPB.Contact_V2_GetExternalContactListResponse) -> [ContactInfo] in
                return res.contacts.map { contactInfoPB -> ContactInfo in
                    return ContactInfo.transform(contactInfoPB: contactInfoPB)
                }
            })
    }

    // 可能想要at的人
    func getWantToMentionChatters(topCount: Int32 = 30) -> Observable<RustPB.Contact_V1_GetWantToMentionChattersResponse> {
        var request = RustPB.Contact_V1_GetWantToMentionChattersRequest()
        request.topCount = topCount

        return self.client.sendAsyncRequest(request)
    }
    func getForwardList() -> Observable<RustPB.Feed_V1_GetForwardListResponse> {
        let request = RustPB.Feed_V1_GetForwardListRequest()
        return self.client.sendAsyncRequest(request)
    }

    func getRemoteSyncForwardList(includeConfigs: [Feed_V1_GetRecentVisitTargetsRequest.IncludeItem], strategy: SyncDataStrategy, limit: Int32) -> Observable<RecentVisitTargetsResponse> {
        var request = RustPB.Feed_V1_GetRecentVisitTargetsRequest()
        request.includeItems = includeConfigs
        request.syncDataStrategy = strategy
        request.limit = limit
        return self.client.sendAsyncRequest(request)
    }

    func getInvitationAccessInfo() -> Observable<RustPB.Contact_V1_GetInvitationAccessInfoResponse> {
        let request = RustPB.Contact_V1_GetInvitationAccessInfoRequest()
        return self.client.sendAsyncRequest(request)
    }
}
