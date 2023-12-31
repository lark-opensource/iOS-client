//
//  RustChatterModule.swift
//  Lark
//
//  Created by Sylar on 2017/11/3.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import RxSwift
import LarkModel
import LarkSDKInterface
import LarkAccountInterface

final class RustChatterModule {
    // MARK: - Users

    class func loadUsersByIds(userIds: [String], client: SDKRustService) -> [String: LarkModel.Chatter] {
        var request = RustPB.Contact_V1_MGetChattersRequest()
        request.chatterIds = userIds
        do {
            return try client.sendSyncRequest(
                request,
                transform: { (response: MGetChattersResponse) -> [String: LarkModel.Chatter] in
                    return response.entity.chatters.compactMapValues { chatter in
                        return try? LarkModel.Chatter.transformChatter(entity: response.entity, id: chatter.id)
                    }
                })
        } catch {
            // log error
            return [:]
        }
    }

    class func fetchUsersByIds(userIds: [String], client: SDKRustService) -> Observable<[String: LarkModel.Chatter]> {
        var request = RustPB.Contact_V1_MGetChattersRequest()
        request.chatterIds = userIds
        return client.sendAsyncRequest(
            request,
            transform: { (response: MGetChattersResponse) -> [String: LarkModel.Chatter] in
                return response.entity.chatters.compactMapValues { chatter in
                    return try? LarkModel.Chatter.transformChatter(entity: response.entity, id: chatter.id)
                }
            })
    }

    // MARK: - User Profile
    class func fetchUserProfile(userId: String, contactToken: String, client: SDKRustService) -> Observable<RustPB.Contact_V1_GetUserProfileResponse> {
        var request = RustPB.Contact_V1_GetUserProfileRequest()
        if contactToken.isEmpty {
            request.userID = userId
        } else {
            request.contactToken = contactToken
        }
        return client.sendAsyncRequest(request)
    }

    class func fetchNewUserProfile(userId: String,
                                   contactToken: String,
                                   chatId: String,
                                   client: SDKRustService,
                                   sourceType: RustPB.Basic_V1_ContactSource) -> Observable<RustPB.Contact_V2_GetUserProfileResponse> {
        var request = RustPB.Contact_V2_GetUserProfileRequest()
        if contactToken.isEmpty {
            request.userID = userId
            request.chatID = chatId
            request.scene = chatId.isEmpty ? .byUserID : .inChat
        } else {
            request.contactToken = contactToken
            request.scene = .byContactToken
        }
        request.source = sourceType
        request.isSupportOneWayRelation = true
        request.syncDataStrategy = .forceServer
        return client.sendAsyncRequest(request)
    }

    class func getNewUserProfile(userId: String,
                                 contactToken: String,
                                 chatId: String,
                                 client: SDKRustService) -> Observable<RustPB.Contact_V2_GetUserProfileResponse> {
        var request = RustPB.Contact_V2_GetUserProfileRequest()
        if contactToken.isEmpty {
            request.userID = userId
            request.chatID = chatId
            request.scene = chatId.isEmpty ? .byUserID : .inChat
        } else {
            request.contactToken = contactToken
            request.scene = .byContactToken
        }
        request.isSupportOneWayRelation = true
        request.syncDataStrategy = .local
        return client.sendAsyncRequest(request)
    }

    // MARK: - User Settings

    // Show Notice Detail
    class func setClient(showNoticeDetail: Bool, client: SDKRustService) -> Observable<Void> {
        var request = RustPB.Basic_V1_SetClientStatusRequest()
        request.showNoticeDetail = showNoticeDetail
        return client.sendAsyncRequest(request)
    }

    class func setClient(showPhoneAlert: Bool, client: SDKRustService) -> Observable<Void> {
        var request = RustPB.Basic_V1_SetClientStatusRequest()
        request.showPhoneAlert = showPhoneAlert
        return client.sendAsyncRequest(request)
    }

    class func fetchRemoteSetting(client: SDKRustService, strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<(Bool, Bool, Bool)> {
        var request = RustPB.Basic_V1_GetClientStatusRequest()
        request.syncDataStrategy = strategy
        return client.sendAsyncRequest(request, transform: { (response: GetClientStatusResponse) -> (Bool, Bool, Bool) in
            return (response.showNoticeDetail, response.showPhoneAlert, response.adminCloseShowDetail)
        })
    }

    class func updateNotificationStatus(notifyDisable: Bool, client: SDKRustService) -> Observable<Bool> {
        return RustChatterModule.updateDeviceNotifySetting(type: .disableMobileNotify,
                                                        value: notifyDisable,
                                                        client: client)
    }

    class func updateNotificationStatus(notifyAtEnabled: Bool, client: SDKRustService) -> Observable<Bool> {
        return RustChatterModule.updateDeviceNotifySetting(type: .stillNotifyAt,
                                                        value: notifyAtEnabled,
                                                        client: client)
    }

    class func updateNotificationStatus(notifySpecialFocus: Bool, client: SDKRustService) -> Observable<Bool> {
        return RustChatterModule.updateDeviceNotifySetting(type: .stillNotifySpecialNotice,
                                                        value: notifySpecialFocus,
                                                        client: client)
    }

    class func updateNotificationStatus(items: [Basic_V1_NotificationSoundSetting.NotificationSoundSettingItem],
                                        client: SDKRustService) -> Observable<Bool> {
        var request = RustPB.Device_V1_SetDeviceNotifySettingRequest()
        request.type = .notificationSoundSetting
        var setting = Basic_V1_NotificationSoundSetting()
        setting.items = items
        request.setting.notificationSoundSetting = setting
        request.syncDataStrategy = .forceServer
        return client.sendAsyncRequest(
            request,
            transform: { (_: SetDeviceNotifySettingResponse) -> Bool in
                return true
            })
    }

    // MARK: Private Method
    fileprivate class func updateDeviceNotifySetting(
        type: SetDeviceNotifySettingRequest.TypeEnum,
        value: Bool,
        client: SDKRustService) -> Observable<Bool> {

        var request = RustPB.Device_V1_SetDeviceNotifySettingRequest()
        request.type = type
        switch type {
        case .disableMobileNotify:
            request.setting.disableMobileNotify = value
        case .stillNotifyAt:
            request.setting.stillNotifyAt = value
        case .all:
            request.setting.stillNotifyAt = value
            request.setting.disableMobileNotify = value
            request.setting.stillNotifySpecialNotice = value
        case .stillNotifySpecialNotice:
            request.setting.stillNotifySpecialNotice = value
        case .notificationSoundSetting:
            break
        @unknown default:
            assert(false, "new value")
            break
        }
        return client.sendAsyncRequest(
            request,
            transform: { (_: SetDeviceNotifySettingResponse) -> Bool in
                return true
            })
    }

    class func fetchServiceChatId(client: SDKRustService) -> Observable<String> {
        let request = RustPB.Im_V1_GetMyCustomerServiceChatRequest()
        return client.sendAsyncRequest(
            request,
            transform: { (response: GetMyCustomerServiceChatResponse) -> String in
                return response.chat.id
            })
    }

    class func updateAvatar(image: Data, client: SDKRustService) -> Observable<String> {
        // needMosaic不需要传
        var request = RustPB.Media_V1_UploadAvatarRequest()
        request.image = image

        return client.sendAsyncRequest(request) { (response: RustPB.Media_V1_UploadAvatarResponse) -> String in
            return response.key
        }.flatMap({ [client] (key) -> Observable<String> in
            // 需要获取到key之后再使用Contact_V1_UpdateChatterRequest更新头像
            var request = RustPB.Contact_V1_UpdateChatterRequest()
            request.iconKey = key
            return client.sendAsyncRequest(request, transform: { (_: UpdateChatterResponse) -> String in
                return key
            })
        })
    }

    class func updateChatter(description: LarkModel.Chatter.Description, client: SDKRustService) -> Observable<String> {
        var request = RustPB.Contact_V1_UpdateChatterRequest()
        request.description_p = description.text
        request.descriptionType = description.type
        return client.sendAsyncRequest(request, transform: { (response: UpdateChatterResponse) -> String in
            return response.message
        })
    }

    class func updateTimezone(timezone: String, client: SDKRustService) -> Observable<String> {
        var request = RustPB.Contact_V1_UpdateChatterRequest()
        request.timeZone = timezone
        return client.sendAsyncRequest(request, transform: { (response: UpdateChatterResponse) -> String in
            return response.message
        })
    }

    class func updateBotForbiddenState(chatterId: String, botMuteInfo: Basic_V1_Chatter.BotMutedInfo, client: SDKRustService) -> Observable<Void> {
        var request = RustPB.Contact_V1_UpdateChatterRequest()
        request.chatterID = chatterId
        request.mutedInfo = botMuteInfo
        return client.sendAsyncRequest(request, transform: { (_: UpdateChatterResponse) -> Void in
            return ()
        })
    }

    class func fetchDeviceNotifySetting(client: SDKRustService, strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<NotifyConfig> {
        var request = RustPB.Device_V1_GetDeviceNotifySettingRequest()
        request.syncDataStrategy = strategy
        return client.sendAsyncRequest(request) { (res: RustPB.Device_V1_GetDeviceNotifySettingResponse) -> NotifyConfig in
            let config = NotifyConfig()
            config.notifySpecialFocus = res.setting.stillNotifySpecialNotice
            config.atNotifyOpen = res.setting.stillNotifyAt
            config.notifyDisable = res.setting.disableMobileNotify
            config.notifySounds = res.setting.notificationSoundSetting
            return config
        }
    }

    class func fetchChatterDescriptions( count: Int32, offset: Int32, client: SDKRustService) -> Observable<ChatterDescriptionEntity> {
        var request = RustPB.Contact_V1_GetChatterDescriptionsRequest()
        request.count = count
        request.offset = offset
        return client.sendAsyncRequest(request) { (res: RustPB.Contact_V1_GetChatterDescriptionsResponse) -> ChatterDescriptionEntity in
            let descriptions = res.pairs.map({ (pair) -> LarkModel.Chatter.Description in
                var description = Chatter.Description()
                description.text = pair.description_p
                description.type = pair.descriptionType
                return description
            })
            return ChatterDescriptionEntity(descriptions: descriptions, hasMore: res.hasMore_p)
        }
    }

    class func deleteChatterDescription(item: LarkModel.Chatter.Description, client: SDKRustService) -> Observable<Void> {
        var request = RustPB.Contact_V1_DeleteChatterDescriptionRequest()
        request.description_p = item
        return client.sendAsyncRequest(request, transform: { (_: DeleteChatterDescriptionResponse) -> Void in
            return ()
        })
    }

    class func deleteChatterWorkStatus(client: SDKRustService) -> Observable<Void> {
        let request = RustPB.Contact_V1_DeleteChatterWorkStatusRequest()
        return client.sendAsyncRequest(request, transform: { (_: DeleteChatterWorkStatusResponse) -> Void in
            return ()
        })
    }

    class func setChannelNickname(chatId: String, nickname: String, client: SDKRustService) -> Observable<Void> {
        var request = RustPB.Contact_V1_SetChannelNicknameRequest()
        request.channel = RustPB.Basic_V1_Channel()
        request.channel.id = chatId
        request.channel.type = .chat
        request.nickname = nickname
        return client.sendAsyncSecurityRequest(request, transform: { (_: SetChannelNicknameResponse) -> Void in
            return ()
        })
    }

    class func setChatterAlias(chatterId: String, contactToken: String, alias: String, client: SDKRustService) -> Observable<Void> {
        var request = RustPB.Contact_V1_SetChatterAliasRequest()
        request.targetID = chatterId
        request.targetToken = contactToken
        request.alias = alias
        return client.sendAsyncRequest(request, transform: { (_: SetChatterAliasResponse) -> Void in
            return ()
        })
    }
}
