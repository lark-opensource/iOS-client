//
//  ChatterAPI.swift
//  LarkSDKInterface
//
//  Created by chengzhipeng-bytedance on 2018/5/30.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import RustPB
import ServerPB

public struct ChatterDescriptionEntity {
    public let descriptions: [Chatter.Description]
    public let hasMore: Bool

    public init(descriptions: [Chatter.Description], hasMore: Bool) {
        self.descriptions = descriptions
        self.hasMore = hasMore
    }
}

public struct ChatterPhoneModel {
    public let number: String
    public let hasPermission: Bool

    public init(number: String, hasPermission: Bool) {
        self.number = number
        self.hasPermission = hasPermission
    }
}

public final class NotifyConfig {
    public var notifyDisableDriver: Driver<Bool> {
        return notifyDisableVariable.asDriver()
    }

    public var atNotifyOpenDriver: Driver<Bool> {
        return atNotifyOpenVariable.asDriver()
    }

    private var notifyDisableVariable: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    private var atNotifyOpenVariable: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    public var notifyDisable: Bool = false {
        didSet {
            notifyDisableVariable.accept(notifyDisable)
        }
    }

    public var atNotifyOpen: Bool = false {
        didSet {
            atNotifyOpenVariable.accept(atNotifyOpen)
        }
    }

    private var notifySpecialFocusRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    public var notifySpecialFocusDriver: Driver<Bool> {
        return notifySpecialFocusRelay.asDriver()
    }

    public var notifySpecialFocus: Bool = false {
        didSet {
            notifySpecialFocusRelay.accept(notifySpecialFocus)
        }
    }

    private var notifySoundsRelay: BehaviorRelay<Basic_V1_NotificationSoundSetting> = BehaviorRelay<Basic_V1_NotificationSoundSetting>(value: Basic_V1_NotificationSoundSetting())

    public var notifySoundsDriver: Driver<Basic_V1_NotificationSoundSetting> {
        return notifySoundsRelay.asDriver()
    }

    public var notifySounds: Basic_V1_NotificationSoundSetting = Basic_V1_NotificationSoundSetting() {
        didSet {
            notifySoundsRelay.accept(notifySounds)
        }
    }

    public init() {}
}

// MARK: - ChatterAPI
public typealias ChatterAPIProvider = () -> ChatterAPI

public typealias ExternalContactsAuthResponse = RustPB.Contact_V2_GetExternalContactsAuthResponse

public protocol ChatterAPI {

    func getChatterFromLocal(id: String) -> Chatter?

    func getChattersFromLocal(ids: [String]) throws -> [String: Chatter]

    func getChatChatterFromLocal(id: String, chatId: String) -> Chatter?

    func getChatChattersFromLocal(ids: [String], chatId: String) throws -> [String: Chatter]

    func fetchChatChatters(ids: [String], chatId: String) -> Observable<[String: Chatter]>

    func fetchChatChattersFromLocal(ids: [String], chatId: String) -> Observable<[String: Chatter]>

    func fetchChatChatters(ids: [String], chatId: String, isForceServer: Bool) -> Observable<[String: Chatter]>

    func getChatter(id: String) -> Observable<Chatter?>

    func getChatter(id: String, forceRemoteData: Bool) -> Observable<Chatter?>

    /// 根据制定的用户id 查找用户数据，如果本地数据库没有，则后续通过异步接口返回缺失的数据
    func getChatters(ids: [String]) -> Observable<[String: Chatter]>

    /// 根据制定的用户id 查找用户数据，如果本地数据库没有，则后续通过异步接口返回缺失的数据
    func getChatChatters(ids: [String], chatId: String) -> Observable<[String: Chatter]>

    func fetchUserProfileInfomation(userId: String, contactToken: String) -> Observable<UserProfile>

    func fetchNewUserProfileInfomation(userId: String,
                                       contactToken: String,
                                       chatId: String,
                                       sourceType: RustPB.Basic_V1_ContactSource) -> Observable<RustPB.Contact_V2_GetUserProfileResponse>
    /// 拉取个人信息页工位和自定义字段数据
    func fetchUserPersonalInfoRequest(userId: String) -> Observable<ServerPB_Users_PullUserPersonalInfoResponse>

    func getNewUserProfileInfomation(userId: String,
                                     contactToken: String,
                                     chatId: String) -> Observable<RustPB.Contact_V2_GetUserProfileResponse>

    /// 查询是否能打电话
    func checkUserPhoneNumber(userId: Int64) -> Observable<ServerPB_Users_CheckUserPhoneNumberResponse>

    /// 设置对方号码查询次数限制
    func setPhoneQueryQuotaRequest(userId: String, quota: String) -> Observable<Void>

    /// 获取对方号码查询次数
    func getPhoneQueryQuotaRequest(userId: String) -> Observable<(Int32, Int32)>

    /// 拉取对方号码查询次数
    func fetchPhoneQueryQuotaRequest(userId: String) -> Observable<(Int32, Int32)>

    /// 发起额度申请
    func sendPhoneQueryQuotaApplyRequest(todayQueryTimes: Int32) -> Observable<CardContent>

    /// 获取专属客服的 chatId
    func fetchServiceChatId() -> Observable<String>

    func updateAvatar(avatarData: Data?) -> Observable<String>

    func updateChatter(description: Chatter.Description) -> Observable<Bool>

    /// 更新chatter时区信息
    func updateTimezone(timezone: String) -> Observable<Void>

    /// 获取当前多端登陆推送设置信息
    func fetchDeviceNotifySetting(strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<NotifyConfig>

    /// 获取工作状态历史接口
    func fetchChatterDescriptions(count: Int32, offset: Int32) -> Observable<ChatterDescriptionEntity>

    /// 删除工作历史
    func deleteChatterDescription(item: Chatter.Description) -> Observable<Void>

    /// 删除工作状态
    func deleteChatterWorkStatus() -> Observable<Void>

    /// 设置群昵称
    func setChannelNickname(chatId: String, nickname: String) -> Observable<Void>

    /// 设置备注
    func setChatterAlias(chatterId: String, contactToken: String, alias: String) -> Observable<Void>

    /// 获取@列表
    func fetchAtList(chatId: String, query: String?) -> Observable<RustPB.Im_V1_GetMentionChatChattersResponse>

    /// 获取@列表
    /// - Parameters:
    ///   - chatId: chatID
    ///   - query: search query
    ///   - return: GetMentionChatChattersResponse, isRemote
    func fetchAtListWithLocalOrRemote(chatId: String, query: String?) -> Observable<(RustPB.Im_V1_GetMentionChatChattersResponse, Bool)>

    /// 获取@列表Remote部门信息
    /// - Parameters:
    ///   - chatterIDs: chatterIDs
    ///   - requestID: 本次请求的标识ID
    ///   - return: GetMentionChatChattersResponse
    func fetchAtListRemoteDepartmentInfo(chatterIds: [Int64], requestID: String) -> Observable<(RustPB.Contact_V1_GetMentionChatterSensitiveInfoResponse, String)>

    /// 选人组件中获得推荐的chatter进行展示,目前仅 Todo 使用
    /// - Parameter count: 推荐chatter的个数. 端上不传，则由后端控制，默认50个
    func getTodoRecommendedChatters(count: Int32?) -> Observable<RustPB.Todo_V1_GetRecommendedContentsResponse>

    /// 根据chatterId获取openApp
    func fetchOpenAppState(botID: String) -> Observable<Void>

    /// 获取本地群成员列表
    func getLocalChatChatters(
        chatId: String,
        filter: String?,
        cursor: String?,
        limit: Int?,
        condition: RustPB.Im_V1_GetChatChattersRequest.Condition?,
        offset: Int?
    ) -> Observable<Im_V1_GetChatChattersResponse>

    /// 分页拉取群成员列表
    func getChatChatters(
        chatId: String,
        filter: String?,
        cursor: String?,
        limit: Int?,
        condition: RustPB.Im_V1_GetChatChattersRequest.Condition?,
        forceRemote: Bool,
        offset: Int?,
        fromScene: RustPB.Im_V1_GetChatChattersRequest.FromScene?
    ) -> Observable<RustPB.Im_V1_GetChatChattersResponse>

    /// 分页拉取群成员列表 大群专用，目前使用的地方：加急列表 return：异步请求
    func getUrgentChatChatters(
        chatId: String,
        filter: String?,
        cursor: String?,
        limit: Int?,
        offset: Int?
    ) -> Observable<RustPB.Im_V1_GetChatChattersResponse>

    /// 分页拉取按字母排序的群成员列表
    func getOrderChatChatters(chatId: String,
                              scene: RustPB.Im_V1_GetOrderedChatChattersRequest.Scene,
                              cursor: Int?,
                              count: Int,
                              uid: String?) -> Observable<RustPB.Im_V1_GetOrderedChatChattersResponse>

    /// 获取chat成员列表部门展示权限
    func getUserBehaviorPermissions() -> Observable<RustPB.Behavior_V1_GetUserBehaviorPermissionsResponse>

    /// 提交成员邀请列表
    func commitAdminInvitationList(inviteInfos: [String],
                                   names: [String],
                                   isEmail: Bool,
                                   departments: [Int64])
        -> Observable<RustPB.Contact_V1_SetAdminInvitationResponse>

    /// 提交首次banner展示时间
    func commitBannerBeginTime() -> Observable<RustPB.Contact_V1_SetBannerBeginTimeResponse>

    /// 获取用户权限
    func fetchUserInvitationMessage() -> Observable<RustPB.Contact_V1_GetUserInvitationMessageResponse>

    /// 获取活跃用户活动权限
    func fetchActivityBannerStatus() -> Observable<RustPB.Feed_V1_GetActivityBannerResponse>

    /// 获取分享企业成员邀请的链接
    func fetchInvitationLink(forceRefresh: Bool,
                             isSameDepartment: Bool?,
                             departments: [Int64]) -> Observable<RustPB.Contact_V1_GetInvitationLinkResponse>

    /// 获取更改姓名、别名的权限
    func fetchUserUpdateNamePermission() -> Observable<(Bool, Bool)>

    /// 设置姓名
    func setUserName(name: String) -> Observable<Void>

    /// 设置别名
    func setAnotherName(anotherName: String) -> Observable<Void>

    /// 修改座位号
    func setStation(station: String) -> Observable<Void>

    /// 修改个人信息页自定义字段
    func setPersonCustomInfo(customInfo: [String: Contact_V1_UpdateChatterRequest.ExtAttrValue]) -> Observable<Void>

    /// 获取屏蔽权限设置
    func fetchUserBlockStatusRequest(userId: String, strategy: SyncDataStrategy?) -> Observable<Contact_V2_GetUserBlockStatusResponse>

    /// 屏蔽/取消屏蔽
    func setupBlockUserRequest(blockUserID: String, isBlock: Bool) -> Observable<SetupBlockUserResponse>

    /// 拉取外部联系人对我的权限
    func fetchExternalContactsAuthRequest(
        chatterIDs: [String],
        actiontype: RustPB.Basic_V1_Auth_ActionType
    ) -> Observable<ExternalContactsAuthResponse>

    /// 获取cp下是否有已激活用户
    func fetchActiveFlags(
        mobiles: [String],
        emails: [String]
    ) -> Observable<[String: Bool]>

    /// URL预览人员列表组件主动拉chatters信息
    func fetchURLPreviewChatters(previewID: String, componentID: String, nextToken: String) -> Observable<Url_V1_PullUrlPreviewChattersListResponse>

    func getUserChatWindowFields(userId: [String], forceServer: Bool) -> Observable<Contact_V2_GetUserChatWindowFieldsResponse>

    // 修改机器人是否禁止推送
    func updateBotForbiddenState(chatterId: String, botMuteInfo: Basic_V1_Chatter.BotMutedInfo) -> Observable<Void>

    // MARK: - 星标联系人
    var pushFocusChatter: Observable<PushFocusChatterMessage> { get }

    func getSpecialFocusChatterList() -> Observable<[Chatter]>

    func updateSpecialFocusStatus(
        to chatterIDs: [Int64],
        operate: Contact_V1_UpdateFocusChatterRequest.Operate
    ) -> Observable<RustPB.Contact_V1_UpdateFocusChatterResponse>

}

public extension ChatterAPI {
    func fetchUserProfileInfomation(userId: String) -> Observable<UserProfile> {
        return fetchUserProfileInfomation(userId: userId, contactToken: "")
    }
}
