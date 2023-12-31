//
//  MessageDetailHandler.swift
//  Action
//
//  Created by 赵冬 on 2019/8/2.
//

import Foundation
import EENavigator
import LarkModel
import Swinject
import LarkCore
import LarkRustClient
import LarkMessageCore
import LarkMessageBase
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkKAFeatureSwitch
import RxSwift
import LarkAppConfig
import AsyncComponent
import RustPB
import LarkWaterMark
import LarkSceneManager
import LarkOpenChat
import LarkNavigator

final class MessageDetailHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }

    func handle(_ body: MessageDetailBody, req: EENavigator.Request, res: Response) throws {
        // 未发送成功的消息不支持进入详情页
        // doc: https://bytedance.feishu.cn/docx/doxcnWXc4RQX5RkAzeqYkx75uTf
        guard body.message.localStatus == .success else { return }
        MessageDetailApprecibleTrack.loadTimeStart(chat: body.chat)
        let r = self.resolver
        let chat = body.chat
        let message = body.message
        var rootMessage: Message?
        // judge is rootMessage or not
        if message.rootId.isEmpty {
            // to slove a crash that two thread to change it at the same
            let copyMessage = message.copy()
            if let content = copyMessage.content as? MergeForwardContent {
                copyMessage.content = content.copy()
            }
            // here only rootMessage
            rootMessage = copyMessage
        } else {
            // to slove a crash that two thread to change it at the same
            let copyMessage = message.rootMessage?.copy()
            if let content = copyMessage?.content as? MergeForwardContent {
                copyMessage?.content = content.copy()
            }
            // here contains rootMessage and replies
            rootMessage = copyMessage
        }
        let pushCenter = try r.userPushCenter
        let wrapper = try r.resolve(assert: ChatPushWrapper.self, argument: chat)
        let messageAPI = try resolver.resolve(assert: MessageAPI.self)
        let componentGenerator: MessageDetailViewControllerComponentGeneratorProtocol
        // 密聊不支持URL预览
        var urlPreviewService: MessageURLPreviewService?
        if chat.isCrypto {
            componentGenerator = CryptoMessageDetailViewControllerComponentGenerator(resolver: userResolver)
        } else {
            componentGenerator = try NormalMessageDetailViewControllerComponentGenerator(resolver: userResolver)
            urlPreviewService = try? resolver.resolve(type: MessageURLPreviewService.self)
        }
        let dragManager = DragInteractionManager()
        dragManager.viewTagBlock = { return $0.getASComponentKey() ?? "" }

        let moduleContext = MessageDetailModuleContext(
            userStorage: userResolver.storage,
            dragManager: dragManager,
            modelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: userResolver)
        )
        moduleContext.messageDetailContext.trackParams = [PageContext.TrackKey.sceneKey: body.chatFromWhere.rawValue]
        moduleContext.keyboardContext.store.setValue(body.chatFromWhere.rawValue, for: IMTracker.Chat.Main.ChatFromWhereKey)
        let context = moduleContext.messageDetailContext
        let pushHandlerRegister = MessageDetailPushHandlersRegister(channelId: chat.id, userResolver: userResolver)
        let currentChatterId = userResolver.userID
        // 判断FeatureSwitch && FG
        let audioToTextEnable = userResolver.fg.staticFeatureGatingValue(with: .init(key: .audioToTextEnable)) &&
                                userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteVoice2Text))
        let messageDetailVM = try MessageDetailViewModel(
            userResolver: userResolver,
            rootId: rootMessage?.id ?? message.rootId,
            pushCenter: pushCenter,
            chatWrapper: wrapper,
            chatAPI: try r.resolve(assert: ChatAPI.self),
            currentChatterId: currentChatterId,
            userGeneralSettings: try resolver.resolve(assert: UserGeneralSettings.self),
            translateService: try resolver.resolve(assert: NormalTranslateService.self),
            contactControlService: try resolver.resolve(assert: ContactControlService.self)
        )
        var channel = RustPB.Basic_V1_Channel()
        channel.id = chat.id
        channel.type = .chat
        let readService = try self.resolver.resolve(assert: ChatMessageReadService.self,
                                                arguments: PutReadScene.messageDetail(chat),
                                                false,
                                                audioToTextEnable,
                                                chat.isRemind,
                                                chat.isInBox,
                                                ["chat": wrapper.chat.value,
                                                 "chatFromWhere": body.chatFromWhere.rawValue] as [String: Any], { () -> Int32 in
                                                    return wrapper.chat.value.readPosition
                                                }, { (info: PutReadInfo) in
                                                    let messageIDs = info.ids.map { (chatIDAndMessageID) -> String in
                                                        return chatIDAndMessageID.messageID
                                                    }
                                                    messageAPI.putReadMessages(
                                                        channel: channel,
                                                        messageIds: messageIDs,
                                                        maxPosition: info.maxPosition,
                                                        maxPositionBadgeCount: info.maxBadgeCount
                                                    )
                                                })
        let messageDetailMessageVMDependency = MessageDetailMessagesVMDependency(
            channelId: chat.id,
            chatWrapper: wrapper,
            currentChatterId: currentChatterId,
            messageAPI: try r.resolve(assert: MessageAPI.self),
            rustService: try r.resolve(assert: RustService.self),
            pushCenter: pushCenter,
            chatMessageReadService: readService,
            messageBurnService: try resolver.resolve(assert: MessageBurnService.self),
            urlPreviewService: urlPreviewService,
            pushHandlerRegister: pushHandlerRegister
        )

        let messageDetailMessageVM = MessageDetailMessagesViewModel(
            tapMessage: message,
            rootMessage: rootMessage,
            messagesDatasource: componentGenerator.messagesDataSource(context: context,
                                                                      pushWrapper: wrapper,
                                                                      rootMessage: rootMessage),
            dependency: messageDetailMessageVMDependency,
            context: context
        )

        let messageDetailVC = MessageDetailViewController(
            moduleContext: moduleContext,
            chatViewModel: messageDetailVM,
            chatMessagesViewModel: messageDetailMessageVM,
            componentGenerator: componentGenerator,
            fromSource: body.source,
            getWaterMark: {
                (try? r.resolve(assert: WaterMarkService.self))?.getWaterMarkImageByChatId($0.id, fillColor: nil) ?? .empty()
            },
            chatFromWhere: body.chatFromWhere
        )
        context.dataSourceAPI = messageDetailMessageVM
        context.pageAPI = messageDetailVC
        res.end(resource: messageDetailVC)
    }
}
