//
//  CryptoChatViewControllerComponentGenerator.swift
//  LarkChat
//
//  Created by zc09v on 2021/11/23.
//

import Foundation
import UIKit
import RxSwift
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
import LarkNavigation
import LarkUIKit
import SuiteAppConfig
import RustPB
import LarkSceneManager
import LarkOpenChat
import AppContainer
import LarkBadge
import EditTextView
import LarkReleaseConfig
import LarkAttachmentUploader
import ByteWebImage
import FigmaKit
import UniverseDesignColor
import LarkSendMessage
import LarkBaseKeyboard
import LarkChatOpenKeyboard
import LarkOpenKeyboard
import LarkContainer
import LarkChatKeyboardInterface

final class CryptoChatViewControllerComponentGenerator: NSObject, ChatViewControllerComponentGeneratorProtocol {

    let userResolver: UserResolver
    let inSelectMode: Bool = false
    let needCellVMGC: Bool = true
    let supportUserUniversalLastPostionSetting: Bool = false

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    lazy var fileDecodeService: RustEncryptFileDecodeService? = {
        return try? resolver.resolve(assert: RustEncryptFileDecodeService.self)
    }()

    func chatMessagesVMDependency(pushWrapper: ChatPushWrapper,
                                  context: ChatContext,
                                  chatKeyPointTracker: ChatKeyPointTracker,
                                  fromWhere: ChatFromWhere) throws -> ChatMessagesVMDependency {
        let chat = pushWrapper.chat.value
        let pushCenter = try resolver.userPushCenter
        let currentChatterID = userResolver.userID
        let messageAPI = try self.resolver.resolve(assert: MessageAPI.self)
        let audioToTextEnable = userResolver.fg.staticFeatureGatingValue(with: .init(key: .audioToTextEnable)) &&
                                userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteVoice2Text))
        var channel = RustPB.Basic_V1_Channel()
        channel.id = chat.id
        channel.type = .chat
        let readService = try self.resolver.resolve( // user:checked
            assert: ChatMessageReadService.self,
            arguments: PutReadScene.chat(chat),
            false,
            audioToTextEnable,
            chat.isRemind,
            chat.isInBox,
            ["chat": pushWrapper.chat.value,
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
                    maxPositionBadgeCount: info.maxBadgeCount)
            }
        )

        let chatMessagesVMDependency = ChatMessagesVMDependency(
            userResolver: userResolver,
            channelId: chat.id,
            currentChatterID: currentChatterID,
            audioShowTextEnable: audioToTextEnable,
            chatKeyPointTracker: chatKeyPointTracker,
            readService: readService,
            urlPreviewService: nil, // 密聊不支持URL预览
            processMessageSelectedEnable: { message in
                if fromWhere == .singleChatGroup,
                   (message.type == .hongbao || message.type == .commercializedHongbao) {
                    return false
                }
                return true
            },
            getFeatureIntroductions: { [weak self] in
                guard let secretChatService = try? self?.userResolver.resolve(type: SecretChatService.self) else {
                    return []
                }
                let secureViewIsWork = context.pageContainer.resolve(ChatScreenProtectService.self)?.secureViewIsWork ?? false
                return secretChatService.featureIntroductions(
                    secureViewIsWork: secureViewIsWork
                )
            }
        )
        return chatMessagesVMDependency
    }

    func navigationBar(moduleContext: ChatModuleContext, pushWrapper: ChatPushWrapper, blurEnabled: Bool, targetVC: UIViewController, chatPath: Path) -> ChatNavigationBar {
        let secretChatService = try? self.resolver.resolve(type: SecretChatService.self)
        CryptoChatNavigationBarModule.onLoad(context: moduleContext.navigaionContext)
        CryptoChatNavigationBarModule.registGlobalServices(container: moduleContext.container)

        let navigationBarModule: BaseChatNavigationBarModule = CryptoChatNavigationBarModule(context: moduleContext.navigaionContext)
        let viewModel = ChatNavigationBarViewModel(
            chatWrapper: pushWrapper,
            module: navigationBarModule,
            isDark: !Display.pad
        )
        let navBar = ChatNavigationBarImp(viewModel: viewModel, blurEnabled: blurEnabled, darkStyle: !Display.pad)
        if !Display.pad, let navigationBackgroundColor = secretChatService?.navigationBackgroundColor.nonDynamic {
            navBar.setBackgroundColor(navigationBackgroundColor)
        }
        return navBar
    }

    func canCreateKeyboard(chat: Chat) -> Bool {
        return chat.chatable
    }

    func keyboard(moduleContext: ChatModuleContext, delegate: ChatInputKeyboardDelegate,
                  chat: Chat, messageSender: @escaping () -> MessageSender,
                  chatKeyPointTracker: ChatKeyPointTracker) -> ChatInternalKeyboardService? {
        let userResolver = self.userResolver
        guard
            let pushCenter = try? userResolver.userPushCenter,
            let chatWrapper = try? resolver.resolve(assert: ChatPushWrapper.self, argument: chat)
        else { return nil }
        let getRootMessage: () -> LarkModel.Message? = { return nil }
        let keyboardNewStyleEnable = KeyboardDisplayStyleManager.isNewKeyboadStyle()
        CryptoChatKeyboardModule.onLoad(context: moduleContext.keyboardContext)
        CryptoChatKeyboardModule.registGlobalServices(container: moduleContext.container)
        let chatKeyboardModule: BaseChatKeyboardModule = CryptoChatKeyboardModule(context: moduleContext.keyboardContext)

        let messageSender = ChatKeyboardMessageSendServiceIMP(messageSender: messageSender)
        let viewModel: DefaultInputViewModel = DefaultInputViewModel(
            userResolver: userResolver,
            chatWrapper: { return chatWrapper },
            messageSender: messageSender,
            pushChannelMessage: pushCenter.driver(for: PushChannelMessage.self),
            pushChat: pushCenter.driver(for: PushChat.self),
            rootMessage: getRootMessage(),
            supportAfterMessagesRender: true,
            getAttachmentUploader: { (key) in
                return try? userResolver.resolve(assert: AttachmentUploader.self, argument: key)
            }
        )

        let context = KeyboardContext(parent: moduleContext.container,
                                      store: Store(),
                                      userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        IMCryptoChatKeyboardModule.onLoad(context: context)
        IMCryptoChatKeyboardModule.registGlobalServices(container: context.container)
        let keyboardModule = IMCryptoChatKeyboardModule(context: context)

        let keyboardView: ChatKeyboardView = ChatKeyboardView(
            chatWrapper: viewModel.chatWrapper,
            viewModel: IMKeyboardViewModel(module: keyboardModule, chat: chatWrapper.chat),
            suppportAtAI: false,
            currentChatterId: viewModel.userResolver.userID,
            pasteboardToken: "LARK-PSDA-messenger-crypto-chat-inputview-permission",
            keyboardNewStyleEnable: keyboardNewStyleEnable,
            supportRealTimeTranslate: false)
        keyboardView.expandType = .hide

        moduleContext.container.register(OpenKeyboardService.self) { [weak keyboardView] (_) -> OpenKeyboardService in
            return keyboardView ?? OpenKeyboardServiceEmptyIMP()
        }

        moduleContext.container.register(KeyboardSendMessageKeyPointTrackerService.self) { (_) -> KeyboardSendMessageKeyPointTrackerService in
            return chatKeyPointTracker
        }

        moduleContext.container.register(KeyboardPictureItemSendService.self) { (_) -> KeyboardPictureItemSendService in
            return messageSender
        }

        moduleContext.container.register(KeyboardAudioItemSendService.self) { (_) -> KeyboardAudioItemSendService in
            return messageSender
        }

        let inputKeyboard = CryptoChatInputKeyboard(
            viewModel: viewModel,
            module: chatKeyboardModule,
            delegate: delegate,
            keyboardView: keyboardView
        )

        moduleContext.container.register(ChatKeyboardOpenService.self) { [weak inputKeyboard] (_) -> ChatKeyboardOpenService in
            return inputKeyboard ?? DefaultChatKeyboardOpenService()
        }
        inputKeyboard.setupModule()
        return inputKeyboard
    }

    func pageContainerRegister(pushWrapper: ChatPushWrapper, context: ChatContext) {
        let resolver = self.resolver
        context.pageContainer.register(ReactionPageService.self) {
            return ReactionPageService(service: try? resolver.resolve(assert: ReactionService.self))
        }
        // 用户关系的页面服务
        context.pageContainer.register(UserRelationPageService.self) {
            return UserRelationPageService(chat: pushWrapper.chat.value, userRelationService: try? resolver.resolve(assert: UserRelationService.self))
        }
    }

    func pageContainerRegister(chatId: String, context: ChatContext) {
        let resolver = self.userResolver
        context.pageContainer.register(ChatScreenProtectService.self) { [weak context] in
            let service = ChatScreenProtectService(chatId: chatId,
                                                   getTargetVC: { [weak context] in return context?.pageAPI },
                                                   forceEnable: true,
                                                   useSecureView: true,
                                                   userResolver: resolver)
            return service
        }
    }

    func instantChatNavigationBar() -> InstantChatNavigationBar {
        let view = InstantChatNavigationBar(isDark: true)
        let secretChatService = try? self.resolver.resolve(type: SecretChatService.self)
        if let navBarBackgroundColor = secretChatService?.navigationBackgroundColor {
            view.navBarBackgroundColor = navBarBackgroundColor
        }
        return view
    }

    func instantKeyboard() -> InstantChatKeyboard {
        return CryptoInstantChatKeyboard()
    }

    func placeholderChatView() -> PlaceholderChatView? {
        let secretChatService = try? self.resolver.resolve(assert: SecretChatService.self)
        return PlaceholderChatView(isDark: true,
                                   title: BundleI18n.LarkChat.Lark_Chat_SecurityProtection,
                                   subTitle: BundleI18n.LarkChat.Lark_Chat_SecretChatAutoHideScreenRecording,
                                   darkBackgroundColor: secretChatService?.navigationBackgroundColor)
    }

    func messageActionServiceRegister(pushWrapper: ChatPushWrapper, moduleContext: ChatModuleContext) {
        CryptoMessageActionModule.onLoad(context: moduleContext.messageActionContext)
        let actionModule = CryptoMessageActionModule(context: moduleContext.messageActionContext)
        let messageMenuService: MessageMenuOpenService = MessageMenuServiceImp(pushWrapper: pushWrapper, actionModule: actionModule)
        moduleContext.chatContext.pageContainer.register(MessageMenuOpenService.self) {
            return messageMenuService
        }
    }

    func chatBanner(pushWrapper: ChatPushWrapper, context: ChatBannerContext) -> ChatBannerView? {
        CryptoChatBannerModule.onLoad(context: context)
        CryptoChatBannerModule.registGlobalServices(container: context.container)
        return ChatBannerView(bannerModule: CryptoChatBannerModule(context: context), chatWrapper: pushWrapper)
    }

    func chatFooter(pushWrapper: ChatPushWrapper, context: LarkOpenChat.ChatFooterContext) -> ChatFooterView? {
        CryptoChatFooterModule.onLoad(context: context)
        CryptoChatFooterModule.registGlobalServices(container: context.container)
        return ChatFooterView(footerModule: CryptoChatFooterModule(context: context), chatWrapper: pushWrapper)
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

    func chatKeyboardTopExtendView(pushWrapper: ChatPushWrapper,
                                   context: ChatKeyboardTopExtendContext,
                                   delegate: ChatKeyboardTopExtendViewDelegate) -> ChatKeyboardTopExtendView? {
        CryptoChatKeyboardTopExtendModule.onLoad(context: context)
        CryptoChatKeyboardTopExtendModule.registGlobalServices(container: context.container)
        return ChatKeyboardTopExtendView(topExtendModule: CryptoChatKeyboardTopExtendModule(context: context), chatWrapper: pushWrapper, delegate: delegate)
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

    func messagesDataSource(pushWrapper: ChatPushWrapper, context: ChatContext) throws -> ChatMessagesDatasource {
        let messageBurnService = try? self.resolver.resolve(type: MessageBurnService.self)
        let messageCellProcessor = NormalChatMessageDatasourceProcessor(isNewRecalledEnable: context.isNewRecallEnable)
        let datasource = ChatMessagesDatasource(
            chat: {
                return pushWrapper.chat.value
            },
            vmFactory: CryptoChatCellViewModelFactory(
                context: context,
                registery: CryptoChatMessageSubFactoryRegistery(
                    context: context, defaultFactory: UnknownContentFactory(context: context)
                )
            ),
            isMessageBurned: { message in
                return messageBurnService?.isBurned(message: message) ?? false
            },
            messageCellProcessor: messageCellProcessor
        )
        messageCellProcessor.dependency = datasource
        return datasource
    }

    func guideManager(chatBaseVC: ChatMessagesViewController) -> ChatBaseGuideManager? {
        return nil
    }

    func needDisplayTabs(chat: Chat) -> Bool {
        return false
    }

    func suspendIcon(chat: Chat) -> UIImage? {
        return Resources.suspend_icon_secret
    }

    func topBlurView(chat: Chat) -> BackgroundBlurView {
        let topBlurView = BackgroundBlurView()
        topBlurView.blurRadius = 50
        topBlurView.backgroundColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.75) & UIColor.ud.staticBlack.withAlphaComponent(0.75)
        let secretChatService = try? self.resolver.resolve(type: SecretChatService.self)
        if !Display.pad, let secretChatService = secretChatService {
            topBlurView.backgroundColor = secretChatService.navigationBackgroundColor.nonDynamic
        }
        return topBlurView
    }

    func messageSelectControl(chat: SelectControlHostController) -> MessageSelectControl? {
        return CryptoMessageSelectControl(chat: chat, pasteboardToken: "LARK-PSDA-messenger-cryptoChat-select-copyCommand-permission")
    }

    func timezoneView(chatNameObservable: Observable<String>) -> TimeZoneView? {
        let fg = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "im.setting.external_display_timezone"))
        return fg ? NewChatTimezoneView(userResolver: userResolver, chatNameObservable: .just(BundleI18n.LarkChat.Lark_IM_SecureChatUser_Title)) : ChatTimezoneView()
    }
}
