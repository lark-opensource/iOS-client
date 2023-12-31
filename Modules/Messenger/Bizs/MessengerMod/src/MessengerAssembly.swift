//
//  MessengerAssembly.swift
//  LarkMessenger
//
//  Created by CharlieSu on 12/3/19.
//

import Foundation
import Swinject
import LarkContact
import LarkSearch
import LarkSearchCore
import LarkNavigation
import LarkMessageCore
import LarkChat
import LarkFeed
import LarkFlag
import LarkMine
import LarkThread
import LarkAudio
import LarkCore
import LarkUrgent
import LarkFocus
import LarkForward
import LarkFinance
import LarkFile
import LarkChatSetting
import LarkQRCode
import LarkMessengerInterface
import LarkAccountInterface
import LarkMonitor
import LarkRustClient
import LarkShareToken
import LarkFeedPlugin
import BootManager
import LKContentFix
import LarkTeam
import LarkAI
import Moment
import DynamicURLComponent
import LarkSDK
import LarkOpenChat
import LarkAssembler
import LKLoadable
import LarkSDKInterface
import HelpDesk
import LarkSendMessage
import LarkChatOpenKeyboard
import LarkSetting
import LarkContainer
import CTADialog

enum Messenger {
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
// nolint: long_function
public final class MessengerAssembly: LarkAssemblyInterface {

    public let config: MessengerAssemblyConfig

    public init(config: MessengerAssemblyConfig = MessengerAssemblyDefaultConfig()) {
        self.config = config
    }

    public func registContainer(container: Container) {
        let userGraph = container.inObjectScope(Messenger.userGraph)
        userGraph.register(ContactDependency.self) { ContactDependencyImpl(resolver: $0) as ContactDependency }
        userGraph.register(ChatDependency.self) { ChatDependencyImpl(resolver: $0) as ChatDependency }
        container.inObjectScope(Feed.userScope).register(FeedDependency.self) { FeedDependencyImpl(resolver: $0) as FeedDependency }
        container.inObjectScope(.userGraph).register(MineDependency.self) { MineDependencyImpl(resolver: $0) as MineDependency }
        userGraph.register(ThreadDependency.self) { ThreadDependencyImpl(resolver: $0) as ThreadDependency }
        userGraph.register(AudioDependency.self) { AudioDependencyImpl(resolver: $0) as AudioDependency }
        userGraph.register(LarkMomentDependency.self) { LarkMomentDependencyImpl(resolver: $0) as LarkMomentDependency }
        userGraph.register(LarkCoreDependency.self) { LarkCoreDependencyImpl(resolver: $0) as LarkCoreDependency }
        userGraph.register(ChatSettingDependency.self) { ChatSettingDependencyImpl(resolver: $0) as ChatSettingDependency }
        userGraph.register(MessageCoreDependency.self) { MessageCoreDependencyImpl(resolver: $0) as MessageCoreDependency }
        userGraph.register(AIDependency.self) { AIDependencyImpl(resolver: $0) as AIDependency }
        userGraph.register(FileDependency.self) { FileDependencyImpl(resolver: $0) as FileDependency }
        userGraph.register(SearchDependency.self) { SearchDependencyImpl(resolver: $0) as SearchDependency }
        userGraph.register(SearchCoreDependency.self) { SearchCoreDependencyImpl(resolver: $0) as SearchCoreDependency }
        userGraph.register(SDKDependency.self) { SDKDependencyImpl(resolver: $0) as SDKDependency }
        userGraph.register(CTADialogDependency.self) { CTADialogDependencyImpl(resolver: $0) as CTADialogDependency }
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(NewUpdateWaterMaskTask.self)
        NewBootManager.register(NewSetupModuleTask.self)
        NewBootManager.register(NewUpdateTimeZoneTask.self)
        NewBootManager.register(NewFetchPayTokenTask.self)
        NewBootManager.register(NewSetupGuideTask.self)
        NewBootManager.register(NewSetupKeyboardTask.self)
        NewBootManager.register(LarkMessengerAssembleTask.self)
        NewBootManager.register(ThemeLaunchTask.self)
    }

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory(delegateProvider: {
            container.whenPassportDelegate { LarkModulePassportDelegate(container: container) }
        }), PassportDelegatePriority.low)
    }

    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory(delegateProvider: {
            container.whenLauncherDelegate { LarkModuleDelegate(resolver: container) }
        }), LauncherDelegateRegisteryPriority.low)
    }

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        ContactAssembly(config: config)
        SearchAssembly()
        FeedPluginAssembly()
        FlagAssembly()
        MineAssembly()
        AudioAssembly()
        CoreAssembly()
        ImageAssembly()
        UrgentAssembly(config: config)
        LarkForwardAssembly()
        FileAssembly()
        FinanceAssembly()
        FileNavigationAssembly()
        EmotionShopAssembly()
        QRCodeAssembly()
        AIAssembly()
        TeamAssembly()
        DynamicURLAssembly()
        FocusAssembly()
        SDKAssembly()
        LarkSendMessageAssembly()
        LarkMonitorAssembly()
        LKContentFixAssembly()
        ChatAssembly(config: config)
        NewChatAssembly(config: config)
        MessageDetailAssembly()
        MessageCoreAssembly()
        ChatSettingAssembly()
        PinAssembly()
        ThreadAssembly()
        MomentsAssembly()
    }

    @_silgen_name("Lark.OpenChat.Messenger.ChatVC")
    static public func openChatRegister() {
        // 在这里集中注册，方便控制顺序
        ChatWidgetModule.register(ChatWidgetURLPreviewSubModule.self)
        // 群 New Pin - 列表模式
        ChatPinCardModule.registerSubModule(UnknownPinCardSubModule.self)
        ChatPinCardModule.registerCellViewModel(UnknownPinCardCellViewModel.self)
        ChatPinCardModule.registerSubModule(AnnouncementPinCardSubModule.self)
        ChatPinCardModule.registerCellViewModel(AnnouncementPinCardCellViewModel.self)
        ChatPinCardModule.registerSubModule(URLPreviewPinCardSubModule.self)
        ChatPinCardModule.registerCellViewModel(URLPreviewPinCardCellViewModel.self)
        ChatPinCardModule.registerSubModule(MessagePinCardSubModule.self)
        ChatPinCardModule.registerCellViewModel(MessagePinCardCellViewModel.self)
        // 群 New Pin - 吸顶模式
        ChatPinSummaryModule.registerSubModule(UnknownPinSummarySubModule.self)
        ChatPinSummaryModule.registerCellViewModel(UnknownPinSummaryCellViewModel.self)
        ChatPinSummaryModule.registerSubModule(URLPreviewPinSummarySubModule.self)
        ChatPinSummaryModule.registerCellViewModel(URLPreviewPinSummaryCellViewModel.self)
        ChatPinSummaryModule.registerSubModule(AnnouncementPinSummarySubModule.self)
        ChatPinSummaryModule.registerCellViewModel(AnnouncementPinSummaryCellViewModel.self)
        ChatPinSummaryModule.registerSubModule(MessagePinSummarySubModule.self)
        ChatPinSummaryModule.registerCellViewModel(MessagePinSummaryCellViewModel.self)
        ChatTabModule.register(ChatMessageTabModule.self)
        ChatTabModule.register(ChatTabFileModule.self)
        ChatTabModule.register(ChatTabDocSpaceModule.self)
        ChatTabModule.register(ChatTabDocAPIModule.self)
        ChatTabModule.register(ChatTabPinModule.self)
        ChatTabModule.register(ChatTabChatAnnouncementModule.self)
        ChatTabModule.register(ChatTabURLModule.self)
        ChatTabModule.register(ChatTabMeetingMinuteModule.self)
        ChatBannerModule.register(ChatTopNoticeBannerModule.self)
        ChatBannerModule.register(ChatApproveBannerModule.self)
        ChatFooterModule.register(ChatterResignMaskFooterModule.self)
        ChatFooterModule.register(ApplyToJoinGroupFooterModule.self)
        CryptoChatFooterModule.register(CryptoChatterResignMaskFooterModule.self)
        //ChatKeyboardTopExtendModule.register(ChatKeyboardTopExtendDemoSubModule.self)
        ChatKeyboardTopExtendModule.register(MyAITopExtendSubModule.self)
        ChatKeyboardTopExtendModule.register(ChatKeyboardTopExtendToolKitSubModule.self)
        ChatNavigationBarModule.registerRightSubModule(ByteViewChatNavigationBarSubModule.self)
        ChatNavigationBarModule.registerRightSubModule(MicroAppChatNavigationBarSubModule.self)
        ChatNavigationBarModule.registerRightSubModule(CalendarChatNavigationBarSubModule.self)
        ChatNavigationBarModule.registerLeftSubModule(ChatNavigationBarSceneItemSubModule.self)
        ChatModeNavigationBarModule.registerLeftSubModule(ChatNavigationBarSceneItemSubModule.self)
        ChatMessagePickerNavigationBarModule.registerLeftSubModule(ChatNavigationBarSceneItemSubModule.self)

        // 注册消息菜单操作 -会话界面
        ChatMessageActionModule.register(MutePlayMessageActionSubModule.self)
        ChatMessageActionModule.register(AudioPlayModeMessageActionSubModule.self)
        ChatMessageActionModule.register(AudioTextMessageActionSubModule.self)
        ChatMessageActionModule.register(UrgentMessageActionSubModule.self)
        ChatMessageActionModule.register(RecallMessageActionSubModule.self)
        ChatMessageActionModule.register(MultiEditMessageActionSubModule.self)
        ChatMessageActionModule.register(ChatReplyMessageActionSubModule.self)
        ChatMessageActionModule.register(ForwardMessageActionSubModule.self)
        ChatMessageActionModule.register(OpenThreadMessageActionSubModule.self)
        ChatMessageActionModule.register(CreateThreadMessageActionSubModule.self)
        ChatMessageActionModule.register(MultiSelectMessageActionSubModule.self)
        ChatMessageActionModule.register(ChatCopyMessageActionSubModule.self)
        ChatMessageActionModule.register(FlagMessageActionSubModule.self)
        ChatMessageActionModule.register(FavoriteMessageActionSubModule.self)
        ChatMessageActionModule.register(PinMessageActionSubModule.self)
        ChatMessageActionModule.register(ChatPinMessageActionSubModule.self)
        ChatMessageActionModule.register(TopMessageMessageActionSubModule.self)
        ChatMessageActionModule.register(AddToStickerMessageActionSubModule.self)
        ChatMessageActionModule.register(TodoMessageActionSubModule.self)
        ChatMessageActionModule.register(TranslateMessageActionSubModule.self)
        ChatMessageActionModule.register(SelectTranslateMessageActionSubModule.self)
        ChatMessageActionModule.register(MeegoMessageActionSubModule.self)
        ChatMessageActionModule.register(ImageEditMessageActionSubModule.self)
        ChatMessageActionModule.register(DeleteMessageActionSubModule.self)
        ChatMessageActionModule.register(TakeActionV2MessageActionSubModule.self)
        ChatMessageActionModule.register(ChatMessageLinkMessageActionSubModule.self)
        ChatMessageActionModule.register(SearchMessageActionSubModule.self)
        ChatMessageActionModule.register(RestrictedMessageActionSubModule.self)
        ChatMessageActionModule.register(LikeActionSubModule.self)
        ChatMessageActionModule.register(DislikeActionSubModule.self)
        ChatMessageActionModule.register(ChatSaveToMessageActionModule.self)
        ChatMessageActionModule.register(QuickActionInfoSubModule.self)
        ChatMessageActionModule.register(ViewGenerationProcessActionSubModule.self)
        /// Chat save to注册的按钮
        ChatSaveToMessageActionModule.register(FavoriteMessageActionSubModule.self)
        ChatSaveToMessageActionModule.register(FlagMessageActionSubModule.self)

        // 注册消息菜单操作 -回复详情页
        MessageDetailMessageActionModule.register(MutePlayMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(AudioPlayModeMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(AudioTextMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(UrgentMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(RecallMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(MultiEditMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(ForwardMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(MessageDetailCopyMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(FlagMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(FavoriteMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(PinMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(ChatPinMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(AddToStickerMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(TodoMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(TranslateMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(SelectTranslateMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(SwitchLanguageMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(MeegoMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(ImageEditMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(DeleteMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(TakeActionV2MessageActionSubModule.self)
        MessageDetailMessageActionModule.register(ChatMessageLinkMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(SearchMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(ToOriginalMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(MessageDetailSaveToMessageActionModule.self)

        MessageDetailSaveToMessageActionModule.register(FavoriteMessageActionSubModule.self)
        MessageDetailSaveToMessageActionModule.register(FlagMessageActionSubModule.self)

        // 注册消息菜单操作 - 密聊
        CryptoMessageActionModule.register(UrgentMessageActionSubModule.self)
        CryptoMessageActionModule.register(RecallMessageActionSubModule.self)
        CryptoMessageActionModule.register(ChatReplyMessageActionSubModule.self)
        CryptoMessageActionModule.register(CryptoCopyMessageActionSubModuleInChat.self)
        CryptoMessageActionModule.register(DeleteMessageActionSubModule.self)
        CryptoMessageActionModule.register(AudioPlayModeMessageActionSubModule.self)

        // 注册消息菜单操作 - 密聊详情页
        CryptoMessageDetailMessageActionModule.register(UrgentMessageActionSubModule.self)
        CryptoMessageDetailMessageActionModule.register(RecallMessageActionSubModule.self)
        CryptoMessageDetailMessageActionModule.register(CryptoCopyMessageActionSubModuleInDetail.self)
        CryptoMessageDetailMessageActionModule.register(DeleteMessageActionSubModule.self)
        CryptoMessageDetailMessageActionModule.register(AudioPlayModeMessageActionSubModule.self)

        // 注册消息菜单操作 - 话题群
        ThreadMessageActionModule.register(MultiEditMessageActionSubModuleInThread.self)
        ThreadMessageActionModule.register(ThreadCopyMessageActionSubModule.self)
        ThreadMessageActionModule.register(TodoMessageActionSubModuleInThread.self)
        ThreadMessageActionModule.register(TranslateMessageActionSubModule.self)
        ThreadMessageActionModule.register(SelectTranslateMessageActionSubModule.self)
        ThreadMessageActionModule.register(SearchMessageActionSubModule.self)
        // TODO: 确认一下话题群首页需要有转文字等按钮吗?安卓目前没有,且话题群这里此功能无法使用
        ThreadMessageActionModule.register(AudioTextMessageActionSubModule.self)
        ThreadMessageActionModule.register(MutePlayMessageActionSubModuleInThreadChat.self)
        ThreadMessageActionModule.register(AudioPlayModeMessageActionSubModule.self)
        ThreadMessageActionModule.register(AddToStickerMessageActionSubModule.self)
        ThreadMessageActionModule.register(ImageEditMessageActionSubModule.self)

        ThreadMessageActionModule.register(ThreadSaveToMessageActionModule.self)

        // 注册消息菜单操作 - 话题详情页
        ThreadDetailMessageActionModule.register(AudioTextMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(MutePlayMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(AddToStickerMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(MultiEditMessageActionSubModuleInThread.self)
        ThreadDetailMessageActionModule.register(ForwardMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(MultiSelectMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(ThreadDetailCopyMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(FlagMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(FavoriteMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(TodoMessageActionSubModuleInThread.self)
        ThreadDetailMessageActionModule.register(TranslateMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(SelectTranslateMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(SearchMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(AudioPlayModeMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(ThreadDetailRecallMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(ThreadReplyMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(ImageEditMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(ThreadDetailSaveToMessageActionModule.self)

        ThreadDetailSaveToMessageActionModule.register(FavoriteMessageActionSubModule.self)
        ThreadDetailSaveToMessageActionModule.register(FlagMessageActionSubModule.self)

        // 注册消息菜单操作 - Reply In Thread
        ReplyThreadMessageActionModule.register(MutePlayMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(RecallMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(ForwardMessageActionSubModuleInThread.self)
        ReplyThreadMessageActionModule.register(MultiSelectMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(FlagMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(FavoriteMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(TodoMessageActionSubModuleInReplyThread.self)
        ReplyThreadMessageActionModule.register(AudioPlayModeMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(AudioTextMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(SearchMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(TranslateMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(SelectTranslateMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(AddToStickerMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(MultiEditMessageActionSubModuleInThread.self)
        ReplyThreadMessageActionModule.register(ReplyMessageActionSubModuleInReplyInThread.self)
        ReplyThreadMessageActionModule.register(PinMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(ChatPinMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(UrgentMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(ToOriginalMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(ImageEditMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(ThreadReplyCopyMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(RestrictedMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(DeleteMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(ReplyThreadMessageLinkMessageActionSubModule.self)

        ReplyThreadMessageActionModule.register(ReplyThreadSaveToMessageActionModule.self)
        ReplyThreadSaveToMessageActionModule.register(FlagMessageActionSubModule.self)
        ReplyThreadSaveToMessageActionModule.register(FavoriteMessageActionSubModule.self)

        // 私有话题注册消息菜单
        PrivateThreadMessageActionModule.register(ForwardMessageActionSubModuleInThread.self)
        PrivateThreadMessageActionModule.register(MultiSelectMessageActionSubModule.self)
        PrivateThreadMessageActionModule.register(ThreadDetailCopyMessageActionSubModule.self)
        PrivateThreadMessageActionModule.register(FavoriteMessageActionSubModule.self)

        PrivateThreadMessageActionModule.register(PrivateThreadSaveToMessageActionModule.self)
        PrivateThreadSaveToMessageActionModule.register(FavoriteMessageActionSubModule.self)

        // 注册消息菜单操作 - 合并转发详情页
        MergeForwardMessageActionModule.register(MergeForwardDetailCopyMessageActionSubModule.self)
        MergeForwardMessageActionModule.register(TranslateMessageActionSubModuleInMergeForward.self)
        MergeForwardMessageActionModule.register(ForwardMessageActionSubModuleInMergeForward.self)

        // 注册消息菜单操作 - Pin列表
        PinListMessageActionModule.register(ChatCopyMessageActionSubModule.self)
        PinListMessageActionModule.register(PinMessageActionSubModule.self)
        PinListMessageActionModule.register(ChatPinMessageActionSubModule.self)
        PinListMessageActionModule.register(ForwardMessageActionSubModule.self)
        PinListMessageActionModule.register(JumpToChatActionSubModule.self)

        // 注册消息菜单操作 - 消息链接化详情页
        MessageLinkDetailActionModule.register(MergeForwardDetailCopyMessageActionSubModule.self)
        MessageLinkDetailActionModule.register(TranslateMessageActionSubModuleInMessageLink.self)

        // 在开发/测试环境下，允许用户在高级调试中使用debug按钮（复制chatid和msgid）
        #if DEBUG || ALPHA || BETA
        ChatMessageActionModule.register(DebugMessageActionSubModule.self)
        MessageDetailMessageActionModule.register(DebugMessageActionSubModule.self)
        ThreadMessageActionModule.register(DebugMessageActionSubModule.self)
        ThreadDetailMessageActionModule.register(DebugMessageActionSubModule.self)
        ReplyThreadMessageActionModule.register(DebugMessageActionSubModule.self)
        PrivateThreadMessageActionModule.register(DebugMessageActionSubModule.self)
        MessageLinkDetailActionModule.register(DebugMessageActionSubModule.self)
        MergeForwardMessageActionModule.register(DebugMessageActionSubModule.self)
        #endif

        /// TODO: 李洛斌 这里Thread是不是不需要注册 没有isMeeting
        ThreadNavigationBarModule.registerRightSubModule(CalendarChatNavigationBarSubModule.self)
        ThreadNavigationBarModule.registerLeftSubModule(ThreadNavigationBarSceneItemSubModule.self)

        NormalChatKeyboardModule.register(MessengerNormalChatKeyboardSubModule.self)
        ChatKeyboardTopExtendModule.register(HelpDeskKeyboardTopExtendSubModule.self)

        #if CCMMod
        NormalChatKeyboardModule.register(DocNormalChatKeyboardSubModule.self)
        NormalChatKeyboardModule.register(BitableChatKeyboardSubModule.self)
        #endif
        #if MeegoMod
        NormalChatKeyboardModule.register(WorkItemNormalChatKeyboardSubModule.self)
        #endif
        #if TodoMod
        NormalChatKeyboardModule.register(TodoNormalChatKeyboardSubModule.self)
        #endif
        #if CalendarMod
        NormalChatKeyboardModule.register(CalendarNormalChatKeyboardSubModule.self)
        #endif
        #if GagetMod
        // FIXME: 投票是否是强依赖需要始终保留？
        NormalChatKeyboardModule.register(MicroAppNormalChatKeyboardSubModule.self)
        #endif
        CryptoChatNavigationBarModule.registerRightSubModule(MessengerCryptoChatNavigationBarSubModule.self)
        CryptoChatNavigationBarModule.registerRightSubModule(ByteViewCryptoChatNavigationBarSubModule.self)
        CryptoChatNavigationBarModule.registerLeftSubModule(ChatNavigationBarLeftItemSubModule.self)
        CryptoChatNavigationBarModule.registerLeftSubModule(ChatNavigationBarSceneItemSubModule.self)
        CryptoChatNavigationBarModule.registerLeftSubModule(NavigationBarCloseSceneItemSubModule.self)
        CryptoChatNavigationBarModule.registerContentSubModule(CryptoChatNavigationBarContentSubModule.self)

        CryptoChatKeyboardModule.register(MessengerCryptoChatKeyboardSubModule.self)

        /// 键盘改造相关
        IMChatKeyboardModule.registerPanelSubModule(IMChatKeyboardEmojiPanelSubModule.self)
        IMChatKeyboardModule.registerPanelSubModule(IMChatKeyboardPicturePanelSubModule.self)
        IMChatKeyboardModule.registerPanelSubModule(IMChatKeyboardAtUserPanelSubModule.self)
        IMChatKeyboardModule.registerPanelSubModule(IMChatKeyboardVoicePanelSubModule.self)
        IMChatKeyboardModule.registerPanelSubModule(IMChatKeyboardFontPanelSubModule.self)
        IMChatKeyboardModule.registerPanelSubModule(IMChatKeyboardMorePanelSubModule.self)
        IMChatKeyboardModule.registerPanelSubModule(IMChatKeyboardCanvasPanelSubModule.self)
        IMChatKeyboardModule.registerPanelSubModule(IMChatKeyboardBurnTimePanelSubModule.self)

        IMCryptoChatKeyboardModule.registerPanelSubModule(IMCryptoChatKeyboardEmojiPanelSubModule.self)
        IMCryptoChatKeyboardModule.registerPanelSubModule(IMCryptoChatKeyboardPicturePanelSubModule.self)
        IMCryptoChatKeyboardModule.registerPanelSubModule(IMCryptoChatKeyboardAtUserPanelSubModule.self)
        IMCryptoChatKeyboardModule.registerPanelSubModule(IMCryptoChatKeyboardVoicePanelSubModule.self)
        IMCryptoChatKeyboardModule.registerPanelSubModule(IMCryptoChatKeyboardMorePanelSubModule.self)
        IMCryptoChatKeyboardModule.registerPanelSubModule(IMCryptoChatKeyboardBurnTimeSubModule.self)

        IMThreadKeyboardModule.registerPanelSubModule(NormalThreadKeyboardEmojiSubModule.self)
        IMMessageThreadKeyboardModule.registerPanelSubModule(MessageThreadKeyboardEmojiSubModule.self)

        IMThreadKeyboardModule.registerPanelSubModule(NormalThreadKeyboardPictureSubModule.self)
        IMMessageThreadKeyboardModule.registerPanelSubModule(MessageThreadKeyboardPictureSubModule.self)

        IMThreadKeyboardModule.registerPanelSubModule(ThreadKeyboardFontSubModule.self)
        IMMessageThreadKeyboardModule.registerPanelSubModule(ThreadKeyboardFontSubModule.self)

        IMThreadKeyboardModule.registerPanelSubModule(NormalThreadKeyboardVoiceSubModule.self)
        IMMessageThreadKeyboardModule.registerPanelSubModule(MessageThreadKeyboardVoiceSubModule.self)

        IMThreadKeyboardModule.registerPanelSubModule(ThreadKeyboardAtUserSubModule.self)
        IMMessageThreadKeyboardModule.registerPanelSubModule(MessageThreadKeyboardAtUserSubModule.self)

        IMThreadKeyboardModule.registerPanelSubModule(NormalThreadKeyboardCanvasSubModule.self)
        IMMessageThreadKeyboardModule.registerPanelSubModule(MessageThreadKeyboardCanvasSubModule.self)

        #if CCMMod
        CryptoChatKeyboardModule.register(DocCryptoChatKeyboardSubModule.self)
        #endif
    }
}
// nolint: long_function
