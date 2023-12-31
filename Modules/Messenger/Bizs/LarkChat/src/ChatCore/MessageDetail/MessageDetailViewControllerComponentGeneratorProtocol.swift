//
//  MessageDetailViewControllerComponentGeneratorProtocol.swift
//  LarkChat
//
//  Created by zhaojiachen on 2021/12/29.
//

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
import LarkMessageBase
import UIKit
import EditTextView
import UniverseDesignToast
import EENavigator
import LarkContainer
import LarkSendMessage
import LarkSceneManager
import LarkBaseKeyboard
import LarkChatOpenKeyboard
import LarkOpenKeyboard
import LarkChatKeyboardInterface

protocol MessageDetailViewControllerComponentGeneratorProtocol: AnyObject, UserResolverWrapper {
    var fileDecodeService: RustEncryptFileDecodeService? { get }
    func keyboard(moduleContext: MessageDetailModuleContext,
                  delegate: ChatInputKeyboardDelegate,
                  pushWrapper: ChatPushWrapper,
                  getRootMessage: () -> LarkModel.Message?,
                  chatFromWhere: ChatFromWhere) throws -> ChatInternalKeyboardService?
    func messageActionServiceRegister(pushWrapper: ChatPushWrapper,
                                      moduleContext: MessageDetailModuleContext)
    func placeholderChatView() -> PlaceholderChatView?
    func messagesDataSource(context: MessageDetailContext, pushWrapper: ChatPushWrapper, rootMessage: LarkModel.Message?) -> MessageDetailMessagesDataSource
    func navigationBarItems(chat: Chat, rootMessage: LarkModel.Message?,
                            uiDataSource: @escaping () -> [[MessageDetailCellViewModel]],
                            targetVC: UIViewController) -> [UIBarButtonItem]
    func pageContainerRegister(pushWrapper: ChatPushWrapper, context: MessageDetailContext)
    func messageSelectControl(chat: SelectControlHostController) -> MessageSelectControl?
}

final class NormalMessageDetailViewControllerComponentGenerator: MessageDetailViewControllerComponentGeneratorProtocol {
    let userResolver: UserResolver
    private let chatterManager: ChatterManagerProtocol

    init(resolver: UserResolver) throws {
        self.chatterManager = try resolver.resolve(assert: ChatterManagerProtocol.self)
        self.userResolver = resolver
    }

    func keyboard(moduleContext: MessageDetailModuleContext,
                  delegate: ChatInputKeyboardDelegate,
                  pushWrapper: ChatPushWrapper,
                  getRootMessage: () -> LarkModel.Message?,
                  chatFromWhere: ChatFromWhere) throws -> ChatInternalKeyboardService? {

        let chat = pushWrapper.chat.value
        let trackInfo = ChatKeyPointTrackerInfo(id: chat.id,
                                                isCrypto: false,
                                                inChatMessageDetail: true,
                                                chat: chat)
        let chatKeyPointTracker = ChatKeyPointTracker(resolver: userResolver, chatInfo: trackInfo)

        let userResolver = self.userResolver
        let messageSender: () -> MessageSender = {
            let sender = MessageSender(userResolver: userResolver, actionPosition: ActionPosition.messageDetail, chatInfo: chatKeyPointTracker.chatInfo, chat: pushWrapper.chat)
            sender.addModifier(modifier: DisplayModeModifier(chat: pushWrapper.chat))
            sender.addModifier(modifier: ChatFromModifier(fromWhere: chatFromWhere))
            return sender
        }

        let sendService = ChatKeyboardMessageSendServiceIMP(messageSender: messageSender)

        moduleContext.container.register(KeyboardPictureItemSendService.self) { (_) -> KeyboardPictureItemSendService in
            return sendService
        }

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

        let canvasItem = ChatKeyboardCanvasItemConfig(uiConfig: nil, sendConfig: KeyboardCanvasSendConfig(sendService: sendService))

        let moreItem = ChatMoreKeyboardItemConfig(uiConfig: KeyboardMoreUIConfig(blacklist: [], tappedBlock: nil),
                                                  sendConfig: KeyboardMoreSendConfig(sendService: sendService))
        let rootMessage = getRootMessage()
        let dataConfig = ChatOpenKeyboardConfig.DataConfig(chat: chat,
                                                           context: moduleContext.keyboardContext,
                                                           userResolver: self.userResolver,
                                                           copyPasteToken: "LARK-PSDA-messenger-chat-detail-keyboard-input-permission",
                                                           delegate: delegate,
                                                           sendService: sendService,
                                                           items: [voiceConfig,
                                                                   emojiConfig,
                                                                   pictureItem,
                                                                   canvasItem,
                                                                   burnTime,
                                                                   moreItem],
                                                           rootMessage: rootMessage) { keyboardView in
            if let message = rootMessage, let keyboardView = keyboardView as? ChatKeyboardView {
                let info = KeyboardJob.ReplyInfo(message: message, partialReplyInfo: nil)
                keyboardView.keyboardStatusManager.defaultKeyboardJob = .reply(info: info)
                keyboardView.switchJob(.reply(info: info))
            }
        }
        let abilityConfig = ChatOpenKeyboardConfig.AbilityConfig(supportRichTextEdit: true,
                                                                         supportRealTimeTranslate: true,
                                                                         disableReplyBar: true,
                                                                         supportAfterMessagesRender: false)
        let config = ChatOpenKeyboardConfig(dataConfig: dataConfig, abilityConfig: abilityConfig)
        chatKeyboard?.loadChatKeyboardViewWithConfig(config)
        return chatKeyboard
    }

    func placeholderChatView() -> PlaceholderChatView? {
        return PlaceholderChatView(isDark: false,
                                   title: BundleI18n.LarkChat.Lark_IM_RestrictedMode_ScreenRecordingEmptyState_Text,
                                   subTitle: BundleI18n.LarkChat.Lark_IM_RestrictedMode_ScreenRecordingEmptyState_Desc)
    }

    var fileDecodeService: RustEncryptFileDecodeService? {
        return nil
    }

    func messagesDataSource(context: MessageDetailContext, pushWrapper: ChatPushWrapper, rootMessage: LarkModel.Message?) -> MessageDetailMessagesDataSource {
        let vmFactory = NormalChatMessageDetailMessageCellViewModelFactory(
            context: context,
            registery: MessageDetailMessageSubFactoryRegistery(
                context: context, defaultFactory: UnknownContentFactory(context: context)
            ),
            cellLifeCycleObseverRegister: NormalMessageDetailCellLifeCycleObseverRegister()
        )
        var existInVisibleMessage: Bool = false
        var rootMsgBurned: Bool = false
        let messageBurnService = try? self.resolver.resolve(type: MessageBurnService.self)
        if let rootMsg = rootMessage {
            rootMsgBurned = messageBurnService?.isBurned(message: rootMsg) ?? false
            existInVisibleMessage = !rootMsg.isVisible || rootMsg.position <= pushWrapper.chat.value.firstMessagePostion
        }
        return MessageDetailMessagesDataSource(
            rootMessage: ((rootMsgBurned || existInVisibleMessage) ? nil : rootMessage),
            chat: {
                return pushWrapper.chat.value
            },
            vmFactory: vmFactory,
            getPlaceholderTip: {
                return BundleI18n.LarkChat.Lark_IM_NoRepliesYet_Empty
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
        var barButtons: [UIBarButtonItem] = []
        if !(rootMessage?.isDecryptoFail ?? false) {
            let forwardBut: ForwardUIBarButtonItem = ForwardUIBarButtonItem(image: Resources.forward_all_normal_icon,
                                                                            style: .plain,
                                                                            target: self,
                                                                            action: #selector(forwardAllMessage(button:))
            )
            forwardBut.getUIDataSource = uiDataSource
            forwardBut.targetVC = targetVC
            forwardBut.chat = chat
            barButtons.append(forwardBut)
        }
        return barButtons
    }

    func messageActionServiceRegister(pushWrapper: ChatPushWrapper,
                                      moduleContext: MessageDetailModuleContext) {
        MessageDetailMessageActionModule.onLoad(context: moduleContext.messageActionContext)
        // 处理内存泄漏临时解法: OpenIM和PageContainer两个容器没有打通, ChatPinService需要也被OpenIM持有
        if let chatPinservice = moduleContext.messageDetailContext.pageContainer.resolve(ChatPinPageService.self) {
            moduleContext.container.register(ChatPinPageService.self) { _ in
                return chatPinservice
            }
        }
        let actionModule = MessageDetailMessageActionModule(context: moduleContext.messageActionContext)
        let messageMenuService: MessageMenuOpenService = MessageMenuServiceImp(pushWrapper: pushWrapper, actionModule: actionModule)
        moduleContext.messageDetailContext.pageContainer.register(MessageMenuOpenService.self) {
            return messageMenuService
        }
    }

    func pageContainerRegister(pushWrapper: ChatPushWrapper, context: MessageDetailContext) {
        let resolver = self.userResolver
        let chatID = pushWrapper.chat.value.id
        if let userPushCenter = try? resolver.userPushCenter {
            context.pageContainer.register(ChatPinPageService.self) { [weak context] in
                return ChatPinPageService(chatID: chatID, pageContext: context)
            }
            context.pageContainer.register(MessageURLTemplateService.self) { [weak context] in
                return MessageURLTemplateService(context: context, pushCenter: userPushCenter)
            }
        }
        context.pageContainer.register(ReactionPageService.self) {
            return ReactionPageService(service: try? resolver.resolve(assert: ReactionService.self))
        }
        context.pageContainer.register(ChatScreenProtectService.self) { [weak context] in
            let service = ChatScreenProtectService(chat: pushWrapper.chat,
                                                   getTargetVC: { [weak context] in return context?.pageAPI },
                                                   userResolver: resolver)
            return service
        }
    }

    private final class ForwardUIBarButtonItem: UIBarButtonItem {
        var getUIDataSource: (() -> [[MessageDetailCellViewModel]])?
        weak var targetVC: UIViewController?
        var chat: Chat?
    }

    /// 用户点击"转发所有消息"icon
    @objc
    private func forwardAllMessage(button: ForwardUIBarButtonItem) {
        guard let targetVC = button.targetVC, let chat = button.chat else { return }
        if chat.enableRestricted(.forward) {
            UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_RestrictedMode_CopyForwardNotAllow_Toast, on: targetVC.view)
            return
        }
        // 判断是否有可以转发的消息：去掉撤回 & 去掉不支持转发的(ContentConfig.supportMutiSelect==false)
        let cellVMs = (button.getUIDataSource?() ?? []).flatMap({ $0 }).compactMap({ $0 as? MessageDetailMessageCellViewModel })
        let messageIds = cellVMs.filter({ !$0.message.isRecalled }).filter({ $0.content.contentConfig?.supportMutiSelect ?? false }).map({ $0.message.id })
        // 没有可以转发的消息，直接toast提示，不进行后续操作
        guard !messageIds.isEmpty else {
            UDToast.showTips(with: BundleI18n.LarkChat.Lark_Chat_NoForwardableThreadMessage, on: targetVC.view)
            return
        }
        let containBurnMessage = cellVMs.contains(where: { $0.message.isOnTimeDel == true })

        // 打点
        MessageDetailTracker.trackForwardAllMessage()
        // 和Chat中对多个消息进行合并转发使用一样的title
        let title = self.gernateMergeMessageTitle(chat: chat)
        // 发起转发操作
        let body = MergeForwardMessageBody(
            originMergeForwardId: nil,
            fromChannelId: chat.id,
            messageIds: messageIds,
            title: title,
            traceChatType: .threadDetail,
            finishCallback: nil,
            supportToMsgThread: true,
            containBurnMessage: containBurnMessage
        )
        navigator.present(
            body: body,
            from: targetVC,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
    }

    private func gernateMergeMessageTitle(chat: Chat) -> String {
        switch chat.type {
        case .p2P:
            if chat.chatter?.id == self.chatterManager.currentChatter.id {
                return BundleI18n.LarkChat.Lark_Legacy_ChatMergeforwardtitlebyoneside(chat.chatter?.displayName ?? "")
            } else {
                let myName = self.chatterManager.currentChatter.displayName
                let otherName = chat.chatter?.displayName ?? ""
                return BundleI18n.LarkChat.Lark_Legacy_ChatMergeforwardtitlebytwoside(myName, otherName)
            }
        case .group, .topicGroup:
            return BundleI18n.LarkChat.Lark_Legacy_ForwardGroupChatHistory
        @unknown default:
            assert(false, "new value")
            return BundleI18n.LarkChat.Lark_Legacy_ForwardGroupChatHistory
        }
    }

    func messageSelectControl(chat: SelectControlHostController) -> MessageSelectControl? {
        return MessageSelectControl(chat: chat, pasteboardToken: "LARK-PSDA-messenger-messageDetail-select-copyCommand-permission")
    }
}
