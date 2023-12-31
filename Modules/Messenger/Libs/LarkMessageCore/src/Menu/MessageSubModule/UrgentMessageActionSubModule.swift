//
//  Urgent.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/5.
//

import Foundation
import LarkModel
import LarkCore
import LarkMessageBase
import EENavigator
import UniverseDesignToast
import LarkMessengerInterface
import LarkOpenChat
import LarkAccountInterface
import LarkSetting
import LarkContainer

public final class UrgentMessageActionSubModule: MessageActionSubModule {
    public override var type: MessageActionType {
        return .urgent
    }

    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    private lazy var groupPermissionLimit: Bool = {
        fgService?.staticFeatureGatingValue(with: "im.chat.only.admin.can.pin.vc.buzz") ?? false
    }()

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        let message = model.message
        let chat = model.chat
        let anonymousId = chat.anonymousId
        let replyMessage = message.threadMessageType == .threadReplyMessage
        let isMe = self.context.userResolver.userID == chat.chatterId || (!anonymousId.isEmpty && anonymousId == chat.chatterId)
        let isFromMe = message.fromId == self.context.userResolver.userID
        // 是可以加急的类型、
        // 是我发的消息
        // 不是我匿名发送的消息
        // 且不是与自己的对话中才有加急能力
        // 在聊天里有加急权限
        guard self.isCanUrgentType(message.type),
              !message.isAnnoymousSendFromMe,
              !isMe,
              !replyMessage,
              isFromMe,
              hasUrgentPermissionInChat(chat) else { return false }
        return true
    }

    private func hasUrgentPermissionInChat(_ chat: Chat) -> Bool {
        guard groupPermissionLimit else { return true }
        // single chat not limit
        if chat.type == .p2P { return true }
        // 服务台不支持加急
        if chat.isOncall { return false }
        if chat.type == .group || chat.chatMode == .threadV2 {
            // 群里有其他人才能发起加急
            if chat.userCount <= 1 { return false }
            switch chat.createUrgentSetting {
            case .allMembers:
                return true
            case .onlyManager:
                // owner or admin
                return chat.isGroupAdmin || chat.ownerId == self.context.userResolver.userID
            case .none, .some(_):
                assertionFailure("unknown type")
                return true
            @unknown default:
                return true
            }
        }
        assertionFailure("unknown chat type")
        return true
    }

    private func isCanUrgentType(_ type: Message.TypeEnum) -> Bool {
        switch type {
        case .audio, .text, .post, .image, .sticker, .media, .card, .location, .mergeForward, .shareGroupChat, .shareUserCard,
                .file, .folder, .videoChat, .hongbao, .commercializedHongbao, .shareCalendarEvent, .todo, .vote:
            return true
        case .generalCalendar, .calendar, .unknown, .system, .email:
            return false
        @unknown default:
            return false
        }
    }

    private func handle(message: Message, chat: Chat) {
        guard let targetVC = self.context.pageAPI else { return }
        if chat.chatterHasResign {
            if let window = targetVC.view.window {
                UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_ChatterResignPermissionUrgent, on: window)
            }
            return
        }

        UrgentTracker.trackMessageUrgentCreate(chat: chat, messageID: message.id, messageType: message.type.trackValue)
        switch chat.type {
        case .p2P:
            if let chatter = chat.chatter {
                self.context.nav.present(
                    body: UrgentChatterBody(chatterId: chatter.id, messageId: message.id, chat: chat, chatFromWhere: .ignored),
                    from: targetVC,
                    prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
                )
            }
        case .group, .topicGroup:
            self.context.nav.present(
                body: UrgentBody(messageId: message.id, urgentScene: .groupChat, chatFromWhere: .ignored),
                from: targetVC,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
            )
        @unknown default:
            assert(false, "new value")
            break
        }
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_MenuUrgent,
                                 icon: BundleResources.Menu.menu_urgent,
                                 trackExtraParams: ["click": "ding",
                                                    "target": "none"]) { [weak self] in
            self?.handle(message: model.message, chat: model.chat)
        }
    }
}
