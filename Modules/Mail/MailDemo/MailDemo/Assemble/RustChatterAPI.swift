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

final class RustChatterSettingAPI: LarkAPI, ChatterSettingAPI {
    func fetchRemoteSetting(strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<(Bool, Bool)> {
        return Observable.empty()
    }

    func updateRemoteSetting(showNotifyDetail: Bool) -> Observable<Void> {
        return Observable.empty()
    }

    func updateRemoteSetting(showPhoneAlert: Bool) -> Observable<Void> {
        return Observable.empty()
    }

    func updateNotificationStatus(notifyDisable: Bool) -> Observable<Bool> {
        return Observable.empty()
    }

    func updateNotificationStatus(notifyAtEnabled: Bool) -> Observable<Bool> {
        return Observable.empty()
    }

    func updateNotificationStatus(notifySpecialFocus: Bool) -> Observable<Bool> {
        return Observable.empty()
    }
    func updateNotificationStatus(items: [Basic_V1_NotificationSoundSetting.NotificationSoundSettingItem]) -> Observable<Bool> {
        return Observable.empty()
    }
}

final class RustChatterAPI: LarkAPI, ChatterAPI {
    func fetchUserPersonalInfoRequest(userId: String) -> RxSwift.Observable<ServerPB.ServerPB_Users_PullUserPersonalInfoResponse> {
        .empty()
    }

    func setStation(station: String) -> RxSwift.Observable<Void> {
        .empty()
    }

    func setPersonCustomInfo(customInfo: [String : RustPB.Contact_V1_UpdateChatterRequest.ExtAttrValue]) -> RxSwift.Observable<Void> {
        .empty()
    }

    func updateBotForbiddenState(chatterId: String, botMuteInfo: RustPB.Basic_V1_Chatter.BotMutedInfo) -> RxSwift.Observable<Void> {
        return Observable.empty()
    }
    
    func fetchURLPreviewChatters(previewID: String, componentID: String, nextToken: String) -> Observable<Url_V1_PullUrlPreviewChattersListResponse> {
        return Observable.empty()
    }
    
    func fetchUserProfileInfomation(userId: String, contactToken: String) -> Observable<UserProfile> {
        return Observable.empty()
    }
    
    func getChatterFromLocal(id: String) -> Chatter? {
        return nil
    }
    
    func getChattersFromLocal(ids: [String]) throws -> [String : Chatter] {
        return [:]
    }
    
    func getChatChatterFromLocal(id: String, chatId: String) -> Chatter? {
        return nil
    }
    
    func getChatChattersFromLocal(ids: [String], chatId: String) throws -> [String : Chatter] {
        return [:]
    }
    
    func fetchChatChatters(ids: [String], chatId: String) -> Observable<[String : Chatter]> {
        return Observable.empty()
    }
    
    func fetchChatChattersFromLocal(ids: [String], chatId: String) -> Observable<[String : Chatter]> {
        return Observable.empty()
    }
    
    func fetchChatChatters(ids: [String], chatId: String, isForceServer: Bool) -> Observable<[String : Chatter]> {
        return Observable.empty()
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
    
    func getChatChatters(ids: [String], chatId: String) -> Observable<[String : Chatter]> {
        return Observable.empty()
    }
    
    func fetchNewUserProfileInfomation(userId: String, contactToken: String, chatId: String, sourceType: Basic_V1_ContactSource) -> Observable<Contact_V2_GetUserProfileResponse> {
        return Observable.empty()
    }
    
    func getNewUserProfileInfomation(userId: String, contactToken: String, chatId: String) -> Observable<Contact_V2_GetUserProfileResponse> {
        return Observable.empty()
    }
    
    func checkUserPhoneNumber(userId: Int64) -> Observable<ServerPB_Users_CheckUserPhoneNumberResponse> {
        return Observable.empty()
    }
    
    func setPhoneQueryQuotaRequest(userId: String, quota: String) -> Observable<Void> {
        return Observable.empty()
    }
    
    func getPhoneQueryQuotaRequest(userId: String) -> Observable<(Int32, Int32)> {
        return Observable.empty()
    }
    
    func fetchPhoneQueryQuotaRequest(userId: String) -> Observable<(Int32, Int32)> {
        return Observable.empty()
    }
    
    func sendPhoneQueryQuotaApplyRequest(todayQueryTimes: Int32) -> Observable<CardContent> {
        return Observable.empty()
    }
    
    func fetchServiceChatId() -> Observable<String> {
        return Observable.empty()
    }
    
    func updateAvatar(avatarData: Data?) -> Observable<String> {
        return Observable.empty()
    }
    
    func updateChatter(description: Chatter.Description) -> Observable<Bool> {
        return Observable.empty()
    }
    
    func updateTimezone(timezone: String) -> Observable<Void> {
        return Observable.empty()
    }
    
    func fetchDeviceNotifySetting(strategy: Basic_V1_SyncDataStrategy) -> Observable<NotifyConfig> {
        return Observable.empty()
    }
    
    func fetchChatterDescriptions(count: Int32, offset: Int32) -> Observable<ChatterDescriptionEntity> {
        return Observable.empty()
    }
    
    func deleteChatterDescription(item: Chatter.Description) -> Observable<Void> {
        return Observable.empty()
    }
    
    func deleteChatterWorkStatus() -> Observable<Void> {
        return Observable.empty()
    }
    
    func setChannelNickname(chatId: String, nickname: String) -> Observable<Void> {
        return Observable.empty()
    }
    
    func setChatterAlias(chatterId: String, contactToken: String, alias: String) -> Observable<Void> {
        return Observable.empty()
    }
    
    func fetchAtList(chatId: String, query: String?) -> Observable<Im_V1_GetMentionChatChattersResponse> {
        return Observable.empty()
    }
    
    func fetchAtListWithLocalOrRemote(chatId: String, query: String?) -> Observable<(Im_V1_GetMentionChatChattersResponse, Bool)> {
        return Observable.empty()
    }
    
    func getTodoRecommendedChatters(count: Int32?) -> Observable<Todo_V1_GetRecommendedContentsResponse> {
        return Observable.empty()
    }
    
    func fetchOpenAppState(botID: String) -> Observable<Void> {
        return Observable.empty()
    }
    
    func getLocalChatChatters(chatId: String, filter: String?, cursor: String?, limit: Int?, condition: Im_V1_GetChatChattersRequest.Condition?, offset: Int?) -> Observable<Im_V1_GetChatChattersResponse> {
        return Observable.empty()
    }
    
    func getChatChatters(chatId: String, filter: String?, cursor: String?, limit: Int?, condition: Im_V1_GetChatChattersRequest.Condition?, forceRemote: Bool, offset: Int?) -> Observable<Im_V1_GetChatChattersResponse> {
        return Observable.empty()
    }
    
    func getUrgentChatChatters(chatId: String, filter: String?, cursor: String?, limit: Int?, offset: Int?) -> Observable<Im_V1_GetChatChattersResponse> {
        return Observable.empty()
    }
    
    func commitAdminInvitationList(inviteInfos: [String], names: [String], isEmail: Bool, departments: [Int64]) -> Observable<Contact_V1_SetAdminInvitationResponse> {
        return Observable.empty()
    }
    
    func commitBannerBeginTime() -> Observable<Contact_V1_SetBannerBeginTimeResponse> {
        return Observable.empty()
    }
    
    func fetchUserInvitationMessage() -> Observable<Contact_V1_GetUserInvitationMessageResponse> {
        return Observable.empty()
    }
    
    func fetchActivityBannerStatus() -> Observable<Feed_V1_GetActivityBannerResponse> {
        return Observable.empty()
    }
    
    func fetchInvitationLink(forceRefresh: Bool, isSameDepartment: Bool?, departments: [Int64]) -> Observable<Contact_V1_GetInvitationLinkResponse> {
        return Observable.empty()
    }
    
    func fetchUserUpdateNamePermission() -> Observable<(Bool, Bool)> {
        return Observable.empty()
    }
    
    func setUserName(name: String) -> Observable<Void> {
        return Observable.empty()
    }
    
    func setAnotherName(anotherName: String) -> Observable<Void> {
        return Observable.empty()
    }
    
    func fetchUserBlockStatusRequest(userId: String, strategy: SyncDataStrategy?) -> Observable<Contact_V2_GetUserBlockStatusResponse> {
        return Observable.empty()
    }
    
    func setupBlockUserRequest(blockUserID: String, isBlock: Bool) -> Observable<SetupBlockUserResponse> {
        return Observable.empty()
    }
    
    func fetchExternalContactsAuthRequest(chatterIDs: [String], actiontype: Basic_V1_Auth_ActionType) -> Observable<ExternalContactsAuthResponse> {
        return Observable.empty()
    }
    
    func fetchActiveFlags(mobiles: [String], emails: [String]) -> Observable<[String : Bool]> {
        return Observable.empty()
    }
    
    func fetchURLPreviewChatters(previewID: String, componentID: String) -> Observable<[String]> {
        return Observable.empty()
    }
    
    func getUserChatWindowFields(userId: [String], forceServer: Bool) -> Observable<Contact_V2_GetUserChatWindowFieldsResponse> {
        return Observable.empty()
    }
    
    var pushFocusChatter: Observable<PushFocusChatterMessage> = Observable.empty()
    
    func getSpecialFocusChatterList() -> Observable<[Chatter]> {
        return Observable.empty()
    }
    
    func updateSpecialFocusStatus(to chatterIDs: [Int64], operate: Contact_V1_UpdateFocusChatterRequest.Operate) -> Observable<Contact_V1_UpdateFocusChatterResponse> {
        return Observable.empty()
    }
    
    
    static let logger = Logger.log(RustChatterAPI.self, category: "RustSDK.User")
    static var log = RustChatterAPI.logger

    override init(client: SDKRustService, onScheduler: ImmediateSchedulerType? = nil) {
        pushFocusChatter
        super.init(client: client, onScheduler: onScheduler)
    }
}

fileprivate extension RustChatterAPI {
    
    func getChatters(ids: [String], forceRemoteData: Bool) -> Observable<[String: LarkModel.Chatter]> {
        guard !ids.isEmpty else {
            return Observable.just([:]).subscribeOn(scheduler!)
        }
        var obserable: Observable<[String: LarkModel.Chatter]>
        obserable = Observable<([String: RustPB.Basic_V1_Chatter], [String])>.create({ [client] (observer) -> Disposable in
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
            var fromServer: Observable<[String: RustPB.Basic_V1_Chatter]> = .just([:])
            if !notInLocalIds.isEmpty {
                fromServer = RustChatterModule.fetchUsersByIds(userIds: notInLocalIds, client: client)
            }
            return Observable.combineLatest(Observable.just(localUsers), fromServer)
                .map({ (locals, remotes) -> [String: LarkModel.Chatter] in
                    return (locals + remotes).mapValues({ (chatter) -> LarkModel.Chatter in
                        return LarkModel.Chatter.transform(pb: chatter)
                    })
                })
        })
        return obserable.subscribeOn(scheduler!)
    }

    func getChatChatters(ids: [String], chatId: String, forceRemoteData: Bool) -> Observable<[String: LarkModel.Chatter]> {
       return Observable.empty()
    }
}

/// 合并本地源和远端源，并按兜底策略处理对应的结果。兜底策略为：
/// 并发请求，远端结果优先（可覆盖本地结果）
/// 其中一端出错，取有结果的一端
/// 都出错，报远端错误
func mergedObservable<T, D>(
    local: Observable<T>, remote: Observable<T>,
    scheduler: SerialDispatchQueueScheduler? = nil, delegate: D
) -> Observable<(T, Bool)> where D: MergeDep, D.Response == T {
    return Observable.empty()
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


final class RustChatterModule {
    class func loadUsersByIds(userIds: [String], client: SDKRustService) -> [String: RustPB.Basic_V1_Chatter] {
        var request = RustPB.Contact_V1_MGetChattersRequest()
        request.chatterIds = userIds
        do {
            return try client.sendSyncRequest(
                request,
                transform: { (response: RustPB.Contact_V1_MGetChattersResponse) -> [String: RustPB.Basic_V1_Chatter] in
                response.entity.chatters
                })
        } catch {
            // log error
            return [:]
        }
    }
    class func fetchUsersByIds(userIds: [String], client: SDKRustService) -> Observable<[String: RustPB.Basic_V1_Chatter]> {
        var request = RustPB.Contact_V1_MGetChattersRequest()
        request.chatterIds = userIds
        return client.sendAsyncRequest(
            request,
            transform: { (response: RustPB.Contact_V1_MGetChattersResponse) -> [String: RustPB.Basic_V1_Chatter] in
            response.entity.chatters
            })
    }
}
