//
//  ChatViewControllerComponentGenerator.swift
//  LarkChat
//
//  Created by zc09v on 2020/2/13.
//

import Foundation
import UIKit
import Swinject
import LarkModel
import LarkCore
import LarkFeatureGating
import LarkSDKInterface
import LarkAccountInterface
import LarkMessengerInterface
import LarkMessageCore
import LarkAppLinkSDK
import LarkFeatureSwitch
import EENavigator
import LarkMessageBase
import LarkKAFeatureSwitch
import LarkAppConfig
import LarkReleaseConfig
import LarkNavigation
import LarkUIKit
import SuiteAppConfig
import RustPB
import LarkSceneManager
import LarkOpenChat
import AppContainer
import LarkBadge
import EditTextView
import LarkAttachmentUploader
import ByteWebImage
import FigmaKit
import UniverseDesignColor
import RxCocoa
import RxSwift
import LKCommonsLogging
import LarkContainer
import LarkSendMessage
import TangramService
import LarkFocus
import LarkOpenKeyboard
import LarkBaseKeyboard
import LarkChatOpenKeyboard
import LarkChatKeyboardInterface
import LarkCustomerService
import LarkSetting

protocol ChatViewControllerComponentGeneratorProtocol: NSObjectProtocol, UserResolverWrapper {
    var inSelectMode: Bool { get }
    var needCellVMGC: Bool { get }
    var supportUserUniversalLastPostionSetting: Bool { get }
    var fileDecodeService: RustEncryptFileDecodeService? { get }
    var chatDataProviderType: ChatDataProviderProtocol.Type { get }
    func chatPushWrapper(chat: Chat) -> ChatPushWrapper?
    func chatViewModel(pushWrapper: ChatPushWrapper) throws -> ChatViewModel
    func chatContainerViewModel(pushWrapper: ChatPushWrapper) -> ChatContainerViewModel
    func chatBanner(pushWrapper: ChatPushWrapper, context: ChatBannerContext) -> ChatBannerView?
    func needDisplayChatMenu(chat: Chat) -> Bool
    func chatMenu(pushWrapper: ChatPushWrapper, delegate: ChaMenutKeyboardDelegate, chatVC: UIViewController) -> ChatMenuBottomView?
    func pinSummaryView(pinSummaryContext: ChatPinSummaryContext, pushWrapper: ChatPushWrapper, chatVC: UIViewController) -> ChatPinSummaryContainerView?
    func widgetsView(moduleContext: ChatModuleContext, pushWrapper: ChatPushWrapper, targetVC: UIViewController) -> ChatWidgetsContainerView?
    func chatFooter(pushWrapper: ChatPushWrapper, context: LarkOpenChat.ChatFooterContext) -> ChatFooterView?
    func chatKeyboardTopExtendView(pushWrapper: ChatPushWrapper,
                                   context: ChatKeyboardTopExtendContext,
                                   delegate: ChatKeyboardTopExtendViewDelegate) -> ChatKeyboardTopExtendView?
    func timezoneView(chatNameObservable: Observable<String>) -> TimeZoneView?
    func backgroundImage(chat: Chat, pushChatTheme: Observable<ChatTheme>) -> ChatBackgroundImageView?
    func unreadMessagesTipViewModel(chatContext: ChatContext,
                                    chat: Chat,
                                    pushCenter: PushNotificationCenter,
                                    readPosition: Int32,
                                    lastMessagePosition: Int32) -> LarkMessageCore.BaseUnreadMessagesTipViewModel?
    func scheduleSendTipView(chatId: Int64,
                             threadId: Int64?,
                             rootId: Int64?,
                             scene: GetScheduleMessagesScene,
                             messageObservable: Observable<[LarkModel.Message]>,
                             sendEnable: Bool,
                             disableObservable: Observable<Bool>,
                             pushObservable: Observable<PushScheduleMessage>) -> ChatScheduleSendTipView?
    func statusDisplayView(chat: BehaviorRelay<Chat>, chatNameObservable: Observable<String>, urlPushObservable: Observable<URLPreviewScenePush>) -> StatusDisplayView?
    func chatMessageViewModel(pushWrapper: ChatPushWrapper,
                              pushHandlerRegister: ChatPushHandlersRegister,
                              context: ChatContext,
                              chatKeyPointTracker: ChatKeyPointTracker,
                              fromWhere: ChatFromWhere) throws -> ChatMessagesViewModel
    func chatMessagesVMDependency(pushWrapper: ChatPushWrapper,
                                  context: ChatContext,
                                  chatKeyPointTracker: ChatKeyPointTracker,
                                  fromWhere: ChatFromWhere) throws -> ChatMessagesVMDependency
    func canCreateKeyboard(chat: Chat) -> Bool
    func chatTableView(userResolver: UserResolver, pushWrapper: ChatPushWrapper, keepOffset: @escaping () -> Bool, fromWhere: ChatFromWhere) -> ChatTableView
    func keyboard(moduleContext: ChatModuleContext, delegate: ChatInputKeyboardDelegate,
                  chat: Chat, messageSender: @escaping () -> MessageSender,
                  chatKeyPointTracker: ChatKeyPointTracker) -> ChatInternalKeyboardService?

    // 注册时机更早，chat信息还未返回，只有context等信息
    func pageContainerRegister(chatId: String, context: ChatContext)
    // chat信息返回之后注册
    func pageContainerRegister(pushWrapper: ChatPushWrapper, context: ChatContext)
    func messageActionServiceRegister(pushWrapper: ChatPushWrapper, moduleContext: ChatModuleContext)
    func navigationBar(moduleContext: ChatModuleContext, pushWrapper: ChatPushWrapper, blurEnabled: Bool, targetVC: UIViewController, chatPath: Path) -> ChatNavigationBar
    func instantChatNavigationBar() -> InstantChatNavigationBar
    func instantKeyboard() -> InstantChatKeyboard
    func placeholderChatView() -> PlaceholderChatView?
    func messagesDataSource(pushWrapper: ChatPushWrapper, context: ChatContext) throws -> ChatMessagesDatasource
    func guideManager(chatBaseVC: ChatMessagesViewController) -> ChatBaseGuideManager?
    func needDisplayTabs(chat: Chat) -> Bool
    func suspendIcon(chat: Chat) -> UIImage?
    func topBlurView(chat: Chat) -> BackgroundBlurView
    func chatFirstMessagePositionDriver(pushWrapper: ChatPushWrapper) -> Driver<Void>?
    func messageSelectControl(chat: SelectControlHostController) -> MessageSelectControl?
    func createThreadPanel(hasChatMenuItem: Bool, pushWrapper: ChatPushWrapper) -> ChatCreateThreadPanel?
    func createChatFrozenMask() -> UIView?
    func messageSender(chat: BehaviorRelay<Chat>, context: ChatContext, chatKeyPointTracker: ChatKeyPointTracker, fromWhere: ChatFromWhere) -> MessageSender
}

extension ChatViewControllerComponentGeneratorProtocol {
    var chatDataProviderType: ChatDataProviderProtocol.Type { return NormalChatDataProvider.self }

    var fileDecodeService: RustEncryptFileDecodeService? {
        return nil
    }

    func chatPushWrapper(chat: Chat) -> ChatPushWrapper? {
        return try? resolver.resolve(assert: ChatPushWrapper.self, argument: chat)
    }

    func chatContainerViewModel(pushWrapper: ChatPushWrapper) -> ChatContainerViewModel {
        return ChatContainerViewModel(userResolver: userResolver, chatWrapper: pushWrapper)
    }

    func chatViewModel(pushWrapper: ChatPushWrapper) throws -> ChatViewModel {
        let pushCenter = try resolver.userPushCenter
        let chatVMDependency = try ChatVMDependency(
            userResolver: userResolver,
            chat: pushWrapper.chat.value)
        return ChatViewModel(dependency: chatVMDependency, chatWrapper: pushWrapper)
    }

    func messageActionServiceRegister(pushWrapper: ChatPushWrapper, moduleContext: ChatModuleContext) {
    }

    func instantChatNavigationBar() -> InstantChatNavigationBar {
        let view = InstantChatNavigationBar(isDark: false)
        return view
    }

    func instantKeyboard() -> InstantChatKeyboard {
        return NormalInstantChatKeyboard()
    }

    func placeholderChatView() -> PlaceholderChatView? {
        return PlaceholderChatView(isDark: false,
                                   title: BundleI18n.LarkChat.Lark_IM_RestrictedMode_ScreenRecordingEmptyState_Text,
                                   subTitle: BundleI18n.LarkChat.Lark_IM_RestrictedMode_ScreenRecordingEmptyState_Desc)
    }

    func chatTableView(userResolver: UserResolver, pushWrapper: ChatPushWrapper, keepOffset: @escaping () -> Bool, fromWhere: ChatFromWhere) -> ChatTableView {
        return ChatTableView(userResolver: userResolver,
                             isOnlyReceiveScroll: pushWrapper.chat.value.isTeamVisitorMode,
                             keepOffset: keepOffset,
                             chatFromWhere: fromWhere)
    }

    func chatBanner(pushWrapper: ChatPushWrapper, context: ChatBannerContext) -> ChatBannerView? {
        return nil
    }

    func chatFooter(pushWrapper: ChatPushWrapper, context: LarkOpenChat.ChatFooterContext) -> ChatFooterView? {
        return nil
    }

    func chatKeyboardTopExtendView(pushWrapper: ChatPushWrapper,
                                   context: ChatKeyboardTopExtendContext,
                                   delegate: ChatKeyboardTopExtendViewDelegate) -> ChatKeyboardTopExtendView? {
        return nil
    }

    func statusDisplayView(chat: BehaviorRelay<Chat>, chatNameObservable: Observable<String>, urlPushObservable: Observable<URLPreviewScenePush>) -> StatusDisplayView? {
        nil
    }

    func scheduleSendTipView(chatId: Int64,
                             threadId: Int64?,
                             rootId: Int64?,
                             scene: GetScheduleMessagesScene,
                             messageObservable: Observable<[LarkModel.Message]>,
                             sendEnable: Bool,
                             disableObservable: Observable<Bool>,
                             pushObservable: Observable<PushScheduleMessage>) -> ChatScheduleSendTipView? {
        nil
    }

    func backgroundImage(chat: Chat, pushChatTheme: Observable<ChatTheme>) -> ChatBackgroundImageView? {
        nil
    }

    func suspendIcon(chat: Chat) -> UIImage? {
        switch chat.type {
        case .p2P:
            if chat.chatter?.type == .bot {
                return Resources.suspend_icon_bot
            } else {
                return Resources.suspend_icon_chat
            }
        case .group, .topicGroup:
            return Resources.suspend_icon_group
        @unknown default:
            return Resources.suspend_icon_chat
        }
    }

    func topBlurView(chat: Chat) -> BackgroundBlurView {
        let topBlurView = BackgroundBlurView()
        topBlurView.blurRadius = 50
        topBlurView.backgroundColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.75) & UIColor.ud.staticBlack.withAlphaComponent(0.75)
        if self.userResolver.fg.staticFeatureGatingValue(with: ChatNewPinConfig.pinnedUrlKey) {
            let line = UIView()
            line.backgroundColor = UIColor.ud.lineDividerDefault
            topBlurView.addSubview(line)
            line.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalTo(0.5)
            }
        }
        return topBlurView
    }

    func unreadMessagesTipViewModel(chatContext: ChatContext,
                                    chat: Chat,
                                    pushCenter: PushNotificationCenter,
                                    readPosition: Int32,
                                    lastMessagePosition: Int32) -> LarkMessageCore.BaseUnreadMessagesTipViewModel? {
        guard let messageAPI = try? userResolver.resolve(type: MessageAPI.self) else { return nil }
        return DownUnReadMessagesTipViewModel(
            userResolver: userResolver,
            chatId: chat.id,
            readPosition: readPosition,
            lastMessagePosition: lastMessagePosition,
            messageAPI: messageAPI,
            pushCenter: pushCenter
        )
    }

    func chatFirstMessagePositionDriver(pushWrapper: ChatPushWrapper) -> Driver<Void>? { return nil }

    func createThreadPanel(hasChatMenuItem: Bool, pushWrapper: ChatPushWrapper) -> ChatCreateThreadPanel? { return nil }

    func createChatFrozenMask() -> UIView? { return nil }

    func messageSender(chat: BehaviorRelay<Chat>, context: ChatContext, chatKeyPointTracker: ChatKeyPointTracker, fromWhere: ChatFromWhere) -> MessageSender {
        let sender = MessageSender(userResolver: self.userResolver, actionPosition: .chat, chatInfo: chatKeyPointTracker.chatInfo, chat: chat)
        sender.addModifier(modifier: DisplayModeModifier(chat: chat))
        sender.addModifier(modifier: ChatFromModifier(fromWhere: fromWhere))
        return sender
    }
}

class ChatViewControllerComponentGenerator: NSObject, ChatViewControllerComponentGeneratorProtocol {
    var chatDataProviderType: ChatDataProviderProtocol.Type { return NormalChatDataProvider.self }

    static let logger = Logger.log(ChatViewControllerComponentGenerator.self, category: "Module.IM.ChatViewControllerComponentGenerator")
    let userResolver: UserResolver
    let inSelectMode: Bool = false
    let needCellVMGC: Bool = true
    let supportUserUniversalLastPostionSetting: Bool = true

    @ScopedInjectedLazy private var p2PBotMenuConfigService: ChatP2PBotMenuConfigService?

    let navBarConfigImp: ChatNavigationBarConfigServiceIMP

    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.navBarConfigImp = ChatNavigationBarConfigServiceIMP(fg: userResolver.fg)
    }

    func instantChatNavigationBar() -> InstantChatNavigationBar {
        let view = InstantChatNavigationBar(isDark: false, leftStyle: navBarConfigImp.showLeftStyle)
        return view
    }

    func chatMessageViewModel(pushWrapper: ChatPushWrapper,
                              pushHandlerRegister: ChatPushHandlersRegister,
                              context: ChatContext,
                              chatKeyPointTracker: ChatKeyPointTracker,
                              fromWhere: ChatFromWhere) throws -> ChatMessagesViewModel {
        let chatMessagesVMDependency = try self.chatMessagesVMDependency(pushWrapper: pushWrapper,
                                                                         context: context,
                                                                         chatKeyPointTracker: chatKeyPointTracker,
                                                                         fromWhere: fromWhere)
        let pushCenter = try resolver.userPushCenter
        let chatDataProvider = chatDataProviderType.init(chatContext: context, chatWrapper: pushWrapper, pushCenter: pushCenter)
        let chatMessagesViewModel = ChatMessagesViewModel(userResolver: userResolver,
                                                          messagesDatasource: try self.messagesDataSource(pushWrapper: pushWrapper,
                                                                                                          context: context),
                                                          chatDataContext: NormalChatDataContext(chatWrapper: pushWrapper),
                                                          chatDataProvider: chatDataProvider,
                                                          dependency: chatMessagesVMDependency,
                                                          context: context,
                                                          chatWrapper: pushWrapper,
                                                          pushHandlerRegister: pushHandlerRegister,
                                                          inSelectMode: inSelectMode,
                                                          supportUserUniversalLastPostionSetting: supportUserUniversalLastPostionSetting,
                                                          gcunit: needCellVMGC
                                                          ? GCUnit(limitWeight: 256, limitGCRoundSecondTime: 10, limitGCMSCost: 100)
                                                          : nil
        )
        return chatMessagesViewModel
    }

    func chatTableView(userResolver: UserResolver, pushWrapper: ChatPushWrapper, keepOffset: @escaping () -> Bool, fromWhere: ChatFromWhere) -> ChatTableView {
        return ChatTableView(userResolver: userResolver,
                             isOnlyReceiveScroll: pushWrapper.chat.value.isTeamVisitorMode,
                             keepOffset: keepOffset,
                             chatFromWhere: fromWhere)
    }

    func messagesDataSource(pushWrapper: ChatPushWrapper, context: ChatContext) throws -> ChatMessagesDatasource {
        let messageBurnService = try? self.resolver.resolve(type: MessageBurnService.self)
        let messageCellProcessor = NormalChatMessageDatasourceProcessor(isNewRecalledEnable: context.isNewRecallEnable)
        let datasource = ChatMessagesDatasource(
            chat: {
                return pushWrapper.chat.value
            },
            vmFactory: NormalChatCellViewModelFactory(
                context: context,
                registery: ChatMessageSubFactoryRegistery(
                    context: context, defaultFactory: UnknownContentFactory(context: context)
                ),
                cellLifeCycleObseverRegister: NormalChatCellLifeCycleObseverRegister(userResolver: userResolver)
            ),
            isMessageBurned: { message in
                return messageBurnService?.isBurned(message: message) ?? false
            },
            messageCellProcessor: messageCellProcessor
        )
        messageCellProcessor.dependency = datasource
        return datasource
    }

    func chatMessagesVMDependency(pushWrapper: ChatPushWrapper,
                                  context: ChatContext,
                                  chatKeyPointTracker: ChatKeyPointTracker,
                                  fromWhere: ChatFromWhere) throws -> ChatMessagesVMDependency {
        let chat = pushWrapper.chat.value
        let currentChatterID = userResolver.userID
        let audioToTextEnable = userResolver.fg.staticFeatureGatingValue(with: .init(key: .audioToTextEnable)) &&
                                userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteVoice2Text))
        let readService = try self.readService(pushWrapper: pushWrapper,
                                               context: context,
                                               audioToTextEnable: audioToTextEnable,
                                               fromWhere: fromWhere)
        let urlPreviewService = try? self.resolver.resolve(type: MessageURLPreviewService.self)

        let chatMessagesVMDependency = ChatMessagesVMDependency(
            userResolver: userResolver,
            channelId: chat.id,
            currentChatterID: currentChatterID,
            audioShowTextEnable: audioToTextEnable,
            chatKeyPointTracker: chatKeyPointTracker,
            readService: readService,
            urlPreviewService: urlPreviewService,
            processMessageSelectedEnable: { message in
                if fromWhere == .singleChatGroup,
                   (message.type == .hongbao || message.type == .commercializedHongbao) {
                    return false
                }
                return true
            },
            getFeatureIntroductions: {
                return []
            }
        )
        return chatMessagesVMDependency
    }

    func readService(pushWrapper: ChatPushWrapper,
                     context: ChatContext,
                     audioToTextEnable: Bool,
                     fromWhere: ChatFromWhere) throws -> ChatMessageReadService {
        let chat = pushWrapper.chat.value
        var channel = RustPB.Basic_V1_Channel()
        channel.id = chat.id
        channel.type = .chat
        let forceNotEnabled = chat.isTeamVisitorMode
        let messageAPI = try self.resolver.resolve(assert: MessageAPI.self)
        let threadAPI = try self.resolver.resolve(assert: ThreadAPI.self)
        return try self.resolver.resolve( // user:checked
            assert: ChatMessageReadService.self,
            arguments: PutReadScene.chat(chat),
            forceNotEnabled,
            audioToTextEnable,
            chat.isRemind,
            chat.isInBox,
            ["chat": chat,
             "chatFromWhere": fromWhere.rawValue] as [String: Any], { () -> Int32 in
                return pushWrapper.chat.value.readPosition
            }, { (info: PutReadInfo) in
                let messageIDs = info.ids.map { (chatIDAndMessageID) -> String in
                    return chatIDAndMessageID.messageID
                }

                messageAPI.putReadMessages(
                    channel: channel,
                    messageIds: messageIDs,
                    maxPosition: info.maxPosition,
                    maxPositionBadgeCount: info.maxBadgeCount,
                    foldIds: info.foldIds)
            }
        )
    }

    func navigationBar(moduleContext: ChatModuleContext, pushWrapper: ChatPushWrapper, blurEnabled: Bool, targetVC: UIViewController, chatPath: Path) -> ChatNavigationBar {
        ChatNavigationBarModule.onLoad(context: moduleContext.navigaionContext)
        ChatNavigationBarModule.registGlobalServices(container: moduleContext.container)
        let navigationBarModule: BaseChatNavigationBarModule = ChatNavigationBarModule(context: moduleContext.navigaionContext)
        /// 页面级别服务
        let imp = self.navBarConfigImp
        moduleContext.container.register(ChatNavigationBarConfigService.self) { _ in imp }
        let viewModel = ChatNavigationBarViewModel(
            chatWrapper: pushWrapper,
            module: navigationBarModule
        )
        let navBar = ChatNavigationBarImp(viewModel: viewModel, blurEnabled: blurEnabled, darkStyle: false)
        return navBar
    }

    func canCreateKeyboard(chat: Chat) -> Bool {
        let openApp = chat.chatter?.openApp
        Self.logger.info("isKeyboardHidden: chatID = \(chat.id), chatable = \(chat.chatable), openApp = \(openApp?.chatable.rawValue)")
        let isKeyboardHidden = !chat.chatable || (openApp != nil && openApp?.chatable == .unchatable)
        return !isKeyboardHidden
    }

    func keyboard(moduleContext: ChatModuleContext,
                      delegate: ChatInputKeyboardDelegate,
                      chat: LarkModel.Chat,
                      messageSender: @escaping () -> MessageSender,
                      chatKeyPointTracker: LarkMessageCore.ChatKeyPointTracker) -> ChatInternalKeyboardService? {
        let sendService = ChatKeyboardMessageSendServiceIMP(messageSender: messageSender)
        moduleContext.container.register(KeyboardSendMessageKeyPointTrackerService.self) { _ in
            return chatKeyPointTracker
        }

        moduleContext.container.register(AIQuickActionSendService.self) { _ in
            return sendService
        }
        let chatKeyboard = try? self.userResolver.resolve(assert: ChatInputKeyboardService.self)
        let voiceConfig = ChatKeyboardVoiceItemConfig(uiConfig: KeyboardVoiceUIConfig(supprtVoiceToText: true, tappedBlock: nil),
                                                      sendConfig: KeyboardVoiceSendConfig(sendService: sendService))

        let emojiConfig = ChatKeyboardEmojiItemConfig(uiConfig: KeyboardEmojiUIConfig(supportSticker: true, tappedBlock: nil), sendConfig: KeyboardEmojiSendConfig(sendService: sendService))

        let pictureItem = ChatKeyboardPictureItemConfig(uiConfig: KeyboardPictureUIConfig(tappedBlock: nil),
                                                        sendConfig: KeyboardPictureSendConfig(sendService: sendService))

        let burnTime = ChatKeyboardBurnTimeItemConfig(uiConfig: KeyboardUIConfig(tappedBlock: nil),
                                                      sendConfig: nil)

        let canvasItem = ChatKeyboardCanvasItemConfig(uiConfig: nil,
                                                      sendConfig: KeyboardCanvasSendConfig(sendService: sendService))

        let moreItem = ChatMoreKeyboardItemConfig(uiConfig: KeyboardMoreUIConfig(blacklist: [], tappedBlock: nil),
                                                  sendConfig: KeyboardMoreSendConfig(sendService: sendService))
        let dataConfig = ChatOpenKeyboardConfig.DataConfig(chat: chat,
                                                           context: moduleContext.keyboardContext,
                                                           userResolver: self.userResolver,
                                                           copyPasteToken: "LARK-PSDA-messenger-chat-keyboard-input-permission",
                                                           delegate: delegate,
                                                           sendService: sendService,
                                                           items: [voiceConfig,
                                                                   emojiConfig,
                                                                   pictureItem,
                                                                   canvasItem,
                                                                   burnTime,
                                                                   moreItem])
        let abilityConfig = ChatOpenKeyboardConfig.AbilityConfig(supportRichTextEdit: true,
                                                                 supportRealTimeTranslate: true,
                                                                 supportAfterMessagesRender: true,
                                                                 supportAtMyAI: true)
        let config = ChatOpenKeyboardConfig(dataConfig: dataConfig, abilityConfig: abilityConfig)
        chatKeyboard?.loadChatKeyboardViewWithConfig(config)
        moduleContext.container.register(MyAIQuickActionSendService.self) { [weak chatKeyboard] (_) -> MyAIQuickActionSendService in
            return chatKeyboard?.myAIQuickActionSendService ?? MyAIQuickActionSendServiceEmptyImpl()
        }
        sendService.getReplyInfoForMessage = { [weak chatKeyboard] (message) in
            /// 如果回复的消息和局部回复的MessageId一致 才可以获取到局部的回复信息
            if let message = message,
               let info = chatKeyboard?.getReplyMessageInfo(),
               info.message.id == message.id {
                return info.partialReplyInfo
            }
            return nil
        }
        return chatKeyboard
    }

    func messageActionServiceRegister(pushWrapper: ChatPushWrapper, moduleContext: ChatModuleContext) {
        ChatMessageActionModule.onLoad(context: moduleContext.messageActionContext)
        let actionModule = ChatMessageActionModule(context: moduleContext.messageActionContext)
        let messageMenuService: MessageMenuOpenService = MessageMenuServiceImp(pushWrapper: pushWrapper, actionModule: actionModule)
        // 处理内存泄漏临时解法: OpenIM和PageContainer两个容器没有打通, ChatPinService需要也被OpenIM持有
        if let chatPinservice = moduleContext.chatContext.pageContainer.resolve(ChatPinPageService.self) {
            moduleContext.container.register(ChatPinPageService.self) { _ in
                return chatPinservice
            }
        }
        moduleContext.chatContext.pageContainer.register(MessageMenuOpenService.self) {
            return messageMenuService
        }
    }

    func pageContainerRegister(chatId: String, context: ChatContext) {
        let resolver = self.userResolver
        context.pageContainer.register(ChatPinPageService.self) { [weak context] in
            return ChatPinPageService(chatID: chatId, pageContext: context)
        }
        if let pushCenter = try? resolver.userPushCenter {
            context.pageContainer.register(MessageURLTemplateService.self) { [weak context] in
                return MessageURLTemplateService(context: context, pushCenter: pushCenter)
            }
        }
        context.pageContainer.register(ChatScreenProtectService.self) { [weak context] in
            let service = ChatScreenProtectService(chatId: chatId,
                                                   getTargetVC: { [weak context] in return context?.pageAPI },
                                                   userResolver: resolver)
            return service
        }
    }

    func pageContainerRegister(pushWrapper: ChatPushWrapper, context: ChatContext) {
        let resolver = self.resolver
        let chat = pushWrapper.chat.value
        context.pageContainer.register(ReactionPageService.self) {
            return ReactionPageService(service: try? resolver.resolve(assert: ReactionService.self))
        }
        if let dep = try? resolver.resolve(assert: DocPreviewViewModelContextDependency.self) {
            context.pageContainer.register(DocChatLifeCycleService.self) {
                return DocChatLifeCycleService(dependency: dep)
            }
        }
        // 用户关系的页面服务
        context.pageContainer.register(UserRelationPageService.self) {
            return UserRelationPageService(chat: chat, userRelationService: try? resolver.resolve(assert: UserRelationService.self))
        }

        if self.userResolver.fg.dynamicFeatureGatingValue(with: "messenger.customer.service.bot") {
            context.pageContainer.register(CustomerChatPageService.self) {
                return CustomerChatPageService(chat: chat, customerService: try? resolver.resolve(assert: LarkCustomerServiceAPI.self))
            }
        }

        if let translateService = try? self.userResolver.resolve(assert: NormalTranslateService.self), translateService.enableDetachResultDic() {
            context.pageContainer.register(TranslateLifeCycleService.self) {
                return TranslateLifeCycleService(translateService: translateService)
            }
        }
    }

    func chatBanner(pushWrapper: ChatPushWrapper, context: ChatBannerContext) -> ChatBannerView? {

        ChatBannerModule.onLoad(context: context)
        ChatBannerModule.registGlobalServices(container: context.container)
        return ChatBannerView(bannerModule: ChatBannerModule(context: context), chatWrapper: pushWrapper)
    }

    func chatFooter(pushWrapper: ChatPushWrapper, context: LarkOpenChat.ChatFooterContext) -> ChatFooterView? {

        ChatFooterModule.onLoad(context: context)
        ChatFooterModule.registGlobalServices(container: context.container)
        return ChatFooterView(footerModule: ChatFooterModule(context: context), chatWrapper: pushWrapper)
    }

    func needDisplayChatMenu(chat: Chat) -> Bool {
        guard self.canCreateChatMenu(chat: chat) else { return false }
        if chat.type == .p2P, chat.chatter?.type == .bot {
            if let chatId = Int64(chat.id),
               self.p2PBotMenuConfigService?.shouldShowMenu(chatId) == true {
                return true
            }
            return false
        } else {
            if case .chatMenu = chat.defDisplaySetting {
                return true
            }
            return false
        }
    }

    func scheduleSendTipView(chatId: Int64,
                             threadId: Int64?,
                             rootId: Int64?,
                             scene: GetScheduleMessagesScene,
                             messageObservable: Observable<[LarkModel.Message]>,
                             sendEnable: Bool,
                             disableObservable: Observable<Bool>,
                             pushObservable: Observable<PushScheduleMessage>) -> ChatScheduleSendTipView? {

        let vm = ChatScheduleSendTipViewModel(chatId: chatId,
                                              threadId: threadId,
                                              rootId: rootId,
                                              scene: scene,
                                              messageObservable: messageObservable,
                                              sendEnable: sendEnable,
                                              disableObservable: disableObservable,
                                              pushObservable: pushObservable,
                                              userResolver: self.userResolver)
        return ChatScheduleSendTipView(viewModel: vm)
    }

    func timezoneView(chatNameObservable: Observable<String>) -> TimeZoneView? {
        let fg = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "im.setting.external_display_timezone"))
        return fg ? NewChatTimezoneView(userResolver: userResolver, chatNameObservable: chatNameObservable) : ChatTimezoneView()
    }

    func statusDisplayView(chat: BehaviorRelay<Chat>, chatNameObservable: Observable<String>, urlPushObservable: Observable<URLPreviewScenePush>) -> StatusDisplayView? {
        let selfId = userResolver.userID
        let focusManager = try? resolver.resolve(assert: FocusManager.self)
        guard chat.value.type == .p2P,
              !chat.value.isPrivateMode,
              chat.value.chatterId != selfId,
              focusManager?.isStatusNoteEnabled ?? false,
            let chatStatusTipNotifyDriver = try? resolver.userPushCenter.driver(for: PushChatStatusTipNotify.self)
        else { return nil }
        return StatusDisplayView(userResolver: userResolver, chat: chat,
                                 chatNameObservable: chatNameObservable,
                                 urlPushObservable: urlPushObservable,
                                 chatStatusTipNotifyDriver: chatStatusTipNotifyDriver)
    }

    func backgroundImage(chat: Chat, pushChatTheme: Observable<ChatTheme>) -> ChatBackgroundImageView? {
        // 密盾聊不支持
        if chat.isPrivateMode { return nil }
        let isOriginMode = chat.theme?.backgroundEntity.mode == .originMode
        let view = ChatBackgroundImageView(chatId: chat.id, isOriginMode: isOriginMode, pushChatTheme: pushChatTheme)
        return view
    }

    func unreadMessagesTipViewModel(chatContext: ChatContext,
                                    chat: Chat,
                                    pushCenter: PushNotificationCenter,
                                    readPosition: Int32,
                                    lastMessagePosition: Int32) -> LarkMessageCore.BaseUnreadMessagesTipViewModel? {
        guard let messageAPI = try? userResolver.resolve(type: MessageAPI.self) else { return nil }
        return DownUnReadMessagesTipViewModel(
            userResolver: userResolver,
            chatId: chat.id,
            readPosition: readPosition,
            lastMessagePosition: lastMessagePosition,
            messageAPI: messageAPI,
            pushCenter: pushCenter
        )
    }

    func widgetsView(moduleContext: ChatModuleContext, pushWrapper: ChatPushWrapper, targetVC: UIViewController) -> ChatWidgetsContainerView? {
        if ChatNewPinConfig.checkEnable(chat: pushWrapper.chat.value, self.userResolver.fg) {
            return nil
        }
        let chat = pushWrapper.chat.value
        if Display.pad || !AppConfigManager.shared.feature(for: .chatMenu).isOn { return nil }
        if chat.isSuper || chat.isPrivateMode || !userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "im.chat.top.widget")) { return nil }

        ChatWidgetModule.onLoad(context: moduleContext.widgetContext)
        ChatWidgetModule.registGlobalServices(container: moduleContext.container)
        let widgetModule = ChatWidgetModule(context: moduleContext.widgetContext)

        let viewModel = ChatWidgetsViewModel(
            widgetModule: widgetModule,
            chatWrapper: pushWrapper
        )
        moduleContext.container.register(ChatOpenWidgetService.self) { [weak viewModel] (_) -> ChatOpenWidgetService in
            return viewModel ?? DefaultChatOpenWidgetServiceImp()
        }
        let widgetsView = ChatWidgetsContainerView(viewModel: viewModel)
        widgetsView.targetVC = targetVC
        return widgetsView
    }

    func canCreateChatMenu(chat: Chat) -> Bool {
        if !AppConfigManager.shared.feature(for: .chatMenu).isOn { return false }
        if chat.isSuper || chat.isPrivateMode || !userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "im.chat.input.menu")) { return false }
        return true
    }

    func chatMenu(pushWrapper: ChatPushWrapper, delegate: ChaMenutKeyboardDelegate, chatVC: UIViewController) -> ChatMenuBottomView? {
        let chat = pushWrapper.chat.value
        guard self.canCreateChatMenu(chat: chat) else { return nil }
        guard let chatId = Int64(chat.id) else { return nil }
        guard let vm = try? ChatMenuViewModel(
            userResolver: userResolver,
            chatId: chatId,
            getChat: { return pushWrapper.chat.value },
            chatVC: chatVC
        ) else { return nil }
        return ChatMenuBottomView(
            vm: vm,
            delegate: delegate,
            hasKeyboardEntry: self.canCreateKeyboard(chat: chat),
            chatVC: chatVC
        )
    }

    func pinSummaryView(pinSummaryContext: ChatPinSummaryContext, pushWrapper: ChatPushWrapper, chatVC: UIViewController) -> ChatPinSummaryContainerView? {
        guard ChatNewPinConfig.checkEnable(chat: pushWrapper.chat.value, self.userResolver.fg) else {
            return nil
        }

        ChatPinSummaryModule.onLoad(context: pinSummaryContext)
        ChatPinSummaryModule.registGlobalServices(container: pinSummaryContext.container)
        let summaryModule = ChatPinSummaryModule(context: pinSummaryContext)
        let pinAndTopNoticeViewModel = ChatPinAndTopNoticeViewModel(userResolver: pinSummaryContext.userResolver, chatId: pushWrapper.chat.value.id)
        let viewModel = ChatPinSummaryContainerViewModel(
            userResolver: userResolver,
            chat: pushWrapper.chat,
            summaryModule: summaryModule,
            pinAndTopNoticeViewModel: pinAndTopNoticeViewModel,
            targetVC: chatVC
        )
        pinSummaryContext.container.register(ChatOpenPinSummaryService.self) { [weak viewModel] (_) -> ChatOpenPinSummaryService in
            return viewModel ?? DefaultChatOpenPinSummaryServiceImp()
        }
        return ChatPinSummaryContainerView(targetVC: chatVC,
                                           supportLeftLayout: self.userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.left.aligned.pin"),
                                           displayTotalCount: !self.userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.pin.count"),
                                           viewModel: viewModel)

    }

    func chatKeyboardTopExtendView(pushWrapper: ChatPushWrapper,
                                   context: ChatKeyboardTopExtendContext,
                                   delegate: ChatKeyboardTopExtendViewDelegate) -> ChatKeyboardTopExtendView? {
        ChatKeyboardTopExtendModule.onLoad(context: context)
        ChatKeyboardTopExtendModule.registGlobalServices(container: context.container)
        return ChatKeyboardTopExtendView(topExtendModule: ChatKeyboardTopExtendModule(context: context), chatWrapper: pushWrapper, delegate: delegate)
    }

    func guideManager(chatBaseVC: ChatMessagesViewController) -> ChatBaseGuideManager? {
        return ChatBaseGuideManager(chatBaseVC: chatBaseVC)
    }

    func needDisplayTabs(chat: Chat) -> Bool {
        if ChatNewPinConfig.checkEnable(chat: chat, self.userResolver.fg) {
            return false
        }
        if chat.isPrivateMode { return false }
        if !chat.isOncall,
           userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: FeatureGatingKey.enableChatTab)) {
            if chat.isTeamVisitorMode {
                return false
            } else {
                return true
            }
        }
        return false
    }

    func chatFirstMessagePositionDriver(pushWrapper: ChatPushWrapper) -> Driver<Void>? {
        pushWrapper.chat
            .distinctUntilChanged { (chat1, chat2) -> Bool in
                return chat1.firstMessagePostion == chat2.firstMessagePostion
            }
            .skip(1)
            .map { _ -> Void in return }
            .asDriver(onErrorJustReturn: ())
    }

    func messageSelectControl(chat: SelectControlHostController) -> MessageSelectControl? {
        return MessageSelectControl(chat: chat, pasteboardToken: "LARK-PSDA-messenger-chat-select-copyCommand-permission")
    }

    func createThreadPanel(hasChatMenuItem: Bool, pushWrapper: ChatPushWrapper) -> ChatCreateThreadPanel? {
        return ChatCreateThreadPanel(hasChatMenuItem: hasChatMenuItem, chatWrapper: pushWrapper)
    }

    func createChatFrozenMask() -> UIView? {
        return ChatFrozenMask()
    }

    // 这里虽然和默认实现逻辑一致，否则子类MyAIChatModeViewControllerComponentGenerator 的 override不会调用
    func messageSender(chat: BehaviorRelay<Chat>, context: ChatContext, chatKeyPointTracker: ChatKeyPointTracker, fromWhere: ChatFromWhere) -> MessageSender {
        let sender = MessageSender(userResolver: self.userResolver, actionPosition: .chat, chatInfo: chatKeyPointTracker.chatInfo, chat: chat)
        sender.addModifier(modifier: DisplayModeModifier(chat: chat))
        sender.addModifier(modifier: ChatFromModifier(fromWhere: fromWhere))
        return sender
    }
}

final class MessagePickerViewControllerComponentGenerator: NSObject, ChatViewControllerComponentGeneratorProtocol {
    func chatMessageViewModel(pushWrapper: ChatPushWrapper,
                              pushHandlerRegister: ChatPushHandlersRegister,
                              context: ChatContext,
                              chatKeyPointTracker: ChatKeyPointTracker,
                              fromWhere: ChatFromWhere) throws -> ChatMessagesViewModel {
        let chatMessagesVMDependency = try self.chatMessagesVMDependency(pushWrapper: pushWrapper,
                                                                         context: context,
                                                                         chatKeyPointTracker: chatKeyPointTracker,
                                                                         fromWhere: fromWhere)
        let pushCenter = try resolver.userPushCenter
        let chatDataProvider = chatDataProviderType.init(chatContext: context, chatWrapper: pushWrapper, pushCenter: pushCenter)
        let chatMessagesViewModel = ChatMessagesViewModel(userResolver: userResolver,
                                                          messagesDatasource: try self.messagesDataSource(pushWrapper: pushWrapper,
                                                                                                          context: context),
                                                          chatDataContext: NormalChatDataContext(chatWrapper: pushWrapper),
                                                          chatDataProvider: chatDataProvider,
                                                          dependency: chatMessagesVMDependency,
                                                          context: context,
                                                          chatWrapper: pushWrapper,
                                                          pushHandlerRegister: pushHandlerRegister,
                                                          inSelectMode: inSelectMode,
                                                          supportUserUniversalLastPostionSetting: supportUserUniversalLastPostionSetting,
                                                          gcunit: needCellVMGC
                                                          ? GCUnit(limitWeight: 256, limitGCRoundSecondTime: 10, limitGCMSCost: 100)
                                                          : nil
        )
        return chatMessagesViewModel
    }

    func messagesDataSource(pushWrapper: ChatPushWrapper, context: ChatContext) throws -> ChatMessagesDatasource {
        let messageBurnService = try? self.resolver.resolve(type: MessageBurnService.self)
        let messageCellProcessor = NormalChatMessageDatasourceProcessor(isNewRecalledEnable: context.isNewRecallEnable)
        let datasource = ChatMessagesDatasource(
            chat: {
                return pushWrapper.chat.value
            },
            vmFactory: NormalChatCellViewModelFactory(
                context: context,
                registery: ChatMessageSubFactoryRegistery(
                    context: context, defaultFactory: UnknownContentFactory(context: context)
                ),
                cellLifeCycleObseverRegister: NormalChatCellLifeCycleObseverRegister(userResolver: userResolver)
            ),
            isMessageBurned: { message in
                return messageBurnService?.isBurned(message: message) ?? false
            },
            messageCellProcessor: messageCellProcessor
        )
        messageCellProcessor.dependency = datasource
        return datasource
    }

    func chatMessagesVMDependency(pushWrapper: ChatPushWrapper,
                                  context: ChatContext,
                                  chatKeyPointTracker: ChatKeyPointTracker,
                                  fromWhere: ChatFromWhere) throws -> ChatMessagesVMDependency {
        let chat = pushWrapper.chat.value
        let currentChatterID = userResolver.userID
        let audioToTextEnable = userResolver.fg.staticFeatureGatingValue(with: .init(key: .audioToTextEnable)) &&
                                userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteVoice2Text))
        let readService = try self.readService(pushWrapper: pushWrapper,
                                               context: context,
                                               audioToTextEnable: audioToTextEnable,
                                               fromWhere: fromWhere)
        let urlPreviewService = try? self.resolver.resolve(type: MessageURLPreviewService.self)

        let chatMessagesVMDependency = ChatMessagesVMDependency(
            userResolver: userResolver,
            channelId: chat.id,
            currentChatterID: currentChatterID,
            audioShowTextEnable: audioToTextEnable,
            chatKeyPointTracker: chatKeyPointTracker,
            readService: readService,
            urlPreviewService: urlPreviewService,
            processMessageSelectedEnable: { message in
                if fromWhere == .singleChatGroup,
                   (message.type == .hongbao || message.type == .commercializedHongbao) {
                    return false
                }
                return true
            },
            getFeatureIntroductions: {
                return []
            }
        )
        return chatMessagesVMDependency
    }

    func readService(pushWrapper: ChatPushWrapper,
                     context: ChatContext,
                     audioToTextEnable: Bool,
                     fromWhere: ChatFromWhere) throws -> ChatMessageReadService {
        let chat = pushWrapper.chat.value
        var channel = RustPB.Basic_V1_Channel()
        channel.id = chat.id
        channel.type = .chat
        let forceNotEnabled = chat.isTeamVisitorMode
        let messageAPI = try self.resolver.resolve(assert: MessageAPI.self)
        let threadAPI = try self.resolver.resolve(assert: ThreadAPI.self)
        return try self.resolver.resolve( // user:checked
            assert: ChatMessageReadService.self,
            arguments: PutReadScene.chat(chat),
            forceNotEnabled,
            audioToTextEnable,
            chat.isRemind,
            chat.isInBox,
            ["chat": chat,
             "chatFromWhere": fromWhere.rawValue] as [String: Any], { () -> Int32 in
                return pushWrapper.chat.value.readPosition
            }, { (info: PutReadInfo) in
                let messageIDs = info.ids.map { (chatIDAndMessageID) -> String in
                    return chatIDAndMessageID.messageID
                }

                messageAPI.putReadMessages(
                    channel: channel,
                    messageIds: messageIDs,
                    maxPosition: info.maxPosition,
                    maxPositionBadgeCount: info.maxBadgeCount,
                    foldIds: info.foldIds)
            }
        )
    }

    let userResolver: UserResolver
    let inSelectMode: Bool = true
    let needCellVMGC: Bool = false
    let supportUserUniversalLastPostionSetting: Bool = true
    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func navigationBar(moduleContext: ChatModuleContext, pushWrapper: ChatPushWrapper, blurEnabled: Bool, targetVC: UIViewController, chatPath: Path) -> ChatNavigationBar {
        ChatMessagePickerNavigationBarModule.onLoad(context: moduleContext.navigaionContext)
        ChatMessagePickerNavigationBarModule.registGlobalServices(container: moduleContext.container)
        let navigationBarModule: BaseChatNavigationBarModule = ChatMessagePickerNavigationBarModule(context: moduleContext.navigaionContext)
        let viewModel = ChatNavigationBarViewModel(
            chatWrapper: pushWrapper,
            module: navigationBarModule
        )
        let navBar = ChatNavigationBarImp(viewModel: viewModel, blurEnabled: blurEnabled, darkStyle: false)
        return navBar
    }

    func canCreateKeyboard(chat: Chat) -> Bool {
        return false
    }

    func keyboard(moduleContext: ChatModuleContext, delegate: ChatInputKeyboardDelegate,
                  chat: Chat, messageSender: @escaping () -> MessageSender,
                  chatKeyPointTracker: ChatKeyPointTracker) -> ChatInternalKeyboardService? {
        /// 同步会话记录不展示键盘
        return nil
    }

    func widgetsView(moduleContext: ChatModuleContext, pushWrapper: ChatPushWrapper, targetVC: UIViewController) -> ChatWidgetsContainerView? {
        return nil
    }

    func needDisplayChatMenu(chat: Chat) -> Bool {
        return false
    }

    func chatMenu(pushWrapper: ChatPushWrapper, delegate: ChaMenutKeyboardDelegate, chatVC: UIViewController) -> ChatMenuBottomView? {
        return nil
    }

    func pinSummaryView(pinSummaryContext: ChatPinSummaryContext, pushWrapper: ChatPushWrapper, chatVC: UIViewController) -> ChatPinSummaryContainerView? {
        return nil
    }

    func timezoneView(chatNameObservable: Observable<String>) -> TimeZoneView? {
        return nil
    }

    func guideManager(chatBaseVC: ChatMessagesViewController) -> ChatBaseGuideManager? {
        return nil
    }

    func needDisplayTabs(chat: Chat) -> Bool {
        return false
    }

    func messageSelectControl(chat: SelectControlHostController) -> MessageSelectControl? {
        return nil
    }

    func pageContainerRegister(pushWrapper: ChatPushWrapper, context: ChatContext) {
    }

    func pageContainerRegister(chatId: String, context: LarkMessageBase.ChatContext) {
        let resolver = self.userResolver
        context.pageContainer.register(ChatScreenProtectService.self) { [weak context] in
            let service = ChatScreenProtectService(chatId: chatId,
                                                   getTargetVC: { [weak context] in return context?.pageAPI },
                                                   userResolver: resolver)
            return service
        }
    }
}
