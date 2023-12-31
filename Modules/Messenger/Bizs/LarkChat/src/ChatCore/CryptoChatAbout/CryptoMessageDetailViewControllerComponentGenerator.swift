//
//  CryptoMessageDetailViewControllerComponentGenerator.swift
//  LarkChat
//
//  Created by zhaojiachen on 2021/12/29.
//

import UIKit
import Foundation
import LarkCore
import LarkReleaseConfig
import LarkAttachmentUploader
import LKCommonsTracker
import AppContainer
import Swinject
import LarkAppConfig
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkKAFeatureSwitch
import LarkFeatureSwitch
import LarkMessageCore
import LarkModel
import LarkOpenChat
import ByteWebImage
import EditTextView
import LarkMessageBase
import LarkSendMessage
import LarkSceneManager
import LarkBaseKeyboard
import LarkChatOpenKeyboard
import LarkOpenKeyboard
import LarkContainer
import LarkChatKeyboardInterface

final class CryptoMessageDetailViewControllerComponentGenerator: MessageDetailViewControllerComponentGeneratorProtocol {
    let userResolver: UserResolver
    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func keyboard(moduleContext: MessageDetailModuleContext,
                  delegate: ChatInputKeyboardDelegate,
                  pushWrapper: ChatPushWrapper,
                  getRootMessage: () -> LarkModel.Message?,
                  chatFromWhere: ChatFromWhere) throws -> ChatInternalKeyboardService? {
        let chat = pushWrapper.chat.value
        let trackInfo = ChatKeyPointTrackerInfo(id: chat.id,
                                                isCrypto: true,
                                                inChatMessageDetail: true,
                                                chat: chat)
        let pushCenter = try resolver.userPushCenter
        let resolver = self.userResolver
        let chatKeyPointTracker = ChatKeyPointTracker(resolver: resolver, chatInfo: trackInfo)
        let messageSender: () -> MessageSender = {
            let sender = MessageSender(userResolver: resolver, actionPosition: ActionPosition.messageDetail, chatInfo: chatKeyPointTracker.chatInfo, chat: pushWrapper.chat)
            sender.addModifier(modifier: DisplayModeModifier(chat: pushWrapper.chat))
            sender.addModifier(modifier: ChatFromModifier(fromWhere: chatFromWhere))
            return sender
        }
        let buildTodoDependency = { () -> MessageCoreTodoDependency in
            return try resolver.resolve(assert: MessageCoreTodoDependency.self)
        }
        let keyboardNewStyleEnable = KeyboardDisplayStyleManager.isNewKeyboadStyle()

        CryptoChatKeyboardModule.onLoad(context: moduleContext.keyboardContext)
        CryptoChatKeyboardModule.registGlobalServices(container: moduleContext.container)

        let chatKeyboardModule: BaseChatKeyboardModule = CryptoChatKeyboardModule(context: moduleContext.keyboardContext)
        let sendService = ChatKeyboardMessageSendServiceIMP(messageSender: messageSender)
        let viewModel: DefaultInputViewModel = DefaultInputViewModel(
            userResolver: userResolver,
            chatWrapper: { pushWrapper },
            messageSender: sendService,
            pushChannelMessage: pushCenter.driver(for: PushChannelMessage.self),
            pushChat: pushCenter.driver(for: PushChat.self),
            rootMessage: getRootMessage(),
            supportAfterMessagesRender: false,
            getAttachmentUploader: { (key) in
                return try? resolver.resolve(assert: AttachmentUploader.self, argument: key)
            })

        let context = KeyboardContext(parent: moduleContext.container,
                                      store: Store(),
                                      userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        IMCryptoChatKeyboardModule.onLoad(context: context)
        IMCryptoChatKeyboardModule.registGlobalServices(container: context.container)
        let keyboardModule = IMCryptoChatKeyboardModule(context: context)

        let keyboardView: ChatKeyboardView = ChatKeyboardView(
            chatWrapper: viewModel.chatWrapper,
            viewModel: IMKeyboardViewModel(module: keyboardModule, chat: pushWrapper.chat),
            suppportAtAI: false,
            currentChatterId: viewModel.userResolver.userID,
            pasteboardToken: "LARK-PSDA-messenger-crypto-chat-detail-inputview-permission",
            keyboardNewStyleEnable: keyboardNewStyleEnable,
            supportRealTimeTranslate: false
        )

        keyboardView.expandType = .hide

        moduleContext.container.register(KeyboardSendMessageKeyPointTrackerService.self) { (_) -> KeyboardSendMessageKeyPointTrackerService in
            return chatKeyPointTracker
        }

        moduleContext.container.register(KeyboardPictureItemSendService.self) { (_) -> KeyboardPictureItemSendService in
            return sendService
        }

        moduleContext.container.register(KeyboardAudioItemSendService.self) { (_) -> KeyboardAudioItemSendService in
            return sendService
        }

        moduleContext.container.register(OpenKeyboardService.self) { [weak keyboardView] (_) -> OpenKeyboardService in
            return keyboardView ?? OpenKeyboardServiceEmptyIMP()
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

    func messageActionServiceRegister(pushWrapper: ChatPushWrapper,
                                      moduleContext: MessageDetailModuleContext) {
        CryptoMessageDetailMessageActionModule.onLoad(context: moduleContext.messageActionContext)
        let actionModule = CryptoMessageDetailMessageActionModule(context: moduleContext.messageActionContext)
        let messageMenuService: MessageMenuOpenService = MessageMenuServiceImp(pushWrapper: pushWrapper, actionModule: actionModule)
        moduleContext.messageDetailContext.pageContainer.register(MessageMenuOpenService.self) {
            return messageMenuService
        }
    }

    func placeholderChatView() -> PlaceholderChatView? {
        let secretChatService = try? self.resolver.resolve(assert: SecretChatService.self)
        return PlaceholderChatView(isDark: true,
                                   title: BundleI18n.LarkChat.Lark_Chat_SecurityProtection,
                                   subTitle: BundleI18n.LarkChat.Lark_Chat_SecretChatAutoHideScreenRecording,
                                   darkBackgroundColor: secretChatService?.navigationBackgroundColor
        )
    }

    lazy var fileDecodeService: RustEncryptFileDecodeService? = {
        return try? resolver.resolve(assert: RustEncryptFileDecodeService.self)
    }()

    func messagesDataSource(context: MessageDetailContext, pushWrapper: ChatPushWrapper, rootMessage: LarkModel.Message?) -> MessageDetailMessagesDataSource {
        var existInVisibleMessage: Bool = false
        var rootMsgBurned: Bool = false
        let messageBurnService = try? self.resolver.resolve(type: MessageBurnService.self)
        if let rootMsg = rootMessage {
            rootMsgBurned = messageBurnService?.isBurned(message: rootMsg) ?? false
            existInVisibleMessage = !rootMsg.isVisible || rootMsg.position <= pushWrapper.chat.value.firstMessagePostion
        }

        let vmFactory: MessageDetailMessageCellViewModelFactory
        vmFactory = CryptoChatMessageDetailMessageCellViewModelFactory(
            context: context,
            registery: CryptoMessageDetailMessageSubFactoryRegistery(
                context: context, defaultFactory: UnknownContentFactory(context: context)
            )
        )
        return MessageDetailMessagesDataSource(
            rootMessage: ((rootMsgBurned || existInVisibleMessage) ? nil : rootMessage),
            chat: {
                return pushWrapper.chat.value
            },
            vmFactory: vmFactory,
            getPlaceholderTip: {
                return BundleI18n.LarkChat.Lark_Chat_SecretChatAllRelatedMsgsDestructed
            },
            getMessageInvisibleTip: {
                return BundleI18n.LarkChat.Lark_Group_UnableViewEarlierMessages
            },
            isBurned: { message in
                return messageBurnService?.isBurned(message: message) ?? false
            },
            existInVisibleMessage: existInVisibleMessage
        )
    }

    func navigationBarItems(chat: Chat, rootMessage: LarkModel.Message?,
                            uiDataSource: @escaping () -> [[MessageDetailCellViewModel]],
                            targetVC: UIViewController) -> [UIBarButtonItem] {
        return []
    }

    func messageSelectControl(chat: SelectControlHostController) -> MessageSelectControl? {
        return CryptoMessageSelectControl(chat: chat, pasteboardToken: "LARK-PSDA-messenger-cryptoMessageDetail-select-copyCommand-permission")
    }

    func pageContainerRegister(pushWrapper: ChatPushWrapper, context: MessageDetailContext) {
        let resolver = self.userResolver
        context.pageContainer.register(ReactionPageService.self) {
            return ReactionPageService(service: try? resolver.resolve(assert: ReactionService.self))
        }
        context.pageContainer.register(ChatScreenProtectService.self) { [weak context] in
            let service = ChatScreenProtectService(chat: pushWrapper.chat,
                                                   getTargetVC: { [weak context] in return context?.pageAPI },
                                                   forceEnable: true,
                                                   useSecureView: true,
                                                   userResolver: resolver)
            return service
        }
    }
}
