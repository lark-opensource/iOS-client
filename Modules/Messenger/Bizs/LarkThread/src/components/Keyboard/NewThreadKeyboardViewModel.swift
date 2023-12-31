//
//  NewThreadKeyboardViewModel.swift
//  LarkThread
//
//  Created by liluobin on 2021/9/8.
//

import Foundation
import UIKit
import LarkContainer
import LarkCore
import RxSwift
import RxCocoa
import RustPB
import LarkAccountInterface
import LarkSDKInterface
import LarkAttachmentUploader
import LarkMessengerInterface
import LarkMessageCore
import LKCommonsLogging
import LarkMessageBase
import LarkBaseKeyboard
import LarkChatOpenKeyboard

final class NewThreadKeyboardViewModel: ThreadKeyboardViewModel {
    static let logger = Logger.log(NewThreadKeyboardViewModel.self, category: "NewThreadKeyboardViewModel")
    var updateAttachmentManagerCallBack: (() -> Void)?
    var attachmentManager: PostAttachmentManager? {
        didSet {
            updateAttachmentManagerCallBack?()
        }
    }
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?

    func updateAttachmentUploaderIfNeed() {
        guard let keyboardJob = keyboardJob else {
            return
        }
        let chatID = self.chatWrapper.chat.value.id
        let draftId: DraftId

        switch keyboardJob {
        case .normal:
            draftId = .chat(chatId: chatID)
        case .reply(let info):
            let message = info.message
            draftId = isReplyInThread ? .replyInThread(messageId: message.id) : .replyMessage(messageId: message.id)
        case .multiEdit(let message):
            draftId = .multiEditMessage(messageId: message.id, chatId: chatID)
        case .quickAction:
            draftId = .chat(chatId: chatID)
        case .scheduleSend: // 定时发送
            draftId = .chat(chatId: chatID)
        case .scheduleMsgEdit(let message):
            draftId = .chat(chatId: chatID)
        }
        let key = ComposePostViewModel.postDraftFileKey(id: draftId, isNewTopic: false)
        if self.attachmentManager?.attachmentUploader.name ?? "" == key {
            return
        }
        guard let uploader = getAttachmentUploader(key) else { return }
        self.attachmentManager = PostAttachmentManager(attachmentUploader: uploader)
    }

    func savePostDraftWithMessageId(_ id: DraftId,
                                draft: String,
                                attachmentKeys: [String],
                                async: Bool,
                                callback: DraftCallback?) {
        self.delegate?.saveDraft(draft: draft, id: id)
        savePostDraftAttachment(attachmentKeys: attachmentKeys, id: id, async: async)
    }

    fileprivate func savePostDraftAttachment(attachmentKeys: [String],
                                             id: DraftId,
                                             async: Bool = true) {
        guard let attachmentManager = self.attachmentManager else {
            return
        }
        /// 生成草稿的key
        let key = ComposePostViewModel.postDraftFileKey(id: id,
                                                        isNewTopic: false)
        attachmentManager.savePostDraftAttachment(attachmentKeys: attachmentKeys, key: key, async: async, log: Self.logger)
    }

    override func getCurrentAttachmentServer() -> PostAttachmentServer? {
        return self.attachmentManager
    }
}
