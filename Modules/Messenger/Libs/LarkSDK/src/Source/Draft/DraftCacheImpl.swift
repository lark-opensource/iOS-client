//
//  DraftCacheImpl.swift
//  Lark
//
//  Created by lichen on 2017/7/5.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import RustPB
import Foundation
import RxSwift
import RxCocoa
import Kingfisher
import LarkModel
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import LarkMessageBase

final class DraftCacheImpl: DraftCache {

    private static let logger = Logger.log(DraftCacheImpl.self, category: "DraftCacheImpl")

    private lazy var scheduler: ImmediateSchedulerType = {
        let queue = DispatchQueue(label: "draft.cache.impl")
        let schedulerType = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: queue.label)
        return schedulerType
    }()

    private let cacheChangeSubject = PublishSubject<DraftCacheType>()
    var cacheChangeSignal: Driver<DraftCacheType> {
        return self.cacheChangeSubject.asDriver(onErrorRecover: { _ in Driver<DraftCacheType>.empty() })
    }

    private lazy var draftQueue: OperationQueue = {
        let queue: OperationQueue = OperationQueue()
        queue.name = "draft.cache.serialQueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    let draftAPI: DraftAPI
    let chatAPI: ChatAPI
    let messageAPI: MessageAPI

    private let disposeBag: DisposeBag = DisposeBag()

    init(draftAPI: DraftAPI, chatAPI: ChatAPI, messageAPI: MessageAPI) {
        self.draftAPI = draftAPI
        self.chatAPI = chatAPI
        self.messageAPI = messageAPI
    }

    func getDraft(key: String) -> Observable<(content: String, partialReplyInfo: RustPB.Basic_V1_Message.PartialReplyInfo?)> {
        guard !key.isEmpty else {
            return Observable<(content: String, partialReplyInfo: RustPB.Basic_V1_Message.PartialReplyInfo?)>.just(("", nil))
        }
        return self.getDraftModel(draftID: key).map { (draft) -> (String, RustPB.Basic_V1_Message.PartialReplyInfo?) in
            return (content: draft?.content ?? "", partialReplyInfo: draft?.hasPartialReplyInfo == true ? draft?.partialReplyInfo : nil)
        }
    }

    /// - Returns: 这里草稿有问题 获取不到Im_V1_GetDraftsRequest
    func getDraftModel(draftID: String) -> Observable<Draft?> {
        let observable = self.draftAPI.getDraft(keys: [draftID]).map { (drafts) -> Draft? in
            let draft = drafts[draftID]
            DraftCacheImpl.logger.info("DraftCacheImpl getDraftModel",
                                       additionalData: ["chatId": String(describing: draft?.chatID),
                                                        "messageId": String(describing: draft?.messageID),
                                                        "draftLength": String(describing: draft?.content.count),
                                                        "partialReplyInfo.position": String(describing: draft?.partialReplyInfo.position),
                                                        "draftType": String(describing: draft?.type)])
            return drafts[draftID]
        }
        return serial(observable)
    }

    func deleteDraft(key: String, chatId: String, type: Draft.TypeEnum) {
        let observable = self.deleteDraft(draftID: key, chatId: chatId, type: type)
        serial(observable).subscribe().disposed(by: self.disposeBag)
    }

    func deleteDraft(key: String, messageID: String, type: Draft.TypeEnum) {
        let observable = self.deleteDraft(draftID: key, messageId: messageID, type: type)
        serial(observable).subscribe().disposed(by: self.disposeBag)
    }

    func deleteDraft(key: String, editMessageId: String, chatId: String) {
        let observable = self.deleteDraft(draftID: key, chatId: chatId, editMessageId: editMessageId, type: .editMessage)
        serial(observable).subscribe().disposed(by: self.disposeBag)
    }

    func deleteScheduleDraft(key: String, messageId: String?, chatId: String) {
        guard key.isEmpty == false else { return }
        let observable = self.deleteDraft(draftID: key, chatId: chatId, messageId: messageId, type: .scheduleMessage)
        serial(observable).subscribe().disposed(by: self.disposeBag)
    }

    func deleteDraft(key: String, threadId: String) {
        let observable = self.deleteDraft(draftID: key,
                                          chatId: nil,
                                          messageId: nil,
                                          threadId: threadId,
                                          type: .msgThread)
        serial(observable).subscribe().disposed(by: self.disposeBag)
    }

    func saveScheduleMsgDraft(chatId: String,
                              parentMessageId: String?,
                              content: String,
                              partialReplyInfo: RustPB.Basic_V1_Message.PartialReplyInfo?,
                              time: Int64,
                              item: RustPB.Basic_V1_ScheduleMessageItem,
                              callback: DraftCallback?) {
        let observable = self.chatAPI.fetchChats(by: [chatId], forceRemote: false).flatMap { [weak self] (chatDic) -> Observable<Draft?> in
            guard let chat = chatDic[chatId], let self = self else { return .just(nil) }
            var scheduleInfo = RustPB.Basic_V1_Draft.ScheduleInfo()
            scheduleInfo.scheduleTime = time
            scheduleInfo.item = item
            return self.saveDraft(chatId: chatId,
                                  messageId: parentMessageId,
                                  editMessageId: nil,
                                  scheduleInfo: scheduleInfo,
                                  partialReplyInfo: partialReplyInfo,
                                  type: .scheduleMessage,
                                  content: content).flatMap(self.saveTransform)
            return .just(nil)
        }
        serial(observable).subscribe(onNext: { (draft) in
            callback?(draft, nil)
        }, onError: { (error) in
            callback?(nil, error)
        }).disposed(by: self.disposeBag)
    }
    // 保存定时消息草稿
    func saveScheduleMsgDraft(chatId: String,
                              parentMessageId: String?,
                              content: String,
                              time: Int64,
                              item: RustPB.Basic_V1_ScheduleMessageItem,
                              callback: DraftCallback?) {
        self.saveScheduleMsgDraft(chatId: chatId,
                                  parentMessageId: parentMessageId,
                                  content: content,
                                  partialReplyInfo: nil,
                                  time: time,
                                  item: item,
                                  callback: callback)
    }

    func saveDraft(chatId: String,
                   type: Draft.TypeEnum,
                   content: String,
                   callback: DraftCallback?) {
        let observable = self.chatAPI.fetchChats(by: [chatId], forceRemote: false).flatMap { [weak self] (chatDic) -> Observable<Draft?> in
            guard let chat = chatDic[chatId], let self = self else { return Observable<Draft?>.just(nil) }
            if !content.isEmpty {
                return self.saveDraft(chatId: chatId, messageId: nil, editMessageId: nil, type: type, content: content).flatMap(self.saveTransform)
            } else if type == .text && !chat.textDraftId.isEmpty {
                return self.deleteDraft(draftID: chat.textDraftId, chatId: chat.id, type: .text).flatMap(self.deleteTransform)
            } else if type == .post && !chat.postDraftId.isEmpty {
                return self.deleteDraft(draftID: chat.postDraftId, chatId: chat.id, type: .post).flatMap(self.deleteTransform)
            }
            return Observable<Draft?>.just(nil)
        }
        serial(observable).subscribe(onNext: { (draft) in
            callback?(draft, nil)
        }, onError: { (error) in
            callback?(nil, error)
        }).disposed(by: self.disposeBag)
    }

    func saveDraft(messageId: String,
                   type: RustPB.Basic_V1_Draft.TypeEnum,
                   partialReplyInfo: PartialReplyInfo?,
                   content: String,
                   callback: LarkSDKInterface.DraftCallback?) {
        let observable = self.getMessageInGlobalThread(messageId).flatMap { [weak self] (message) -> Observable<Draft?> in
            guard let self = self else { return Observable<Draft?>.just(nil) }
            if !content.isEmpty {
                return self.saveDraft(chatId: nil,
                                      messageId: messageId,
                                      editMessageId: nil,
                                      partialReplyInfo: partialReplyInfo,
                                      type: type,
                                      content: content).flatMap(self.saveTransform)
            } else if type == .text && !message.textDraftId.isEmpty {
                return self.deleteDraft(draftID: message.textDraftId, messageId: message.id, type: .text).flatMap(self.deleteTransform)
            } else if type == .post && !message.postDraftId.isEmpty {
                return self.deleteDraft(draftID: message.postDraftId, messageId: message.id, type: .post).flatMap(self.deleteTransform)
            }
            return Observable<Draft?>.just(nil)
        }
        serial(observable).subscribe(onNext: { (draft) in
            callback?(draft, nil)
        }, onError: { (error) in
            callback?(nil, error)
        }).disposed(by: self.disposeBag)
    }

    func saveDraft(messageId: String, type: Draft.TypeEnum, content: String, callback: DraftCallback?) {
        self.saveDraft(messageId: messageId,
                       type: type,
                       partialReplyInfo: nil,
                       content: content,
                       callback: callback)
    }

    func saveDraft(editMessageId: String, chatId: String, content: String, callback: DraftCallback?) {
        let observable = self.getMessageInGlobalThread(editMessageId).flatMap { [weak self] (message) -> Observable<Draft?> in
            guard let self = self else { return Observable<Draft?>.just(nil) }
            if !content.isEmpty {
                return self.saveDraft(chatId: chatId, messageId: nil, editMessageId: editMessageId, type: .editMessage, content: content).flatMap(self.saveTransform)
            } else if !message.editDraftId.isEmpty {
                return self.deleteDraft(draftID: message.editDraftId, editMessageId: message.id, type: .editMessage).flatMap(self.deleteTransform)
            }
            return Observable<Draft?>.just(nil)
        }
        serial(observable).subscribe(onNext: { (draft) in
            callback?(draft, nil)
        }, onError: { (error) in
            callback?(nil, error)
        }).disposed(by: self.disposeBag)
    }

    func saveDraft(msgThreadId: String, content: String, callback: DraftCallback?) {
        let observable = self.getMessageInGlobalThread(msgThreadId).flatMap { [weak self] (message) -> Observable<Draft?> in
            guard let self = self else { return Observable<Draft?>.just(nil) }
            if !content.isEmpty {
                return self.saveDraft(chatId: nil,
                                      messageId: nil,
                                      editMessageId: nil,
                                      threadId: msgThreadId,
                                      type: .msgThread,
                                      content: content).flatMap(self.saveTransform)
            } else if !message.msgThreadDraftId.isEmpty {
                return self.deleteDraft(draftID: message.msgThreadDraftId,
                                        threadId: msgThreadId,
                                        type: .msgThread).flatMap(self.deleteTransform)
            }
            return Observable<Draft?>.just(nil)
        }
        serial(observable).subscribe(onNext: { (draft) in
            callback?(draft, nil)
        }, onError: { (error) in
            callback?(nil, error)
        }).disposed(by: self.disposeBag)
    }

    /// use async serial queue to handle  save draft task to keep right order
    /// - Parameter observable: update/delete draft task observable
    private func serial<T>(_ observable: Observable<T>, uuid: String = UUID().uuidString) -> Observable<T> {
        return Observable<T>.create { [weak self] (observer) -> Disposable in
            var disposable: Disposable?
            var disposed: Bool = false
            if let self = self {
                /// add async task to queue
                self.draftQueue.addAsyncBlock { (callback) in
                    if disposed {
                        callback()
                        return
                    }
                    disposable = observable.subscribe(onNext: { (result) in
                        observer.onNext(result)
                    }, onError: { (error) in
                        observer.onError(error)
                        callback()
                    }, onCompleted: {
                        observer.onCompleted()
                        callback()
                    })
                }
            } else {
                observer.onCompleted()
            }
            return Disposables.create {
                disposable?.dispose()
                disposed = true
            }
        }
    }

    private func deleteDraft(
        draftID: String,
        chatId: String? = nil,
        messageId: String? = nil,
        editMessageId: String? = nil,
        threadId: String? = nil,
        type: Draft.TypeEnum) -> Observable<Void> {
            let draft = self.createDraftModel(draftID: draftID,
                                              chatId: chatId,
                                              messageId: messageId,
                                              editMessageId: editMessageId,
                                              threadId: threadId,
                                              type: type)
        return self.deleteDraft(draft: draft)
    }

    private func deleteDraft(draft: Draft) -> Observable<Void> {
        let draftAPI = self.draftAPI
        DraftCacheImpl.logger.info("DraftCacheImpl deleteDraft", additionalData: ["chatId": draft.chatID,
                                                                                  "messageId": draft.messageID,
                                                                                  "editMessageId": draft.editMessageID,
                                                                                  "draftLength": "\(draft.content.count)",
                                                                                  "draftType": "\(draft.type)"])
        return self.notifiationDraftChange(draft: draft, isDelete: true).flatMap { (draft) -> Observable<Void> in
            return draftAPI.deleteDraft(key: draft.id).do(onError: { (error) in
                DraftCacheImpl.logger.error(
                    "delete draft failed",
                    additionalData: ["key": draft.content],
                    error: error
                )
            })
        }
    }

    private var deleteTransform: (()) throws -> Observable<Draft?> = { (_) -> Observable<Draft?> in
        return Observable<Draft?>.just(nil)
    }

    private var saveTransform: (Draft) throws -> Observable<Draft?> = { (draft) -> Observable<Draft?> in
        return Observable<Draft?>.just(draft)
    }

    private func saveDraft(
            chatId: String?,
            messageId: String?,
            editMessageId: String?,
            threadId: String? = nil,
            scheduleInfo: RustPB.Basic_V1_Draft.ScheduleInfo? = nil,
            partialReplyInfo: PartialReplyInfo? = nil,
            type: Draft.TypeEnum,
            content: String) -> Observable<Draft> {
        let draft = createDraftModel(chatId: chatId,
                                     messageId: messageId,
                                     editMessageId: editMessageId,
                                     scheduleInfo: scheduleInfo,
                                     partialReplyInfo: partialReplyInfo,
                                     threadId: threadId,
                                     type: type,
                                     content: content)
        DraftCacheImpl.logger.info("DraftCacheImpl saveDraft", additionalData: ["chatId": draft.chatID,
                                                                                "messageId": draft.messageID,
                                                                                "editMessageId": draft.editMessageID,
                                                                                "threadId": draft.threadID,
                                                                                "partialReplyInfoPosition": "\(partialReplyInfo?.position.rawValue)",
                                                                                "draftLength": "\(draft.content.count)",
                                                                                "draftType": "\(draft.type)"])
        let draftAPI = self.draftAPI
        return self.notifiationDraftChange(draft: draft).flatMap { (draft) -> Observable<Draft> in
            return draftAPI.saveDraft(draft).do(onError: { (error) in
                DraftCacheImpl.logger.error("save draft failed", error: error)
            })
        }
    }

    private func createDraftModel(
        draftID: String? = nil,
        chatId: String? = nil,
        messageId: String? = nil,
        editMessageId: String? = nil,
        scheduleInfo: Basic_V1_Draft.ScheduleInfo? = nil,
        partialReplyInfo: PartialReplyInfo? = nil,
        threadId: String? = nil,
        type: Draft.TypeEnum,
        content: String = "") -> Draft {
            var draft = Draft()
            draft.type = type
            draft.content = content
            if let draftID = draftID {
                draft.id = draftID
            }
            if let chatId = chatId, !chatId.isEmpty {
                draft.chatID = chatId
            }
            if let info = scheduleInfo {
                draft.scheduleInfo = info
            }
            if let messageId = messageId, !messageId.isEmpty {
                draft.messageID = messageId
            }
            if let threadId = threadId, !threadId.isEmpty {
                draft.type = .msgThread
                draft.threadID = threadId
            }
            if let editMessageId = editMessageId, !editMessageId.isEmpty {
                draft.editMessageID = editMessageId
                //二次编辑草稿的type一律填.editMessage
                draft.type = .editMessage
            }
            if let partialReplyInfo = partialReplyInfo {
                draft.partialReplyInfo = partialReplyInfo
            }
            return draft
    }

    private func notifiationDraftChange(draft: Draft, isDelete: Bool = false) -> Observable<Draft> {
        return Observable<Draft>.create { [weak self] (observer) -> Disposable in
            if draft.hasEditMessageID {
                self?.cacheChangeSubject.onNext(
                    DraftCacheType.editMessage(draft.editMessageID, (messageId: nil, isDelete: isDelete, type: draft.type, content: draft.content, scheduleTime: nil))
                )
            } else if draft.type == .scheduleMessage {
                self?.cacheChangeSubject.onNext(
                    DraftCacheType.scheduleMessage(draft.chatID,
                                                   (messageId: draft.messageID, isDelete: isDelete, type: draft.type, content: draft.content, scheduleTime: draft.scheduleInfo.scheduleTime))
                )
            } else if draft.hasChatID {
                self?.cacheChangeSubject.onNext(
                    DraftCacheType.chat(draft.chatID, (messageId: nil, isDelete: isDelete, type: draft.type, content: draft.content, scheduleTime: nil))
                )
            } else if draft.hasMessageID {
                self?.cacheChangeSubject.onNext(
                    DraftCacheType.message(draft.messageID, (messageId: draft.messageID, isDelete: isDelete, type: draft.type, content: draft.content, scheduleTime: nil))
                )
            }
            observer.onNext(draft)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    private func getMessageInGlobalThread(_ messageID: String) -> Observable<Message> {
        let messageAPI = self.messageAPI
        return messageAPI.fetchLocalMessage(id: messageID).subscribeOn(self.scheduler)
    }
}

/// 下面代码是临时代码 Rust适配后之后会直接删除
extension DraftCacheImpl {

    func saveThreadTabDraft(content: String, callback: DraftCallback?) {
        let observable = self.saveDraft(chatId: nil, messageId: nil, editMessageId: nil, partialReplyInfo: nil, type: .individualTopic, content: content)
        serial(observable).subscribe(onNext: { (draft) in
            DraftCacheImpl.logger.info("DraftCacheImpl saveThreadTabDraft", additionalData: ["chatId": draft.chatID,
                                                                              "messageId": draft.messageID,
                                                                              "draftLength": "\(draft.content.count)",
                                                                              "draftType": "\(draft.type)"])

            callback?(draft, nil)
        }, onError: { (error) in
            callback?(nil, error)
        }).disposed(by: self.disposeBag)
    }

    func deleteThreadTabDraft() {
        let observable = draftAPI.fetchDefaultTopicGroupDraft().flatMap { [weak self] (draft) -> Observable<Void> in
            if let self = self {
                DraftCacheImpl.logger.info("DraftCacheImpl deleteThreadTabDraft", additionalData: ["chatId": draft.chatID,
                                                                                    "messageId": draft.messageID,
                                                                                    "draftLength": "\(draft.content.count)",
                                                                                    "draftType": "\(draft.type)"])
                return self.deleteDraft(draft: draft)
            } else {
                return Observable<Void>.just(())
            }
        }
        serial(observable).subscribe().disposed(by: self.disposeBag)
    }

    func fetchThreadTabDraft() -> Observable<String> {
        return draftAPI.fetchDefaultTopicGroupDraft().flatMap { (draft) -> Observable<String> in
            DraftCacheImpl.logger.info("DraftCacheImpl saveThreadTabDraft", additionalData: ["chatId": draft.chatID,
                                                                            "messageId": draft.messageID,
                                                                            "draftLength": "\(draft.content.count)",
                                                                            "draftType": "\(draft.type)"])
            return Observable<String>.just(draft.content)
        }
    }
}

typealias AsyncOperationBlock = (_ completionHandler: @escaping () -> Void) -> Void
final class AsyncBlockOperation: Operation {
    var asyncBlock: AsyncOperationBlock
    init(_ asyncBlock: @escaping AsyncOperationBlock) {
        self.asyncBlock = asyncBlock
        super.init()
    }
    override func start() {
        if !self.isCancelled {
            self.isExecuting = true
            self.isFinished = false
            self.asyncBlock { [weak self] in
                self?.isExecuting = false
                self?.isFinished = true
            }
        } else {
            self.isFinished = true
        }
    }

    fileprivate var _executing: Bool = false
    override var isExecuting: Bool {
        get { return _executing }
        set {
            if newValue != _executing {
                willChangeValue(forKey: "isExecuting")
                _executing = newValue
                didChangeValue(forKey: "isExecuting")
            }
        }
    }

    fileprivate var _finished: Bool = false
    override var isFinished: Bool {
        get { return _finished }
        set {
            if newValue != _finished {
                willChangeValue(forKey: "isFinished")
                _finished = newValue
                didChangeValue(forKey: "isFinished")
            }
        }
    }

    override var isAsynchronous: Bool {
        return true
    }

}

extension OperationQueue {
    @discardableResult
    func addAsyncBlock(_ asyncBlock: @escaping AsyncOperationBlock) -> AsyncBlockOperation {
        let asyncOperation = AsyncBlockOperation(asyncBlock)
        self.addOperation(asyncOperation)
        return asyncOperation
    }
}
