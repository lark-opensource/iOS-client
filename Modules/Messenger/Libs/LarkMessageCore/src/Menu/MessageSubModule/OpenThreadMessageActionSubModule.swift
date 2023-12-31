//
//  CreateThread.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/5.
//

import Foundation
import LarkOpenChat
import LarkModel
import LarkCore
import EENavigator
import LarkMessageBase
import LKCommonsLogging
import LarkMessengerInterface
import UniverseDesignToast
import LarkContainer

public class ReplyInThreadMessageActionSubModule: MessageActionSubModule {

    @ScopedInjectedLazy var abTestService: MenuInteractionABTestService?

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    static let logger = Logger.log(OpenThreadMessageActionSubModule.self, category: "MessageCore")

    fileprivate func handle(message: Message, chat: Chat, keyboardStartupState: KeyboardStartupState = .init(type: .none)) {
        guard let targetVC = self.context.pageAPI else { return }
        let loadType: ThreadDetailLoadType
        var threadId: String
        switch message.threadMessageType {
        case .unknownThreadMessage:
            threadId = message.id
            if message.syncToChatThreadRootMessage != nil {
                loadType = .unread
            } else {
                loadType = .root
            }
        case .threadRootMessage:
            threadId = message.id
            loadType = .unread
        case .threadReplyMessage:
            Self.logger.error("OpenThreadMessageActionSubModule: threadMessageType error")
            assertionFailure("threadMessageType error")
            return
        @unknown default:
            return
        }
        let targetMessage: Message
        if let rootMessage = message.syncToChatThreadRootMessage {
            threadId = rootMessage.id
            targetMessage = rootMessage
        } else {
            targetMessage = message
        }
        let body = ReplyInThreadByModelBody(message: targetMessage,
                                 chat: chat,
                                 loadType: loadType,
                                 keyboardStartupState: keyboardStartupState,
                                 sourceType: .chat,
                                 chatFromWhere: .ignored)
        self.context.nav.push(body: body, from: targetVC)
    }

    fileprivate func getTrackExtraParams(chat: Chat, isOpenThread: Bool, threadId: String) -> [AnyHashable: Any] {

        var value: [AnyHashable: Any] = [:]
        switch abTestService?.abTestResult ?? .none {
        case .gentle:
            value["click"] = "reply_in_thread"
            value["ab_version"] = 1
        case .radical:
            value["click"] = "reply_in_thread"
            value["ab_version"] = 2
        case .none:
            value["click"] = isOpenThread ? "check_thread" : "create_thread"
            if !chat.isCrypto {
                value["ab_version"] = 0
            }
        }
        value["target"] = "im_thread_detail_view"
        value["thread_id"] = threadId
        return value
    }
}

public final class OpenThreadMessageActionSubModule: ReplyInThreadMessageActionSubModule {
    public override var type: MessageActionType {
        return .openThread
    }
    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        return model.message.threadMessageType == .threadRootMessage || model.message.syncToChatThreadRootMessage != nil
    }
    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        let message = model.message
        return MessageActionItem(text: abTestService?.threadReplyMenuTitle(chat: model.chat) ??
                                 BundleI18n.LarkMessageCore.Lark_IM_Thread_ViewThread_Tooltip,
                                 icon: BundleResources.Menu.menu_open_thread,
                                 trackExtraParams: getTrackExtraParams(chat: model.chat,
                                                                       isOpenThread: true,
                                                                       threadId: message.threadId.isEmpty ? message.id : message.threadId)) { [weak self] in
            self?.handle(message: model.message, chat: model.chat)
        }
    }
}

public final class CreateThreadMessageActionSubModule: ReplyInThreadMessageActionSubModule {
    // https://bytedance.feishu.cn/docx/doxcnAijkQVHZDEodrehSxqFxrb
    @ScopedInjectedLazy private var replyInThreadConfig: ReplyInThreadConfigService?
    public override var type: MessageActionType {
        return .createThread
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        return model.message.threadMessageType == .unknownThreadMessage
        && (model.message.syncToChatThreadRootMessage == nil)
        && replyInThreadConfig?.canCreateThreadForChat(model.chat) ?? false
        && replyInThreadConfig?.canReplyInThread(message: model.message) ?? false
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        let message = model.message
        return MessageActionItem(text: abTestService?.threadReplyMenuTitle(chat: model.chat) ??
                                 BundleI18n.LarkMessageCore.Lark_IM_Thread_StartThread_Button,
                                 icon: BundleResources.Menu.menu_create_thread,
                                 trackExtraParams: getTrackExtraParams(chat: model.chat, isOpenThread: false, threadId: message.threadId.isEmpty ? message.id : message.threadId)) { [weak self] in
            self?.handle(message: model.message, chat: model.chat, keyboardStartupState: .init(type: .inputView))
        }
    }
}
