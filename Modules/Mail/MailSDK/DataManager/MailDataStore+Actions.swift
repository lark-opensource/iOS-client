//
//  MailDataStore+actions.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/3/6.
//

import Foundation
import RxSwift
import RustPB

// MARK: 一些会有side effect的，放到这里面。
extension MailDataStore {
    func archive(threadID: String, fromLabelID: String) {
        EventBus.$threadListEvent.accept(.resetThreadsCache(labelId: Mail_LabelId_Archived)) // TODO: REFACTOR 不知道为什么需要

        fetcher?.archive(threadID: threadID, fromLabelID: fromLabelID).subscribe(onNext: { (_) in
            MailDataStore.logger.info("archive succ")
        }, onError: { (error) in
            MailDataStore.logger.error("archive failed", error: error)
        }).disposed(by: self.disposeBag)
    }

    func trash(threadID: String, fromLabelID: String) {
        EventBus.$threadListEvent.accept(.resetThreadsCache(labelId: Mail_LabelId_Trash)) // TODO: REFACTOR 不知道为什么需要

        fetcher?.trash(threadID: threadID, fromLabelID: fromLabelID).subscribe(onNext: { (_) in
            MailDataStore.logger.info("trash succ")
        }, onError: { (error) in
            MailDataStore.logger.error("trash failed", error: error)
        }).disposed(by: self.disposeBag)
    }

    func unread(threadID: String, unread: Bool, fromLabelID: String) {
        if unread {
            fetcher?.unread(threadID: threadID, fromLabelID: fromLabelID).subscribe(onNext: { (_) in
                MailDataStore.logger.info("unread succ")
            }, onError: { (error) in
                MailDataStore.logger.error("unread failed", error: error)
            }).disposed(by: self.disposeBag)
        } else {
            fetcher?.read(threadID: threadID, fromLabelID: fromLabelID).subscribe(onNext: { (_) in
                MailDataStore.logger.info("unread succ")
            }, onError: { (error) in
                MailDataStore.logger.error("unread failed", error: error)
            }).disposed(by: self.disposeBag)
        }
    }

    func moveToInbox(threadID: String, fromLabelID: String) {
        EventBus.$threadListEvent.accept(.resetThreadsCache(labelId: Mail_LabelId_Inbox))

        fetcher?.moveToInbox(threadID: threadID, fromLabelID: fromLabelID).subscribe(onNext: { (_) in
            MailDataStore.logger.info("move to inbox succ")
        }, onError: { (error) in
            MailDataStore.logger.error("move to inbox failed", error: error)
        }).disposed(by: self.disposeBag)
    }

    func trashMessage(messageIds: [String], threadID: String, fromLabelID: String, feedCardId: String? = nil, completion: @escaping () -> Void) {
        EventBus.$threadListEvent.accept(.resetThreadsCache(labelId: Mail_LabelId_Trash))

        fetcher?.trashMessage(messageIds: messageIds, threadID: threadID, fromLabelID: fromLabelID, feedCardId: feedCardId).subscribe(onNext: { (_) in
            MailDataStore.logger.info("deleteMessage succ")
            completion()
        }, onError: { (error) in
            MailDataStore.logger.error("deleteMessage failed", error: error)
            InteractiveErrorRecorder.recordError(event: .delete_message_error, errorMessage: "\(error)")
        }).disposed(by: self.disposeBag)
    }

    func updateOutboxMail(threadId: String?,
                          messageId: String?,
                          action: Email_Client_V1_MailUpdateOutboxActionRequest.OutboxAction) -> Observable<(threadId: String?, messageId: String?)> {
		guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.updateOutboxMail(threadId: threadId, messageId: messageId, action: action)
            .observeOn(MainScheduler.instance)
            .map { [weak self] (resp) -> (threadId: String?, messageId: String?) in
                if let self = self, let threadId = threadId {
                    EventBus.$threadListEvent.accept(.needUpdateThreadList(label: Mail_LabelId_Outbox, removeThreadId: threadId))
                    EventBus.$threadListEvent.accept(.needUpdateOutbox)
                }
                return (resp.threadId, resp.messageId)
            }
    }
}
