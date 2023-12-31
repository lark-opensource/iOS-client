//
//  ChatInputViewModel.swift
//  LarkChat
//
//  Created by liluobin on 2021/8/30.
//

import Foundation
import UIKit
import LarkContainer
import LarkModel
import LarkCore
import RxSwift
import RxCocoa
import LarkAttachmentUploader
import LarkMessageCore
import LarkMessengerInterface
import LarkSendMessage
import LarkMessageBase
import LarkAccountInterface
import LarkSDKInterface
import LarkGuide
import RustPB
import LarkBaseKeyboard
import LarkChatOpenKeyboard
import LarkAIInfra
import LarkChatKeyboardInterface

public protocol AIQuickActionSendService {
    /// 发送 AI 的快捷指令消息（API、Prompt 类型）
    func sendAIQuickAction(content: RustPB.Basic_V1_RichText,
                           chatId: String,
                           position: Int32,
                           quickActionID: String,
                           quickActionParams: [String: String]?,
                           quickActionBody: AIQuickAction?,
                           callback: ((SendMessageState) -> Void)?)

    /// 发送 AI 的快捷指令消息（Query 类型）
    func sendAIQuery(content: RustPB.Basic_V1_RichText,
                     chatId: String,
                     position: Int32,
                     quickActionBody: AIQuickAction?,
                     callback: ((SendMessageState) -> Void)?)
}
public protocol ChatKeyboardMessageSendService: KeyboardMoreItemSendService,
                                                ChatOpenKeyboardSendService,
                                                AIQuickActionSendService {
    /// 发送普通文本消息 -> 不设定时发送
    func sendText(content: RustPB.Basic_V1_RichText,
                  lingoInfo: RustPB.Basic_V1_LingoOption?,
                  parentMessage: Message?,
                  chatId: String,
                  position: Int32,
                  quasiMsgCreateByNative: Bool,
                  callback: ((SendMessageState) -> Void)?)
}

/// 草稿的问题
public final class ChatInputViewModel: DefaultInputViewModel {
    var attachmentManager: PostAttachmentManager?
    var updateAttachmentManagerCallBack: (() -> Void)?
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?
    @ScopedInjectedLazy var newGuideManager: NewGuideService?
    @ScopedInjectedLazy var postSendService: PostSendService?

    var draftMessage: Message? {
        return draftReplyInfo?.message
    }

    var draftReplyInfo: KeyboardJob.ReplyInfo? {
        var info: KeyboardJob.ReplyInfo?
        if let replyInfo = self.keyboardStatusManagerBlock?()?.getReplyInfo() {
            info = replyInfo
        } else if let rootMessage = self.rootMessage {
            info = KeyboardJob.ReplyInfo(message: rootMessage, partialReplyInfo: nil)
        }
        return info
    }

    override init(userResolver: UserResolver,
                  chatWrapper: @escaping () -> ChatPushWrapper,
                  messageSender: ChatKeyboardMessageSendService?,
                  pushChannelMessage: Driver<PushChannelMessage>,
                  pushChat: Driver<PushChat>,
                  rootMessage: Message?,
                  itemsTintColor: UIColor? = nil,
                  supportAfterMessagesRender: Bool,
                  getAttachmentUploader: @escaping ((String) -> AttachmentUploader?),
                  supportDraft: Bool) {
        let key = ComposePostViewModel.postDraftFileKey(id: rootMessage == nil ? .chat(chatId: chatWrapper().chat.value.id) : .replyMessage(messageId: rootMessage?.id ?? ""),
                                                        isNewTopic: false)
        if let attachmentUploader = getAttachmentUploader(key) {
            attachmentManager = PostAttachmentManager(attachmentUploader: attachmentUploader)
        }
        super.init(userResolver: userResolver,
                   chatWrapper: chatWrapper,
                   messageSender: messageSender,
                   pushChannelMessage: pushChannelMessage,
                   pushChat: pushChat,
                   rootMessage: rootMessage,
                   itemsTintColor: itemsTintColor,
                   supportAfterMessagesRender: supportAfterMessagesRender,
                   getAttachmentUploader: getAttachmentUploader,
                   supportDraft: supportDraft)
    }

    override func cleanReplyMessage() {
        guard let keyboardStatusManager = self.keyboardStatusManagerBlock?() else {
            return
        }
        if let replyMessage = keyboardStatusManager.getReplyMessage() {
            keyboardStatusManager.switchToDefaultJob()
            draftCache?.deleteDraft(key: replyMessage.postDraftId, messageID: replyMessage.id, type: .post)
        }
    }

    func cleanPostDraft() {
        guard let draftCache else { return }
        let draftKey = self.postDraftKey()

        switch self.keyboardJob {
        case .multiEdit(let message):
            draftCache.deleteDraft(key: draftKey, editMessageId: message.id, chatId: chatModel.id)
        case .scheduleSend, .scheduleMsgEdit:
            let id = self.rootMessage == nil ? chatModel.scheduleMessageDraftID : (self.rootMessage?.scheduleMessageDraftId ?? "")
            Self.logger.info("getScheduleDraft delete")
            draftCache.deleteScheduleDraft(key: id, messageId: rootMessage?.id, chatId: chatModel.id)
        default:
            if let messageId = draftMessage?.id {
                draftCache.deleteDraft(key: draftKey, messageID: messageId, type: .post)
            } else {
                draftCache.deleteDraft(key: draftKey, chatId: chatModel.id, type: .post)
            }
        }
        self.attachmentManager?.attachmentUploader.cleanPostDraftAttachment()
    }

    func updateAttachmentUploaderIfNeed() {
        let chatID = self.chatWrapper.chat.value.id
        let draftId: DraftId
        if let replyMessage = draftMessage {
            draftId = .replyMessage(messageId: replyMessage.id)
        } else {
            draftId = .chat(chatId: chatID)
        }
        let key = ComposePostViewModel.postDraftFileKey(id: draftId, isNewTopic: false)
        if attachmentManager?.attachmentUploader.name != key, let attachmentUploader = getAttachmentUploader(key) {
            attachmentManager = PostAttachmentManager(attachmentUploader: attachmentUploader)
        }
        updateAttachmentManagerCallBack?()
    }

    override func getCurrentAttachmentServer() -> PostAttachmentServer? {
        return attachmentManager
    }

    override func getCurrentDraftContent() -> Observable<(content: String, partialReplyInfo: RustPB.Basic_V1_Message.PartialReplyInfo?)> {
        guard let draftCache else { return .just(("", nil)) }
        if let multiEditMessage = self.keyboardStatusManagerBlock?()?.getMultiEditMessage() {
            return draftCache.getDraft(key: multiEditMessage.editDraftId)
        } else if let replyMessage = self.replyMessage {
            return draftCache.getDraft(key: replyMessage.postDraftId)
        } else if let rootMessage = self.rootMessage {
            return draftCache.getDraft(key: rootMessage.postDraftId)
        } else {
            return draftCache.getDraft(key: chatWrapper.chat.value.postDraftId)
        }
    }
    /// 获取当前的Text草稿
    func getTextDraftContent() -> Observable<(content: String, partialReplyInfo: RustPB.Basic_V1_Message.PartialReplyInfo?)> {
        return super.getCurrentDraftContent()
    }
    /// 使用基类的方式，清空注意下当前的Text草稿
    func cleanTextDraft() {
        super.saveInputViewDraft(content: "",
                                 callback: nil)
    }

    /// 存储草稿信息
    func saveInputViewDraft(draft: String,
                            attachmentKeys: [String],
                            async: Bool,
                            isExitChat: Bool = false,
                            callback: DraftCallback?) {
        guard let keyboardJob = self.keyboardJob else {
            return
        }

        let draftId: DraftId
        if case .multiEdit(let editMessage) = keyboardJob {
            draftId = .multiEditMessage(messageId: editMessage.id, chatId: self.chatModel.id)
        } else if case .scheduleSend(let info) = keyboardJob {
            let parentMessage = info?.message
            let time: Int64 = Int64(self.scheduleTime ?? 0)
            var item = RustPB.Basic_V1_ScheduleMessageItem()
            item.itemType = .quasiScheduleMessage
            draftId = .schuduleSend(chatId: self.chatModel.id,
                                    time: time,
                                    partialReplyInfo: info?.partialReplyInfo,
                                    parentMessage: parentMessage,
                                    item: item)
        } else if case .scheduleMsgEdit(let info, _, _) = keyboardJob {
            let msg = info?.message
            // 定时编辑下只有chat页面离开时才保存草稿
            guard rootMessage == nil, isExitChat else { return }
            let time: Int64 = Int64(self.scheduleTime ?? 0)
            var item = RustPB.Basic_V1_ScheduleMessageItem()
            item.itemID = msg?.id ?? ""
            item.itemType = msg?.id == msg?.cid ? .quasiScheduleMessage : .scheduleMessage

            draftId = .schuduleSend(chatId: self.chatModel.id,
                                    time: time,
                                    partialReplyInfo: info?.partialReplyInfo,
                                    parentMessage: msg?.parentMessage,
                                    item: item)
        } else if let replyInfo = self.draftReplyInfo {
            draftId = .replyMessage(messageId: replyInfo.message.id, partialReplyInfo: replyInfo.partialReplyInfo)
        } else {
            draftId = .chat(chatId: self.chatModel.id)
        }
        /// 如果被禁言则删除草稿（二次编辑草稿除外）
        if !chatModel.isAllowPost {
            switch draftId {
            case .multiEditMessage, .schuduleSend:
                savePostDraftWithMessageId(id: draftId,
                                           draft: draft,
                                           attachmentKeys: attachmentKeys,
                                           async: async,
                                           callback: callback)
            default:
                save(draft: "",
                     id: draftId,
                     type: .post,
                     callback: callback)
            }
        } else {
            savePostDraftWithMessageId(id: draftId,
                                       draft: draft,
                                       attachmentKeys: attachmentKeys,
                                       async: async,
                                       callback: callback)
        }
    }

    func savePostDraftWithMessageId(id: DraftId,
                                    draft: String,
                                    attachmentKeys: [String],
                                    async: Bool,
                                    callback: DraftCallback?) {
        save(draft: draft, id: id, type: .post, callback: callback)
        savePostDraftAttachment(attachmentKeys: attachmentKeys,
                                id: id,
                                async: async)
    }

    func saveScheduleDraft(id: DraftId,
                           draft: String,
                           attachmentKeys: [String],
                           async: Bool,
                           callback: DraftCallback?) {
        save(draft: draft, id: id, type: .scheduleMessage, callback: callback)
        savePostDraftAttachment(attachmentKeys: attachmentKeys,
                                id: id,
                                async: async)
    }

    fileprivate func savePostDraftAttachment(attachmentKeys: [String],
                                             id: DraftId,
                                             async: Bool = true) {
        /// 生成草稿的key
        let key = ComposePostViewModel.postDraftFileKey(id: id,
                                                        isNewTopic: false)
        attachmentManager?.savePostDraftAttachment(attachmentKeys: attachmentKeys, key: key, async: async, log: Self.logger)
    }

}
