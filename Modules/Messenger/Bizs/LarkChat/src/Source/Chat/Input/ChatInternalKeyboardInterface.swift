//
//  ChatInternalKeyboardInterface.swift
//  LarkChat
//
//  Created by liluobin on 2023/8/31.
//

import UIKit
import LarkChatKeyboardInterface
import LarkMessengerInterface
import LarkModel
import LarkKeyboardView
import LarkChatOpenKeyboard
import RustPB
import LarkSDKInterface

protocol ChatInternalKeyboardService: AfterFirstScreenMessagesRenderDelegate {
    var view: ChatKeyboardView? { get }
    var myAIQuickActionSendService: MyAIQuickActionSendService? { get }
    func getReplyMessageInfo() -> KeyboardJob.ReplyInfo?
    func clearReplyMessage()
    func setReplyMessage(message: Message, replyInfo: PartialReplyInfo?)
    func reEditMessage(message: Message)
    func multiEditMessage(message: Message)
    func setupStartupKeyboardState()
    func updateAttachmentSizeFor(attributedText: NSAttributedString)
    func getDraftMessageBy(lastDraftId: String,
                           callback: @escaping (LarkChatOpenKeyboard.DraftId?, LarkModel.Message?, RustPB.Basic_V1_Draft?) -> Void)
    func save(draft: String, id: DraftId, type: RustPB.Basic_V1_Draft.TypeEnum, callback: DraftCallback?)
    func saveInputViewDraft(isExitChat: Bool, callback: DraftCallback?)
    func actionAfterKeyboardInitDraftFinish(_ action: @escaping () -> Void)
    func reloadKeyBoard(rootMessage: Message)
    func insertRichText(richText: RustPB.Basic_V1_RichText)
    func updateAttributedString(message: Message,
                                isInsert: Bool,
                                callback: (() -> Void)?)
}

/// Chat键盘的所有能力不一定都需要对外暴漏
/// 一些负责的功能 可以内部使用，不对外开放
protocol ChatInputKeyboardService: ChatOpenKeyboardService,
                                   ChatInternalKeyboardService {
}
