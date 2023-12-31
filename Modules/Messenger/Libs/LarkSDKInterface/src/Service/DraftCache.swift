//
//  DraftCache.swift
//  Pods
//
//  Created by lichen on 2018/8/27.
//

import Foundation
import LarkModel
import RxCocoa
import RxSwift
import RustPB

public enum DraftCacheType {
    case chat(String, DraftInfo)
    case message(String, DraftInfo)
    case editMessage(String, DraftInfo)
    case scheduleMessage(String, DraftInfo)
}

public typealias DraftInfo = (messageId: String?,
                              isDelete: Bool,
                              type: RustPB.Basic_V1_Draft.TypeEnum,
                              content: String,
                              scheduleTime: Int64?)

public typealias DraftCallback = (_ draft: RustPB.Basic_V1_Draft?, _ error: Error?) -> Void

public protocol DraftCache {
    var cacheChangeSignal: Driver<DraftCacheType> { get }

    func getDraft(key: String) -> Observable<(content: String, partialReplyInfo: RustPB.Basic_V1_Message.PartialReplyInfo?)>

    func getDraftModel(draftID: String) -> Observable<RustPB.Basic_V1_Draft?>

    func deleteDraft(key: String, chatId: String, type: RustPB.Basic_V1_Draft.TypeEnum)

    func deleteDraft(key: String, messageID: String, type: RustPB.Basic_V1_Draft.TypeEnum)

    func deleteDraft(key: String, editMessageId: String, chatId: String)

    func deleteScheduleDraft(key: String, messageId: String?, chatId: String)

    func saveDraft(chatId: String,
                   type: RustPB.Basic_V1_Draft.TypeEnum,
                   content: String,
                   callback: DraftCallback?)

    // 保持定时消息草稿
    func saveScheduleMsgDraft(chatId: String,
                              parentMessageId: String?,
                              content: String,
                              time: Int64,
                              item: RustPB.Basic_V1_ScheduleMessageItem,
                              callback: DraftCallback?)

    func saveScheduleMsgDraft(chatId: String,
                              parentMessageId: String?,
                              content: String,
                              partialReplyInfo: RustPB.Basic_V1_Message.PartialReplyInfo?,
                              time: Int64,
                              item: RustPB.Basic_V1_ScheduleMessageItem,
                              callback: DraftCallback?)

    func saveDraft(messageId: String, type: RustPB.Basic_V1_Draft.TypeEnum, content: String, callback: DraftCallback?)

    func saveDraft(messageId: String,
                   type: RustPB.Basic_V1_Draft.TypeEnum,
                   partialReplyInfo: PartialReplyInfo?,
                   content: String,
                   callback: DraftCallback?)

    /// msg thread使用新的草稿接口 类型为MSG_THREAD
    func saveDraft(msgThreadId: String, content: String, callback: DraftCallback?)
    /// 删除MSG_THREAD草稿
    func deleteDraft(key: String, threadId: String)

    func saveDraft(editMessageId: String, chatId: String, content: String, callback: DraftCallback?)

    func saveThreadTabDraft(content: String, callback: DraftCallback?)

    func deleteThreadTabDraft()

    func fetchThreadTabDraft() -> Observable<String>
}
