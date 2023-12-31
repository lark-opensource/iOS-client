//
//  RustUserAPI.swift
//  Lark
//
//  Created by Sylar on 2017/11/3.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import RxCocoa
import RxSwift
import LarkModel
import LarkFoundation
import LarkSDKInterface
import LKCommonsLogging
import LarkExtensions
import LarkRustClient
import LarkFeatureGating
import ServerPB
import LarkContainer
import LarkSetting

final class RustChatterSettingAPI: LarkAPI, ChatterSettingAPI {
    func fetchRemoteSetting(strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<(Bool, Bool, Bool)> {
        return RustChatterModule.fetchRemoteSetting(client: self.client, strategy: strategy).subscribeOn(scheduler)
    }

    func updateRemoteSetting(showNotifyDetail: Bool) -> Observable<Void> {
        return RustChatterModule.setClient(showNoticeDetail: showNotifyDetail, client: self.client).subscribeOn(scheduler)
    }

    func updateRemoteSetting(showPhoneAlert: Bool) -> Observable<Void> {
        return RustChatterModule.setClient(showPhoneAlert: showPhoneAlert, client: self.client).subscribeOn(scheduler)
    }

    func updateNotificationStatus(notifyDisable: Bool) -> Observable<Bool> {
        return RustChatterModule.updateNotificationStatus(notifyDisable: notifyDisable, client: self.client).subscribeOn(scheduler)
    }

    func updateNotificationStatus(notifyAtEnabled: Bool) -> Observable<Bool> {
        return RustChatterModule.updateNotificationStatus(notifyAtEnabled: notifyAtEnabled, client: self.client).subscribeOn(scheduler)
    }

    func updateNotificationStatus(notifySpecialFocus: Bool) -> Observable<Bool> {
        return RustChatterModule.updateNotificationStatus(notifySpecialFocus: notifySpecialFocus, client: self.client).subscribeOn(scheduler)
    }

    func updateNotificationStatus(items: [Basic_V1_NotificationSoundSetting.NotificationSoundSettingItem]) -> Observable<Bool> {
        return RustChatterModule.updateNotificationStatus(items: items,
                                                          client: self.client).subscribeOn(scheduler)
    }
}

final class RustChatterAPI: LarkAPI, ChatterAPI {

    static let logger = Logger.log(RustChatterAPI.self, category: "RustSDK.User")
    static var log = RustChatterAPI.logger
    let pushCenter: PushNotificationCenter
    let featureGatingService: FeatureGatingService

    init(client: SDKRustService, pushCenter: PushNotificationCenter, featureGatingService: FeatureGatingService, onScheduler: ImmediateSchedulerType? = nil) {
        self.pushCenter = pushCenter
        self.featureGatingService = featureGatingService
        super.init(client: client, onScheduler: onScheduler)
    }

    // MARK: - Get Chatter(s) with chatterId or chatId
    func getChatterFromLocal(id: String) -> LarkModel.Chatter? {
        var chatter: LarkModel.Chatter?
        do {
            chatter = try self.getChattersFromLocal(ids: [id]).first?.value
        } catch {
            RustChatterAPI.logger.error("获取用户数据异常", additionalData: ["chatterId": id], error: error)
        }
        return chatter
    }

    func getChatChatterFromLocal(id: String, chatId: String) -> LarkModel.Chatter? {
        var chatter: LarkModel.Chatter?
        do {
            chatter = try self.getChatChattersFromLocal(ids: [id], chatId: chatId).first?.value
        } catch {
            RustChatterAPI.logger.error("获取用户数据异常", additionalData: ["chatterId": id], error: error)
        }
        return chatter
    }

    func getChatChattersFromLocal(ids: [String], chatId: String)  throws -> [String: LarkModel.Chatter] {
        var request = RustPB.Im_V1_GetChatChattersByIdsRequest()
        request.chatterIds = ids
        request.chatID = chatId
        let response: ContextResponse<RustPB.Im_V1_GetChatChattersByIdsResponse> = try client.sendSyncRequest(request, allowOnMainThread: true)
        let chatters = response.response.entity.chatChatters[chatId]?.chatters ?? [:]
        return chatters.compactMapValues({ (chatter) -> LarkModel.Chatter? in
            return try? LarkModel.Chatter.transformChatChatter(entity: response.response.entity, chatID: chatId, id: chatter.id)
        })
    }

    func fetchChatChattersFromLocal(ids: [String], chatId: String) -> Observable<[String: LarkModel.Chatter]> {
        return fetchChatChatters(ids: ids, chatId: chatId, strategy: .local)
    }

    func fetchChatChatters(ids: [String], chatId: String) -> Observable<[String: LarkModel.Chatter]> {
        return fetchChatChatters(ids: ids, chatId: chatId, strategy: nil)
    }

    func fetchChatChatters(ids: [String], chatId: String, strategy: RustPB.Basic_V1_SyncDataStrategy?) -> Observable<[String: LarkModel.Chatter]> {
        var request = RustPB.Im_V1_GetChatChattersByIdsRequest()
        request.chatterIds = ids
        request.chatID = chatId
        if let strategy = strategy {
            request.strategy = strategy
        }
        return self.client.sendAsyncRequest(request, transform: { (response: GetChatChattersByIdsResponse) -> [String: LarkModel.Chatter] in
            let chatters = response.entity.chatChatters[chatId]?.chatters ?? [:]
            return chatters.compactMapValues({ (chatter) -> LarkModel.Chatter? in
                return try? LarkModel.Chatter.transformChatChatter(entity: response.entity, chatID: chatId, id: chatter.id)
            })
        })
    }

    func fetchChatChatters(ids: [String], chatId: String, isForceServer: Bool) -> Observable<[String: Chatter]> {
        var request = RustPB.Im_V1_GetChatChattersByIdsRequest()
        request.chatterIds = ids
        request.chatID = chatId
        request.strategy = isForceServer ? .forceServer : .tryLocal
        return self.client.sendAsyncRequest(request, transform: { (response: GetChatChattersByIdsResponse) -> [String: LarkModel.Chatter] in
            let chatters = response.entity.chatChatters[chatId]?.chatters ?? [:]
            return chatters.compactMapValues({ (chatter) -> LarkModel.Chatter? in
                return try? LarkModel.Chatter.transformChatChatter(entity: response.entity, chatID: chatId, id: chatter.id)
            })
        })
    }

    func getChatter(id: String, forceRemoteData: Bool) -> Observable<LarkModel.Chatter?> {
        return self.getChatters(ids: [id], forceRemoteData: forceRemoteData).map({ (userModels) -> LarkModel.Chatter? in
            return userModels.first?.value
        })
    }

    func getChatter(id: String) -> Observable<LarkModel.Chatter?> {
        return self.getChatter(id: id, forceRemoteData: false)
    }

    func getChatters(ids: [String]) -> Observable<[String: LarkModel.Chatter]> {
        return self.getChatters(ids: ids, forceRemoteData: false)
    }

    func getChatChatters(ids: [String], chatId: String) -> Observable<[String: LarkModel.Chatter]> {
        return self.getChatChatters(ids: ids, chatId: chatId, forceRemoteData: false)
    }

    func getChattersFromLocal(ids: [String]) throws -> [String: LarkModel.Chatter] {
        guard !ids.isEmpty else {
            return [:]
        }
        var request = RustPB.Contact_V1_MGetChattersRequest()
        request.chatterIds = ids
        return try self.client.sendSyncRequest(request, transform: { (response: MGetChattersResponse) -> [String: LarkModel.Chatter] in
            return response.entity.chatters.compactMapValues { (chatter) -> LarkModel.Chatter? in
                return try? LarkModel.Chatter.transformChatter(entity: response.entity, id: chatter.id)
            }
        })
    }

    // MARK: - Fetch profile information
    func fetchUserProfileInfomation(userId: String, contactToken: String) -> Observable<UserProfile> {
        return RustChatterModule
                .fetchUserProfile(userId: userId, contactToken: contactToken, client: self.client)
                .map({ UserProfile.transform(pb: $0) })
                .subscribeOn(scheduler)
    }

    func fetchNewUserProfileInfomation(userId: String,
                                       contactToken: String,
                                       chatId: String,
                                       sourceType: RustPB.Basic_V1_ContactSource) -> Observable<RustPB.Contact_V2_GetUserProfileResponse> {
        return RustChatterModule
                .fetchNewUserProfile(userId: userId,
                                     contactToken: contactToken,
                                     chatId: chatId,
                                     client: self.client,
                                     sourceType: sourceType)
                .subscribeOn(scheduler)
    }

    func fetchUserPersonalInfoRequest(userId: String) -> Observable<ServerPB_Users_PullUserPersonalInfoResponse> {
        var request = ServerPB.ServerPB_Users_PullUserPersonalInfoRequest()
        request.userID = userId
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .pullUserPersonalInfo)
    }

    func getNewUserProfileInfomation(userId: String,
                                     contactToken: String,
                                     chatId: String) -> Observable<RustPB.Contact_V2_GetUserProfileResponse> {
        return RustChatterModule
            .getNewUserProfile(userId: userId,
                               contactToken: contactToken,
                               chatId: chatId,
                               client: self.client)
            .subscribeOn(scheduler)
    }

    /// 查询是否能打电话
    func checkUserPhoneNumber(userId: Int64) -> Observable<ServerPB_Users_CheckUserPhoneNumberResponse> {
        var request = ServerPB_Users_CheckUserPhoneNumberRequest()
        request.targetUserID = userId
        return client.sendPassThroughAsyncRequest(request, serCommand: .checkUserPhoneNumber)
    }

    /// 设置对方号码查询次数限制
    func setPhoneQueryQuotaRequest(userId: String, quota: String) -> Observable<Void> {
        var request = RustPB.Contact_V1_SetPhoneQueryQuotaRequest()
        request.targetUserID = userId
        request.quota = quota
        return self.client.sendAsyncRequest(request)
    }

    /// 获取对方号码查询次数
    func getPhoneQueryQuotaRequest(userId: String) -> Observable<(Int32, Int32)> {
        var request = RustPB.Contact_V1_GetPhoneQueryDailyQuotaRequest()
        request.targetUserID = userId
        return self.client.sendSyncRequest(request, transform: { (response: GetPhoneQueryDailyQuotaResponse) -> (Int32, Int32) in
            return (response.dailyQuota, response.maxLimit)
        })
    }

    /// 拉取对方号码查询次数
    func fetchPhoneQueryQuotaRequest(userId: String) -> Observable<(Int32, Int32)> {
        var request = RustPB.Contact_V1_GetPhoneQueryDailyQuotaRequest()
        request.targetUserID = userId
        return self.client.sendAsyncRequest(request, transform: { (response: GetPhoneQueryDailyQuotaResponse) -> (Int32, Int32) in
            return (response.dailyQuota, response.maxLimit)
        })
    }

    /// 发起额度申请
    func sendPhoneQueryQuotaApplyRequest(todayQueryTimes: Int32) -> Observable<LarkModel.CardContent> {
        var request = RustPB.Contact_V1_SendPhoneQueryQuotaApplyRequest()
        request.todayQueryTimes = todayQueryTimes
        return self.client.sendAsyncRequest(request, transform: { (response: SendPhoneQueryQuotaApplyResponse) -> LarkModel.CardContent in
            return CardContent.transform(cardContent: response.cardContent)
        })
    }

    func fetchServiceChatId() -> Observable<String> {
        return RustChatterModule.fetchServiceChatId(client: self.client).subscribeOn(scheduler)
    }

    // MARK: - 星标联系人
    func getSpecialFocusChatterList() -> Observable<[Chatter]> {
        var request = RustPB.Contact_V1_GetFocusChatterListRequest()
        request.syncDataStrategy = .tryLocal
        return client.sendAsyncRequest(request, transform: { (res: RustPB.Contact_V1_GetFocusChatterListResponse) -> [Chatter] in
            return res.chatters.map { Chatter.transform(pb: $0) }
        })
    }

    func updateSpecialFocusStatus(to chatterIDs: [Int64], operate: Contact_V1_UpdateFocusChatterRequest.Operate) -> Observable<RustPB.Contact_V1_UpdateFocusChatterResponse> {
        var request = RustPB.Contact_V1_UpdateFocusChatterRequest()
        request.chatterIds = chatterIDs
        request.operate = operate
        return client.sendAsyncRequest(request)
    }

    var pushFocusChatter: Observable<PushFocusChatterMessage> {
        pushCenter.observable(for: PushFocusChatterMessage.self)
    }

    // MARK: - Update Chatter Information API
    func updateAvatar(avatarData: Data?) -> Observable<String> {
        guard let data = avatarData else {
            return Observable.just("").subscribeOn(scheduler)
        }
        return RustChatterModule
            .updateAvatar(image: data, client: client)
            .subscribeOn(scheduler)
    }

    func updateChatter(description: LarkModel.Chatter.Description) -> Observable<Bool> {
        return RustChatterModule
            .updateChatter(description: description, client: client)
            .map { _ in true }
            .subscribeOn(scheduler)
    }

    /// 更新chatter时区信息
    func updateTimezone(timezone: String) -> Observable<Void> {
        return RustChatterModule
            .updateTimezone(timezone: timezone, client: client)
            .map { _ in }
            .subscribeOn(scheduler)
    }

    func fetchDeviceNotifySetting(strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<NotifyConfig> {
        return RustChatterModule.fetchDeviceNotifySetting(client: self.client, strategy: strategy)
    }

    func fetchChatterDescriptions( count: Int32, offset: Int32) -> Observable<ChatterDescriptionEntity> {
         return RustChatterModule.fetchChatterDescriptions(count: count, offset: offset, client: self.client)
    }

    func deleteChatterDescription(item: LarkModel.Chatter.Description) -> Observable<Void> {
        return RustChatterModule.deleteChatterDescription(item: item, client: self.client)
    }

    func deleteChatterWorkStatus() -> Observable<Void> {
        return RustChatterModule.deleteChatterWorkStatus(client: self.client)
    }

    func setChannelNickname(chatId: String, nickname: String) -> Observable<Void> {
        return RustChatterModule.setChannelNickname(chatId: chatId, nickname: nickname, client: self.client)
    }

    func setChatterAlias(chatterId: String, contactToken: String, alias: String) -> Observable<Void> {
        return RustChatterModule.setChatterAlias(chatterId: chatterId, contactToken: contactToken, alias: alias, client: self.client)
    }

    func updateBotForbiddenState(chatterId: String, botMuteInfo: Basic_V1_Chatter.BotMutedInfo) -> Observable<Void> {
        return RustChatterModule.updateBotForbiddenState(chatterId: chatterId, botMuteInfo: botMuteInfo, client: client)
    }

    func fetchAtList(chatId: String, query: String?) -> Observable<RustPB.Im_V1_GetMentionChatChattersResponse> {
        var request = GetMentionChatChattersRequest()
        request.chatID = chatId
        if let query = query {
            request.query = query
        }

        request.isFromServer = false
        let localObservable = (self.client.sendAsyncRequest(request) as Observable<GetMentionChatChattersResponse>)

        request.isFromServer = true
        let remoteObservable = (self.client.sendAsyncRequest(request) as Observable<GetMentionChatChattersResponse>)

        struct D: MergeDep {
            var query: String
            func isEmpty(response: GetMentionChatChattersResponse) -> Bool {
                !query.isEmpty && response.inChatChatterIds.isEmpty && response.outChatChatterIds.isEmpty
            }
        }

        return mergedObservable(local: localObservable, remote: remoteObservable,
                                scheduler: self.scheduler as? SerialDispatchQueueScheduler,
                                delegate: D(query: query ?? ""), featureGatingService: featureGatingService).map({ $0.0 })
    }

    func fetchAtListWithLocalOrRemote(chatId: String, query: String?) -> Observable<(RustPB.Im_V1_GetMentionChatChattersResponse, Bool)> {
        var request = GetMentionChatChattersRequest()
        request.chatID = chatId
        if let query = query {
            request.query = query
        }

        request.isFromServer = false
        let localObservable = (self.client.sendAsyncRequest(request) as Observable<GetMentionChatChattersResponse>)

        request.isFromServer = true
        let remoteObservable = (self.client.sendAsyncRequest(request) as Observable<GetMentionChatChattersResponse>)

        struct D: MergeDep {
            var query: String
            func isEmpty(response: GetMentionChatChattersResponse) -> Bool {
                !query.isEmpty && response.inChatChatterIds.isEmpty && response.outChatChatterIds.isEmpty
            }
        }

        return mergedObservable(local: localObservable, remote: remoteObservable,
                                scheduler: self.scheduler as? SerialDispatchQueueScheduler,
                                delegate: D(query: query ?? ""),
                                featureGatingService: featureGatingService)
    }

    func fetchAtListRemoteDepartmentInfo(chatterIds: [Int64], requestID: String) -> Observable<(RustPB.Contact_V1_GetMentionChatterSensitiveInfoResponse, String)> {
        var request = Contact_V1_GetMentionChatterSensitiveInfoRequest()
        request.chatterIds = chatterIds
        request.strategy = .forceServer
        return self.client.sendAsyncRequest(request).map { ($0, requestID) }
    }

    func getTodoRecommendedChatters(count: Int32?) -> Observable<RustPB.Todo_V1_GetRecommendedContentsResponse> {
        var request = GetRecommendedContentsRequest()
        if let count = count {
            request.count = count
        }
        return self.client.sendAsyncRequest(request)
    }

    /// 根据chatterId获取openApp
    func fetchOpenAppState(botID: String) -> Observable<Void> {
        var request = RustPB.Openplatform_V1_GetOpenAppStateRequest()
        request.botID = botID
        /// true的含义是，如果数据库有数据返回数据库中的数据并触发回调，同时进行异步网络更新。否则等待网络数据返回后触发回调。
        /// false是，数据库有数据返回数据库数据并触发回调，数据库无数据就返回可用并触发回调，并进行异步网络更新。
        request.urgent = true
        return self.client.sendAsyncRequest(request).map({ _ in })
    }

    func getLocalChatChatters(
        chatId: String,
        filter: String?,
        cursor: String?,
        limit: Int?,
        condition: RustPB.Im_V1_GetChatChattersRequest.Condition?,
        offset: Int?
    ) -> Observable<Im_V1_GetChatChattersResponse> {
        var request = GetChatChattersRequest()
        request.chatID = chatId
        if let filter = filter { request.filter = filter }
        if let cursor = cursor { request.cursor = cursor }
        if let limit = limit { request.limit = Int32(limit) }
        if let condition = condition { request.condition = condition }
        if let offset = offset { request.offset = Int32(offset) }
        request.isFromServer = false
        return self.client.sendAsyncRequest(request)
    }

    /// 分页拉取群成员列表 大群专用，目前使用的地方：@列表、群成员列表 return：同步请求 + 异步请求
    func getChatChatters(
        chatId: String,
        filter: String?,
        cursor: String?,
        limit: Int?,
        condition: RustPB.Im_V1_GetChatChattersRequest.Condition?,
        forceRemote: Bool,
        offset: Int?,
        fromScene: RustPB.Im_V1_GetChatChattersRequest.FromScene?
    ) -> Observable<Im_V1_GetChatChattersResponse> {
        var request = GetChatChattersRequest()
        request.chatID = chatId
        if let filter = filter { request.filter = filter }
        if let cursor = cursor { request.cursor = cursor }
        if let limit = limit { request.limit = Int32(limit) }
        if let condition = condition { request.condition = condition }
        if let offset = offset { request.offset = Int32(offset) }
        if let fromScene = fromScene { request.fromScene = fromScene }
        Self.logger.info("<GetChatChatters> Im_V1_GetChatChattersRequest.fromScene: \(request.fromScene)")
        if forceRemote {
            request.isFromServer = true
            return self.client.sendAsyncRequest(request)
        } else {
            request.isFromServer = false
            let localOB: Observable<RustPB.Im_V1_GetChatChattersResponse> = self.client.sendAsyncRequest(request)

            request.isFromServer = true
            let remoteOB: Observable<RustPB.Im_V1_GetChatChattersResponse> = self.client.sendAsyncRequest(request)

            struct D: MergeDep {
                var chatId: String
                func isEmpty(response: Im_V1_GetChatChattersResponse) -> Bool {
                    if let chatters = response.entity.chatChatters[chatId]?.chatters, !chatters.isEmpty { return false }
                    return true
                }
            }

            return mergedObservable(local: localOB, remote: remoteOB,
                                    scheduler: self.scheduler as? SerialDispatchQueueScheduler,
                                    delegate: D(chatId: chatId),
                                    featureGatingService: featureGatingService).map({ $0.0 })
        }
    }

    /// 分页拉取按字母排序的群成员列表
    func getOrderChatChatters(chatId: String,
                              scene: RustPB.Im_V1_GetOrderedChatChattersRequest.Scene,
                              cursor: Int?,
                              count: Int,
                              uid: String?) -> RxSwift.Observable<RustPB.Im_V1_GetOrderedChatChattersResponse> {
        var request = GetOrderedChatChattersRequest()
        request.chatID = Int64(chatId) ?? 0
        request.scene = scene
        request.sortRule = .alphabeticalOrder
        request.count = Int32(count)
        if let cursor = cursor { request.chatterID = Int64(cursor) }
        if let uid = uid { request.uid = uid }
        return self.client.sendAsyncRequest(request)
    }

    /// 获取chat成员列表部门展示权限
    func getUserBehaviorPermissions() -> Observable<RustPB.Behavior_V1_GetUserBehaviorPermissionsResponse> {
        var request = Behavior_V1_GetUserBehaviorPermissionsRequest()
        request.behaviors = [.displayDepartment]
        return self.client.sendAsyncRequest(request)
    }

    /// 分页拉取群成员列表 大群专用，目前使用的地方：加急列表 return：异步请求
    func getUrgentChatChatters(
        chatId: String,
        filter: String?,
        cursor: String?,
        limit: Int?,
        offset: Int?
    ) -> Observable<RustPB.Im_V1_GetChatChattersResponse> {
        var request = GetChatChattersRequest()
        request.chatID = chatId
        if let filter = filter { request.filter = filter }
        if let cursor = cursor { request.cursor = cursor }
        if let limit = limit { request.limit = Int32(limit) }
        if let offset = offset { request.offset = Int32(offset) }

        request.isFromServer = true
        return self.client.sendAsyncRequest(request)
    }

    // MARK: - 应用内邀请
    /// 提交成员邀请(手机号/邮箱)
    func commitAdminInvitationList(inviteInfos: [String],
                                   names: [String],
                                   isEmail: Bool,
                                   departments: [Int64]) -> Observable<SetAdminInvitationResponse> {
        var request = SetAdminInvitationRequest()
        request.type = isEmail ? .email : .mobile
        request.invitationPlatform = .platformIphone
        if isEmail {
            request.emails = inviteInfos
        } else {
            request.mobiles = inviteInfos
        }
        request.names = names
        if !departments.isEmpty {
            request.departments = departments
        }
        return self.client.sendAsyncRequest(request).observeOn(MainScheduler.instance)
    }

    /// 提交首次banner展示时间
    func commitBannerBeginTime() -> Observable<SetBannerBeginTimeResponse> {
        let request = SetBannerBeginTimeRequest()
        return self.client.sendAsyncRequest(request).observeOn(MainScheduler.instance)
    }

    /// 获取用户权限
    func fetchUserInvitationMessage() -> Observable<GetUserInvitationMessageResponse> {
        var request = GetUserInvitationMessageRequest()
        request.invitationPlatform = .platformIphone
        return self.client.sendAsyncRequest(request).observeOn(MainScheduler.instance)
    }

    /// 获取活跃用户活动权限
    func fetchActivityBannerStatus() -> Observable<GetActivityBannerResponse> {
        let request = GetActivityBannerRequest()
        return self.client.sendAsyncRequest(request).observeOn(MainScheduler.instance)
    }

    /// 获取分享企业成员邀请的链接
    func fetchInvitationLink(forceRefresh: Bool = false,
                             isSameDepartment: Bool? = nil,
                             departments: [Int64] = []) -> Observable<GetInvitationLinkResponse> {
        var request = GetInvitationLinkRequest()
        request.isRefresh = forceRefresh
        request.invitationPlatform = .platformIphone
        if let isSameDepartment = isSameDepartment {
            request.isSameDepartment = isSameDepartment
        }
        if !departments.isEmpty {
            request.departmentID = departments[0]
        }
        return self.client.sendAsyncRequest(request).observeOn(MainScheduler.instance)
    }

    /// 获取更改姓名权限
    func fetchUserUpdateNamePermission() -> Observable<(Bool, Bool)> {
        let request = GetUserUpdateNamePermissionRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: GetUserUpdateNamePermissionResponse) -> (Bool, Bool) in
            return (response.enable, response.enableAnotherName)
        })
    }

    /// 设置姓名
    func setUserName(name: String) -> Observable<Void> {
        var request = SetUserNameRequest()
        request.name = name
        request.updateFields = [.name]
        return self.client.sendAsyncRequest(request).map({ _ in })
    }

    /// 设置别名
    func setAnotherName(anotherName: String) -> Observable<Void> {
        var request = SetUserNameRequest()
        request.anotherName = anotherName
        request.updateFields = [.anotherName]
        return self.client.sendAsyncRequest(request).map({ _ in })
    }

    /// 修改座位号
    func setStation(station: String) -> Observable<Void> {
        var request = RustPB.Contact_V1_UpdateChatterRequest()
        request.station = station
        return self.client.sendAsyncRequest(request).map({ _ in })
    }

    /// 修改个人信息页自定义字段
    func setPersonCustomInfo(customInfo: [String: Contact_V1_UpdateChatterRequest.ExtAttrValue]) -> Observable<Void> {
        var request = RustPB.Contact_V1_UpdateChatterRequest()
        request.extAttr = customInfo
        return self.client.sendAsyncRequest(request).map({ _ in })
    }

    /// 获取屏蔽权限设置
    func fetchUserBlockStatusRequest(userId: String, strategy: SyncDataStrategy? = nil) -> Observable<Contact_V2_GetUserBlockStatusResponse> {
        var request = RustPB.Contact_V2_GetUserBlockStatusRequest()
        request.blockUserID = userId
        if let strategy = strategy {
            request.strategy = strategy
        }
        return self.client.sendAsyncRequest(request)
    }

    /// 屏蔽/取消屏蔽
    func setupBlockUserRequest(blockUserID: String, isBlock: Bool) -> Observable<SetupBlockUserResponse> {
        var request = SetupBlockUserRequest()
        request.blockUserID = blockUserID
        request.blockStatus = isBlock
        return self.client.sendAsyncRequest(request)
    }

    /// 拉取外部联系人对我的权限
    func fetchExternalContactsAuthRequest(
        chatterIDs: [String],
        actiontype: RustPB.Basic_V1_Auth_ActionType
    ) -> Observable<ExternalContactsAuthResponse> {
        var request = FetchExternalContactsAuthRequest()
        request.chatterIds = chatterIDs

        return self.client.sendAsyncRequest(request)
    }

    /// 获取cp下是否有已激活用户
    func fetchActiveFlags(
        mobiles: [String],
        emails: [String]
    ) -> Observable<[String: Bool]> {
        var request = ServerPB_Users_CheckContactIsLinkedToUserRequest()
        request.mobiles = mobiles
        request.emails = emails
        let resp: Observable<ServerPB_Users_CheckContactIsLinkedToUserResponse> = client.sendPassThroughAsyncRequest(request, serCommand: .checkContactIsLinkedToUser)
        return resp.flatMap { (resp) -> Observable<[String: Bool]> in
            return .just(resp.contactIsLinkedToUser)
        }
    }

    /// URL预览人员列表组件主动拉chatters信息
    func fetchURLPreviewChatters(previewID: String, componentID: String, nextToken: String) -> Observable<Url_V1_PullUrlPreviewChattersListResponse> {
        var request = Url_V1_PullUrlPreviewChattersListRequest()
        request.previewID = previewID
        request.componentID = componentID
        request.nextToken = nextToken
        return client.sendAsyncRequest(request)
    }

    func getUserChatWindowFields(userId: [String], forceServer: Bool) -> Observable<Contact_V2_GetUserChatWindowFieldsResponse> {
        var request = Contact_V2_GetUserChatWindowFieldsRequest()
        request.userID = userId
        request.syncDataStrategy = forceServer ? .forceServer : .tryLocal
        return client.sendAsyncRequest(request)
    }
}

fileprivate extension RustChatterAPI {
    func getChatters(ids: [String], forceRemoteData: Bool) -> Observable<[String: LarkModel.Chatter]> {
        guard !ids.isEmpty else {
            return Observable.just([:]).subscribeOn(scheduler)
        }
        var obserable: Observable<[String: LarkModel.Chatter]>
        if forceRemoteData {
            obserable = RustChatterModule.fetchUsersByIds(userIds: ids, client: self.client)
        } else {
            obserable = Observable<([String: LarkModel.Chatter], [String])>.create({ [client] (observer) -> Disposable in
                var notInLocalIds: [String] = ids
                let localUserChatters = RustChatterModule.loadUsersByIds(userIds: ids, client: client)
                localUserChatters.forEach({ (_, chatter) in
                    if ids.contains(chatter.id) {
                        notInLocalIds.lf_remove(object: chatter.id)
                    }
                })
                observer.onNext((localUserChatters, notInLocalIds))
                observer.onCompleted()

                return Disposables.create()
            }).flatMap({ [client] (args) -> Observable<[String: LarkModel.Chatter]> in
                let (localUsers, notInLocalIds) = args
                var fromServer: Observable<[String: LarkModel.Chatter]> = .just([:])
                if !notInLocalIds.isEmpty {
                    fromServer = RustChatterModule.fetchUsersByIds(userIds: notInLocalIds, client: client)
                }
                return Observable.combineLatest(Observable.just(localUsers), fromServer)
                    .map({ (locals, remotes) -> [String: LarkModel.Chatter] in
                        return locals + remotes
                    })
            })
        }
        return obserable.subscribeOn(scheduler)
    }

    func getChatChatters(ids: [String], chatId: String, forceRemoteData: Bool) -> Observable<[String: LarkModel.Chatter]> {
        guard !ids.isEmpty, !chatId.isEmpty else {
            return Observable.just([:]).subscribeOn(scheduler)
        }
        var obserable: Observable<[String: LarkModel.Chatter]>
        if forceRemoteData {
            obserable = self.fetchChatChatters(ids: ids, chatId: chatId)
        } else {
            obserable = Observable<([String: LarkModel.Chatter], [String])>.create({ (observer) -> Disposable in
                var notInLocalIds: [String] = ids
                let localUserChatters = (try? self.getChatChattersFromLocal(ids: ids, chatId: chatId)) ?? [:]
                localUserChatters.forEach({ (_, chatter) in
                    if ids.contains(chatter.id) {
                        notInLocalIds.lf_remove(object: chatter.id)
                    }
                })
                observer.onNext((localUserChatters, notInLocalIds))
                observer.onCompleted()

                return Disposables.create()
            }).flatMap({ (args) -> Observable<[String: LarkModel.Chatter]> in
                let (localUsers, notInLocalIds) = args
                var fromServer: Observable<[String: LarkModel.Chatter]> = .just([:])
                if !notInLocalIds.isEmpty {
                    fromServer = self.fetchChatChatters(ids: notInLocalIds, chatId: chatId)
                }
                return Observable.combineLatest(Observable.just(localUsers), fromServer)
                    .map({ (locals, remotes) -> [String: LarkModel.Chatter] in
                        return locals + remotes
                    })
            })
        }
        return obserable.subscribeOn(scheduler)
    }
}

/// 合并本地源和远端源，并按兜底策略处理对应的结果。兜底策略为：
/// 并发请求，远端结果优先（可覆盖本地结果）
/// 其中一端出错，取有结果的一端
/// 都出错，报远端错误
func mergedObservable<T, D>(
    local: Observable<T>, remote: Observable<T>,
    scheduler: SerialDispatchQueueScheduler? = nil, delegate: D, featureGatingService: FeatureGatingService
) -> Observable<(T, Bool)> where D: MergeDep, D.Response == T {
    let source = Observable.merge(
        local.materialize().map { (false, $0) },
        remote.materialize().map { (true, $0) }
        ).observeOn(scheduler ?? SerialDispatchQueueScheduler(qos: .userInitiated))
    // wrap to send completed, for canceling early
    return Observable.create { (observer) -> Disposable in
        var state = ReqState<T>()
        let hasLocalEmptyBackupForChatter = featureGatingService.staticFeatureGatingValue(with: "ios.search.local.emtpy.chatter_in_chat")
        return source.subscribe { (event) in
            switch event {
            case let .next((isRemote, reqEvent)):
                // 兜底策略：
                // 并发请求，远端结果优先（可覆盖本地结果）
                // 其中一端出错，取有结果的一端
                // 都出错，报远端错误
                let setter: (ReqStateCase<T>) -> Void
                if isRemote {
                    setter = { state.remote = $0 }
                } else {
                    setter = { state.local = $0 }
                }
                func update(_ cases: ReqStateCase<T>) {
                    setter(cases)
                    // after change state, check the status and response
                    switch (state.local, state.remote) {
                    case (_, .success):
                        // 远端成功，直接结束
                        observer.onCompleted()
                    case (_, .empty(let response)) where !hasLocalEmptyBackupForChatter:
                        // 远端空，无兜底FG时，使用远端空结果.
                        observer.onNext((response, true))
                        observer.onCompleted()
                    case (.success, .some):
                        // 本地成功，远端失败，本地结束
                        observer.onCompleted()
                    case (.some, .empty(let response)):
                        // 本地失败，远端空, 通知空
                        observer.onNext((response, true))
                        observer.onCompleted()
                    case (.some, .failure(let error)):
                        // 本地失败，远端异常，报远端异常
                        observer.onError(error)
                    default: break
                    }
                }

                switch reqEvent {
                case .next(let response):
                    if delegate.isEmpty(response: response) {
                        update(.empty(response))
                    } else {
                        observer.onNext((response, isRemote)) // 结果直接输出，是否结束下面综合判断
                        update(.success(response))
                    }
                case .error(let error):
                    update(.failure(error))
                default: break // ignore complete in single source
                }
            // materialize has no error
            case .completed:
                observer.on(.completed)
            default: break
            }
        }
    }
}

protocol MergeDep {
    associatedtype Response
    func isEmpty(response: Response) -> Bool
}

enum ReqStateCase<T> {
    case success(T)
    case empty(T)
    case failure(Error)
}

struct ReqState<T> {
    var local: ReqStateCase<T>?
    var remote: ReqStateCase<T>?
}
