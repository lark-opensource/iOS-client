//
//  SDKAssembly.swift
//  Lark
//
//  Created by liuwanlin on 2018/8/9.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkFoundation
import LarkContainer
import LarkRustClient
import RxSwift
import Swinject
import LarkModel
import LarkCustomerService
import LarkFeatureGating
import LarkSDKInterface
import LarkAccountInterface
import LarkDebug
import LarkDebugExtensionPoint
import LarkAppConfig
import LarkCache
import LarkStorage
import LarkEmotionKeyboard
import BootManager
import LKCommonsLogging
import ByteWebImage
import LarkEmotion
import TangramService
import LarkAssembler
import LarkSetting
import LarkSendMessage

enum SDK {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "lark.ios.messeger.userscope.refactor") //Global
        return v
    }
    static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

public final class SDKAssembly: LarkAssemblyInterface {
    static let log = Logger.log(SDKAssembly.self, category: "assembly")

    public init() { }

    public func registLaunch(container: Container) {
        NewBootManager.register(ChatterPreloadTask.self)
    }

    public func registContainer(container: Container) {
        let userGraph = container.inObjectScope(SDK.userGraph)
        let user = container.inObjectScope(SDK.userScope)

        userGraph.register(SDKRustService.self) { (r) -> SDKRustService in
            return SDKClient(client: try r.resolve(assert: RustService.self))
        }

        // packer
        user.register(MessagePacker.self) { (r) -> MessagePacker in
            let packer = MessagePackerImpl()
            packer.fetchers = [
                ChatChatterDataFetcher(chatterAPI: try r.resolve(assert: ChatterAPI.self))
            ]
            packer.packItems = [
                .chatter: [FromChatterPackItem()],
                .reaction: [ReactionPackItem()],
                .systemTrigger: [SystemTriggerPackItem()],
                .callChatter: [CallChatterPackItem()],
                .manipulator: [ManipulatorPackItem()],
                .recaller: [RecallerPackItem()]
            ]
            return packer
        }

        // userspace
        user.register(UserCacheService.self) { r -> UserCacheService in
            return UserCacheServiceImpl(docsUserCacheService: try r.resolve(assert: SDKDependency.self), userResolver: r)
        }

        // service
        user.register(ReactionService.self) { _ in
            guard let reactionService = EmojiImageService.default else { fatalError("should never go here") }
            reactionService.loadReactions()
            return reactionService
        }

        user.register(DraftCache.self) { r in
            return DraftCacheImpl(
                draftAPI: try r.resolve(assert: DraftAPI.self),
                chatAPI: try r.resolve(assert: ChatAPI.self),
                messageAPI: try r.resolve(assert: MessageAPI.self))
        }

        user.register(ChatService.self) { r in
            let chatAPI = try r.resolve(assert: ChatAPI.self)
            let chatterAPI = try r.resolve(assert: ChatterAPI.self)
            let userID = try r.resolve(assert: PassportUserService.self).user.userID
            return ChatServiceImpl(
                chatAPI: chatAPI,
                chatterAPI: chatterAPI,
                userID: userID,
                userPushCenter: try r.userPushCenter
            )
        }

        user.register(UserGeneralSettings.self) { (r) -> UserGeneralSettings in
            return UserGeneralSettingsImpl(
                chatterSettingAPI: try r.resolve(assert: ChatterSettingAPI.self),
                chatterAPI: try r.resolve(assert: ChatterAPI.self),
                urgentAPI: try r.resolve(assert: UrgentAPI.self),
                configAPI: try r.resolve(assert: ConfigurationAPI.self),
                pushCenter: try r.userPushCenter,
                timeFormatService: try r.resolve(assert: TimeFormatSettingService.self),
                serverNTPTimeService: try r.resolve(assert: ServerNTPTimeService.self),
                featureGatingService: try r.resolve(assert: FeatureGatingService.self),
                currentChatterID: (try r.resolve(assert: PassportUserService.self)).user.userID
            )
        }

        user.register(TimeFormatSettingService.self) { _ in
            TimeFormatSettingImpl()
        }

        user.register(ServerNTPTimeService.self) { (r) in
            return ServerNTPTimeImpl(ntpAPI: try r.resolve(assert: NTPAPI.self))
        }

        user.register(AudioRecognizeService.self) { (r) -> AudioRecognizeService in
            return AudioRecognizeServiceImpl(
                audioAPI: try r.resolve(assert: AudioAPI.self),
                pushCenter: try r.userPushCenter
            )
        }

        user.register(LarkCustomerServiceAPI.self) { (r) -> LarkCustomerServiceAPI in
            let rustClient = try r.resolve(assert: RustService.self)
            return LarkCustomerService(client: rustClient, navigator: r.navigator, userResolver: r)
        }

        user.register(UserAppConfig.self) { (r) -> UserAppConfig in
            let config: UserAppConfig = BaseUserAppConfig(
                configAPI: try r.resolve(assert: ConfigurationAPI.self),
                pushWebSocketStatusOb: try r.userPushCenter.observable(for: PushWebSocketStatus.self),
                pushAppConfigOb: try r.userPushCenter.observable(for: PushAppConfig.self),
                settingService: try r.resolve(assert: SettingService.self)
            )
            return config
        }

        user.register(UserUniversalSettingService.self) { (r) -> UserUniversalSettingService in
            let config: UserUniversalSettingService = UserUniversalSettingConfig(
                pushCenter: try r.userPushCenter,
                userResolver: r)
            return config
        }

        user.register(TenantUniversalSettingService.self) { (r) -> TenantUniversalSettingService in
            let config: TenantUniversalSettingService = TenantUniversalSettingConfig(pushCenter: try r.userPushCenter, userResolver: r)
            return config
        }

        user.register(FeedAPI.self) { (r) -> FeedAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustFeedAPI(
                client: rustClient,
                onScheduler: scheduler
            )
        }

        user.register(UrgentAPI.self) { (r) -> UrgentAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            let currentChatterId = try r.resolve(assert: PassportUserService.self).user.userID
            return RustUrgentAPI(
                client: rustClient,
                currentChatterId: currentChatterId,
                onScheduler: scheduler
            )
        }

        user.register(ChatAPI.self) { (r) -> ChatAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            let currentChatterId = try r.resolve(assert: PassportUserService.self).user.userID
            return RustChatAPI(
                userResolver: r,
                client: rustClient,
                currentChatterId: currentChatterId,
                featureGatingService: try r.resolve(assert: FeatureGatingService.self),
                onScheduler: scheduler
            )
        }

        user.register(OncallAPI.self) { (r) -> OncallAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustOncallAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(ZendeskAPI.self) { (r) -> ZendeskAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustZendeskAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(TeamAPI.self) { (r) -> TeamAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustTeamAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(ToolKitAPI.self) { (r) -> RustToolKitAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustToolKitAPI(userResolver: r, client: rustClient, onScheduler: scheduler)
        }

        user.register(SceneAPI.self) { (r) -> SceneAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustSceneAPI(userResolver: r, client: rustClient, onScheduler: scheduler)
        }

        user.register(ChatterAPI.self) { (r) -> ChatterAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustChatterAPI(client: rustClient,
                                  pushCenter: try r.userPushCenter,
                                  featureGatingService: try r.resolve(assert: FeatureGatingService.self),
                                  onScheduler: scheduler)
        }

        user.register(MessageAPI.self) { (r) -> MessageAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            let urlPreviewService = try r.resolve(assert: MessageURLPreviewService.self)
            let currentChatterId = try r.resolve(assert: PassportUserService.self).user.userID
            return RustMessageAPI(
                client: rustClient,
                urlPreviewService: urlPreviewService,
                currentChatterId: currentChatterId,
                onScheduler: scheduler
            )
        }

        user.register(MessageURLPreviewService.self) { r in
            return MessageURLPreviewServiceImp(urlPreviewAPI: try r.resolve(assert: URLPreviewAPI.self), pushCenter: try r.userPushCenter)
        }

        user.register(TranslateAPI.self) { (r) -> TranslateAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustTranslateAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(DraftAPI.self) { (r) -> DraftAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustDraftAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(NTPAPI.self) { (r) -> NTPAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustNTPAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(RedPacketAPI.self) { (r) -> RedPacketAPI in
            return RustRedPaketAPI(client: try r.resolve(assert: SDKRustService.self), onScheduler: scheduler)
        }

        user.register(AuthAPI.self) { (r) -> AuthAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            let deviceId = try r.resolve(assert: DeviceService.self).deviceId
            return RustAuthAPI(
                deviceId: deviceId,
                client: rustClient,
                onScheduler: scheduler
            )
        }

        user.register(ReactionAPI.self) { (r) -> ReactionAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustReactionAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(ReactionSkinTonesAPI.self) { (r) -> ReactionSkinTonesAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustReactionAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(DocAPI.self) { (r) -> DocAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustDocAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(ThreadAPI.self) { (r) -> ThreadAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            let urlPreviewService = try r.resolve(assert: MessageURLPreviewService.self)
            return RustThreadAPI(client: rustClient, urlPreviewService: urlPreviewService, currentChatterId: try r.resolve(assert: PassportUserService.self).user.userID, onScheduler: scheduler)
        }

        user.register(ChatterSettingAPI.self) { (r) -> ChatterSettingAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustChatterSettingAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(ConfigurationAPI.self) { (r) -> ConfigurationAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            let deviceId = try r.resolve(assert: DeviceService.self).deviceId
            return RustConfigurationAPI(client: rustClient, onScheduler: scheduler, deviceId: deviceId)
        }

        user.register(SecurityFileAPI.self) { (r) -> SecurityFileAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            if r.fg.staticFeatureGatingValue(with: "messenger.file.detect") {
                return RustSecurityFileAPI(client: rustClient, onScheduler: scheduler)
            }
            return RustFileAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(ImageAPI.self) { (r) -> ImageAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustImageAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(MailAPI.self) { (r) -> MailAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustMailAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(AudioAPI.self) { (r) -> AudioAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustAudioAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(VideoAPI.self) { (r) -> VideoAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustVideoAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(ResourceAPI.self) { (r) -> ResourceAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustResourceAPI(userResolver: r, client: rustClient, onScheduler: scheduler)
        }

        user.register(FlagAPI.self) { (r) -> FlagAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            let currentChatterId = try r.resolve(assert: PassportUserService.self).user.userID
            return RustFlagAPI(
                pushCenter: try r.userPushCenter,
                currentChatterId: currentChatterId,
                client: rustClient,
                onScheduler: scheduler
            )
        }

        user.register(FavoritesAPI.self) { (r) -> FavoritesAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            let currentChatterId = try r.resolve(assert: PassportUserService.self).user.userID
            return RustFavoriteAPI(
                userPushCenter: try r.userPushCenter,
                currentChatterId: currentChatterId,
                client: rustClient,
                onScheduler: scheduler
            )
        }

        user.register(PinAPI.self) { (r) -> PinAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            let currentChatterId = try r.resolve(assert: PassportUserService.self).user.userID
            let urlPreviewService = try r.resolve(assert: MessageURLPreviewService.self)
            return RustPinAPI(
                userPushCenter: try r.userPushCenter,
                currentChatterId: currentChatterId,
                client: rustClient,
                urlPreviewService: urlPreviewService,
                onScheduler: scheduler)
        }

        user.register(PassportAPI.self) { (r) -> PassportAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustPassportAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(StickerAPI.self) { (r) -> StickerAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustStickerAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(ChatApplicationAPI.self) { (r) -> ChatApplicationAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustChatApplicationAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(ExternalContactsAPI.self) { (r) -> ExternalContactsAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustExternalContactsAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(UserAPI.self) { (r) -> UserAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustUserAPI(client: rustClient,
                               featureGatingService: try r.resolve(assert: FeatureGatingService.self),
                               onScheduler: scheduler)
        }

        user.register(ContactAPI.self) { (r) -> ContactAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustUserAPI(client: rustClient,
                               featureGatingService: try r.resolve(assert: FeatureGatingService.self),
                               onScheduler: scheduler)
        }

        user.register(RustLogAPI.self) { (r) -> RustLogAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustLogAPIImpl(client: rustClient, onScheduler: scheduler)
        }

        user.register(HeartbeatAPI.self) { (r) -> HeartbeatAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustHeartbeatAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(MailAPI.self) { (r) -> MailAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustMailAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(PushAPI.self) { (r) -> PushAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustPushAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(UrlAPI.self) { (r) -> RustUrlAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustUrlAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(DynamicResourceAPI.self) { (r) -> DynamicResourceAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustDynamicResourceAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(TenantAPI.self) { (r) -> TenantAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustTenantAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(NamecardAPI.self) { (r) -> NamecardAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustNamecardAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(NotificationDiagnoseAPI.self) { (r) -> NotificationDiagnoseAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return RustNotificationDiagnoseAPI(client: rustClient, onScheduler: scheduler)
        }

        user.register(ChatterManagerProtocol.self) { r in
            let userPushCenter = try r.userPushCenter
            let pushChatter = userPushCenter.observable(for: PushChatters.self).map { $0.chatters }
            return ChatterManager(pushChatters: pushChatter, userResolver: r)
        }
    }

    public func registDebugItem(container: Container) {
        ({ ClearCurrentUserUserDefaultsItem() }, SectionType.dataInfo)
        ({ ClearStandardUserDefaultsItem() }, SectionType.dataInfo)
        ({ ClearLaunchGuideUserDefaultsItem() }, SectionType.dataInfo)
        ({ ResetLarkItem { try? container.getCurrentUserResolver().resolve(assert: UserSpaceService.self) } }, SectionType.dataInfo) // foregroundUser
        ({ CacheDebugItem() }, SectionType.debugTool)
    }

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory { ChatterManagerPassportDelegate(container: container) }, PassportDelegatePriority.middle)
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushChats, ChatsPushHandler.init(resolver:)) // 聊天
        (Command.pushChatChatters, ChatChatterPushHandler.init(resolver:)) // 群成员变化
        (Command.pushChatAdminUsers, ChatAdminPushHandler.init(resolver:)) // 群管理员变化
        (Command.pushChatChatterTag, ChatChatterTagPushHandler.init(resolver:)) // 群管理tag变化
        (Command.pushChatChatterListDepartmentName, ChatChatterListDepartmentNameHandler.init(resolver:)) // 群成员列表部门信息变化
        (Command.pushFeedCards, FeedCardsPushHandler.init(resolver:)) // FeedCards
        (Command.pushWebSocketStatus, WebSocketStatusPushHandler.init(resolver:)) // 长链状态
        (Command.pushMessagesV2, MessagePushHandler.init(resolver:)) // 消息通知
        (Command.pushTranslateLanguagesSetting, TranslateLanguageSettingPushHandler.init(resolver:)) //翻译设置通知，设置部分数据，只需部分覆盖
        (Command.pushLanguagesConfigurationNotice, TranslateLanguagesConfigurationPushHandler.init(resolver:)) //翻译语言效果设置通知，设置部分数据，只需部分覆盖
        (Command.pushLanguageAutoTranslateScope, TranslateLanguagesAutoTranslateScopePushHandler.init(resolver:)) //翻译Scopes设置通知，只需部分覆盖语种纬度
        (Command.pushLanguagesConfigurationNoticeV2, TranslateLanguagesConfigurationV2PushHandler.init(resolver:)) //翻译语言效果设置通知V2，设置部分数据，只需部分覆盖
        (Command.pushDisableAutoTranslateLanguageNotice, DisableAutoTranslateLanguagePushHandler.init(resolver:)) //不自动翻译语言设置通知，设置部分数据，只需部分覆盖
        (Command.pushAutoTranslateScopeNotice, AutoTranslateScopePushHandler.init(resolver:)) //翻译scope通知，设置部分数据，只需部分覆盖
        (Command.pushUploadFile, UploadFilePushHandler.init(resolver:)) //申请Badge
        (Command.pushContact, ExternalContactsPushHandler.init(resolver:)) // 文件上传进度
        (Command.pushChatters, ChattersPushHandler.init(resolver:)) // 成员变化
        (Command.pushAppConfig, AppConfigPushHandler.init(resolver:)) // AppConfig push
        (Command.pushDeviceNotifySetting, DeviceNotifySettingPushHandler.init(resolver:)) // 当设置了pc在线不弹出提醒后，sdk会根据pc在线状态, 告知上层此时是否需要在首页告知用户当前不提醒的状态
        (Command.pushDeviceOnlineStatus, DeviceOnlineStatusPushHandler.init(resolver:)) // 当其他端登陆/退出的时候，会收到此push
        (Command.pushValidDevices, ValidDevicesPushHandler.init(resolver:)) // 当前登录设备
        (Command.pushCustomizedStickers, StickersPushHandler.init(resolver:)) // 自定义表情
        (Command.pushStickerSets, StickerSetsPushHandler.init(resolver:)) // 用户最近使用表情
        (Command.pushUserReactions, UserRecentReactionPushHandler.init(resolver:)) // 用户最常使用表情
        (Command.pushUserMruReactions, UserMruReactionPushHandler.init(resolver:))
        (Command.pushSaveToSpaceStoreState, SaveToSpaceStorePushHandler.init(resolver:)) // 保存到坚果云
        (Command.pushDownloadFile, DownloadFilePushHandler.init(resolver:)) // 下载文件进度
        (Command.pushHideChannel, PushHideChannelHandler.init(resolver:))
        (Command.pushResourceProgress, ResourceProgressPushHandler.init(resolver:))
        (Command.pushResource, ResourcePushHandler.init(resolver:))
        (Command.pushChannelNickname, PushChannelNicknameHandler.init(resolver:))
        (Command.pushPinReadStatus, PinReadStatePushHandler.init(resolver:))
        (Command.pushCardMessageID, CardMessageActionResultPushHandler.init(resolver:))
        (Command.pushThreads, ThreadPushHandler.init(resolver:))
        (Command.pushUserSetting, UserSettingPushHandler.init(resolver:))
        (Command.pushMiniprogramUpdate, MiniprogramUpdatePushHandler.init(resolver:))
        (Command.pushOpenCommon, OpenCommonRequestPushHandler.init(resolver:))
        (Command.pushAudioMessageRecognitionResult, AudioMessageRecognitionPushHandler.init(resolver:))
        (Command.pushOfflineUpdatedChats, OfflineUpdatedChatsPushHandler.init(resolver:))
        (Command.pushTopicGroups, PushTopicGroupHandler.init(resolver:))
        (Command.pushTopicGroupTabBadge, PushTopicGroupTabBadgeHandler.init(resolver:))
        (Command.pushThreadFeedAvatarChanges, PushThreadFeedAvatarChangesHandler.init(resolver:))
        (Command.pushMyThreadsReplyPrompt, MyThreadsReplyPromptHandler.init(resolver:))
        (Command.pushAppFeed, AppFeedPushHandler.init(resolver:))
        (Command.pushMiniprogramPreview, MiniprogramPreviewPushHandler.init(resolver:))
        (Command.pushDynamicNetStatus, DynamicNetStatusPushHandler.init(resolver:))
        (Command.pushTrack, TrackPushHandler.init(resolver:)) // 会话时区通知
        (Command.pushChatTimeTipNotice, ChatTimeTipNotifyPushHandler.init(resolver:)) // 会话个人状态通知
        (Command.pushChattersPartialInfo, ChattersPartialInfoPushHandler.init(resolver:))
        (Command.pushPreloadUpdatedChats, PreloadUpdatedChatPushHandler.init(resolver:))
        (Command.pushWayToAddMeSetting, AddMeSettingPushHandler.init(resolver:))
        (Command.pushMessageReactions, MessageReactionsPushHandler.init(resolver:))
        (Command.pushAiMessagesFeedback, MessageFeedbackStatusPushHandler.init(resolver:))
        (Command.pushMessageReadStates, MessageReadStatesPushHandler.init(resolver:))
        (Command.pushFaceToFaceApplicants, FaceToFaceApplicantsPushHandler.init(resolver:))
        (Command.pushMonitorAppLagStatus, MonitorAPPLagPushHandler.init(resolver:))
        (Command.pushUniversalUserSetting, UserUniversalPushHandler.init(resolver:))
        (Command.pushExtractPackageStatus, ExtrackPackagePushHandler.init(resolver:))
        (Command.pushChatTopNotice, ChatTopNoticePushHandler.init(resolver:))
        (Command.pushChunkyUploadStatus, VideoChunkPushHandler.init(resolver:))
        (Command.pushChatTabs, ChatTabsPushHandler.init(resolver:))
        (Command.pushChatPinCount, ChatPinCountPushHandler.init(resolver:))
        (Command.pushChatToolkits, ChatToolKitsPushHandler.init(resolver:))
        (Command.pushTenantMessageConf, TenantMessageConfPushHandler.init(resolver:))
        (Command.pushScheduleMessage, ScheduleMessagePushHandler.init(resolver:))
        (Command.pushChatMenuItems, ChatMenuItemsPushHandler.init(resolver:))
        (Command.pushChatWidgets, ChatWidgetsPushHandler.init(resolver:))
        (Command.pushUniversalChatPinOperation, ChatUniversalChatPinOperationPushHandler.init(resolver:))
        (Command.pushFirstScreenUniversalChatPins, ChatFirstScreenUniversalChatPinsPushHandler.init(resolver:))
        (Command.pushChatPinInfo, ChatPinInfoPushHandler.init(resolver:))
        (Command.pushAudioRecognition, PushAudioRecognitionHandler.init(resolver:))
    }
}
