//
//  Forward.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/5.
//

import Foundation
import LarkOpenChat
import LarkModel
import LarkMessengerInterface
import EENavigator
import LarkCore
import UniverseDesignToast
import LarkFeatureGating
import LarkContainer

public class ForwardMessageActionSubModule: MessageActionSubModule {
    @ScopedInjectedLazy private var replyInThreadConfig: ReplyInThreadConfigService?
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?

    public override var type: MessageActionType {
        return .forward
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    fileprivate var originMergeForwardId: String? {
        return (context as? PrivateThreadMessageActionContext)?.originMergeForwardId
    }

    func getForwardOriginMergeForwardId(message: Message) -> String? {
        return originMergeForwardId
    }

    fileprivate func handle(message: Message, chat: Chat) {
        guard let targetVC = self.context.pageAPI else { return }
        let body = ForwardMessageBody(originMergeForwardId: getForwardOriginMergeForwardId(message: message),
                                      message: message, type: .message(message.id),
                                      from: .chat,
                                      supportToMsgThread: true,
                                      traceChatType: .group)
        if chat.enableRestricted(.forward) {
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_RestrictedMode_CopyForwardNotAllow_Toast, on: targetVC.view)
            return
        }
        self.context.nav.present(
            body: body,
            from: targetVC,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
        )
    }

    private func threadForwardhandle(message: Message, chat: Chat) {
        guard let targetVC = self.context.pageAPI else { return }
        if chat.enableRestricted(.forward) {
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_RestrictedMode_CopyForwardNotAllow_Toast, on: targetVC.view)
            return
        }
        let body = MergeForwardMessageBody(
            originMergeForwardId: nil,
            fromChannelId: chat.id,
            messageIds: [message.id],
            threadRootMessage: message,
            title: BundleI18n.LarkMessageCore.Lark_Legacy_ForwardGroupChatHistory,
            forwardThread: true,
            traceChatType: .thread,
            finishCallback: nil,
            supportToMsgThread: true,
            isMsgThread: true,
            containBurnMessage: message.isOnTimeDel
        )
        self.context.nav.present(
            body: body,
            from: targetVC,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        let message = model.message
        if message.threadMessageType != .threadRootMessage {
            return self.canForward(message: message, chat: model.chat)
        } else if replyInThreadConfig?.canForwardThread(message: message) ?? false {
            return true
        } else {
            return false
        }
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        let trackExtraParams: [AnyHashable: Any] = ["click": "forward",
                 "forward_type": forwardTypeTrack,
                 "target": "public_multi_select_share_view"]
        if model.message.threadMessageType == .threadRootMessage {
            return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IM_Thread_ForwardCompleteThread_Tooltip,
                                     icon: BundleResources.Menu.menu_forward_thread,
                                     trackExtraParams: trackExtraParams) { [weak self] in
                self?.threadForwardhandle(message: model.message, chat: model.chat)
            }
        } else {
            return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_MenuForward,
                                     icon: BundleResources.Menu.menu_forward,
                                     trackExtraParams: trackExtraParams) { [weak self] in
                self?.handle(message: model.message, chat: model.chat)
            }
        }
    }

    func canForward(message: Message, chat: Chat) -> Bool {
        if context.userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.disable_announcement.client"),
           (message.content as? PostContent)?.isGroupAnnouncement ?? false {
            return false
        }
        guard self.chatSecurityControlService?.getDynamicAuthorityFromCache(event: .receive,
                                                                            message: message,
                                                                            anonymousId: chat.anonymousId).authorityAllowed ?? false else { return false }

        switch message.type {
        case .text, .post, .image, .media, .shareGroupChat, .shareUserCard,
                .mergeForward, .location, .shareCalendarEvent, .sticker, .videoChat, .calendar:
            return true
        case .audio:
            return false
        case .file:
            // 局域网文件不支持转发
            if let fileContent = message.content as? FileContent {
                return fileContent.fileSource != .lanTrans
            }
            return true
        case .folder:
            // 局域网文件夹不支持转发
            if let folderContent = message.content as? FolderContent {
                return folderContent.fileSource != .lanTrans
            }
            return true
        case .card:
            /// 消息卡片转发
            guard !message.isEphemeral else {
                return false
            }

            /// 卡片需要FG控制
            guard self.context.getFeatureGating(.init(key: .messageCardForward)) else {
                return false
            }

            if (message.content as? CardContent)?.enableForward ?? false {
                return true
            }
            return false
        case .todo:
            if let todo = message.content as? TodoContent {
                return !todo.isFromBot
            }
            return false
        case .email, .hongbao, .vote,
                .commercializedHongbao, .system,
                .unknown:
            return false
        case .generalCalendar:
            switch message.content {
            case is GeneralCalendarEventRSVPContent,
                is RoundRobinCardContent,
                is SchedulerAppointmentCardContent:
                return true
            default:
                return false
            }
        @unknown default:
            return false
        }
    }

    var forwardTypeTrack: String {
        "normal"
    }

}

public final class ForwardMessageActionSubModuleInThread: ForwardMessageActionSubModule {
    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        return self.canForward(message: model.message, chat: model.chat)
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_MenuForward,
                                 icon: BundleResources.Menu.menu_forward,
                                 trackExtraParams: [:]) { [weak self] in
            self?.handle(message: model.message, chat: model.chat)
        }
    }
}

public final class ForwardMessageActionSubModuleInMergeForward: ForwardMessageActionSubModule {

    override var forwardTypeTrack: String {
        "merge"
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        guard self.context.userResolver.fg.dynamicFeatureGatingValue(with: "messenger.combine_forward.forward") else {
            return false
        }
        return super.canHandle(model: model)
    }

    override func getForwardOriginMergeForwardId(message: Message) -> String? {
        return originMergeForwardIdFor(message)
    }

    private func originMergeForwardIdFor(_ message: Message) -> String? {
        /// 没有 fatherMFMessage直接返回
        guard let msg = message.fatherMFMessage else {
            return nil
        }
        var fatherMFMessage: Message = msg
        let maxNestCount = 10
        for _ in 0..<maxNestCount {
            if let mfMessage = fatherMFMessage.fatherMFMessage {
                fatherMFMessage = mfMessage
                continue
            }
            return fatherMFMessage.id
        }
        return nil
    }
}
