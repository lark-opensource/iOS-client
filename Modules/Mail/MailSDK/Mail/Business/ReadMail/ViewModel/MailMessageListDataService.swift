//
//  MailMessageListControllerDataSource.swift
//  MailSDK
//
//  Created by majx on 2020/3/18.
//

import Foundation
import RxSwift
import RxRelay
import RustPB

class MailMessageListDataService {

    var dataSource = ThreadSafeArray<MailMessageListPageViewModel>(array: [])

    private lazy var dataQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "mail.messagelist.dataservice"
        queue.maxConcurrentOperationCount = 2
        queue.qualityOfService = .utility
        return queue
    }()

    private lazy var dataScheduler: OperationQueueScheduler = {
        let scheduler = OperationQueueScheduler(operationQueue: dataQueue)
        return scheduler
    }()

    private lazy var observeScheduler: OperationQueueScheduler = {
        let q = OperationQueue()
        q.maxConcurrentOperationCount = 1
        q.qualityOfService = .userInitiated
        let scheduler = OperationQueueScheduler(operationQueue: q)
        return scheduler
    }()

    private func timeCost(_ start: CFTimeInterval) -> CFTimeInterval {
        return (CACurrentMediaTime() - start) * 1000
    }
    
    
  
        
    func loadMailItem(threadId: String,
                      labelId: String,
                      messageId: String?,
                      forwardInfo: DataServiceForwardInfo?) -> Observable<(MailItem, Bool)> {
        var newMessageIds: [String]?
        if let myMessageId = messageId, !myMessageId.isEmpty {
            newMessageIds = [myMessageId]
            MailLogger.info("message list loadMailItem threadId: \(threadId) with new message id: \(myMessageId) ")
        }
        MailLogger.info("message list local start loadMailItem threadId: \(threadId) labelId: \(labelId) ---->")
        var start = CACurrentMediaTime()
        return MailDataSource.shared.getMessageListFromLocal(threadId: threadId,
                                                             labelId: labelId,
                                                             newMessageIds: newMessageIds,
                                                             forwardInfo: forwardInfo)
        .subscribeOn(dataScheduler)
        .observeOn(observeScheduler)
        .do(onError: { (error) in
            MailLogger.info("message list local loadMailItem threadId: \(threadId) labelId: \(labelId) error \(error)")
        }).flatMap { [weak self] response -> Observable<(MailItem, Bool)> in
            guard let `self` = self else { return Observable.just((response.mailItem, false)) }
            MailLogger.info("message list local loadMailItem threadId: \(threadId), labelId: \(labelId) notInDB \(response.notInDB) cost \(self.timeCost(start))---->")
            if response.notInDB {
                return self.loadMailItemFromNet(threadId: threadId,
                                                labelId: labelId,
                                                newMessageIds: newMessageIds,
                                                forwardInfo: forwardInfo).map { ($0, true) }
            } else {
                return Observable.just((response.mailItem, false))
            }
        }
    }
        
    private func loadMailItemFromNet(threadId: String,
                                     labelId: String,
                                     newMessageIds: [String]?,
                                     forwardInfo: DataServiceForwardInfo?) -> Observable<MailItem> {
        MailLogger.info("message list remote loadMailItem threadId: \(threadId) labelId: \(labelId)")
        return MailDataSource.shared.getMessageListFromRemote(threadId: threadId, labelId: labelId, forwardInfo: forwardInfo, newMessageIds: newMessageIds)
            .subscribeOn(dataScheduler)
            .observeOn(observeScheduler)
            .do(onNext: {(mailItem) in
                MailLogger.info("message list remote loadMailItem threadId: \(threadId) labelId: \(labelId) success msg-count \(mailItem.messageItems.count)")
            }, onError: {(error) in
                MailLogger.info("message list remote loadMailItem threadId: \(threadId) labelId: \(labelId)  error \(error)")
            })
    }

    func loadMessageItem(threadId: String,
                         messageId: String,
                         isForward: Bool) -> Observable<MailMessageListPageViewModel?> {
        MailLogger.info("message item get messageId: \(messageId) threadId \(threadId)")
        return MailDataSource.shared.getMassageItem(messageId: messageId, isForward: isForward)
            .subscribeOn(dataScheduler)
            .observeOn(observeScheduler)
            .do(onError: {(error) in
                MailLogger.info("message item get messageId: \(messageId) threadId \(threadId) error")
            }).map {(messageItem) in
                MailLogger.info("message item get messageId: \(messageId) threadId \(threadId) success")
                if let viewModel = self.updateViewModel(threadId: threadId, messageItem: messageItem) {
                    return viewModel
                } else {
                    return nil
                }
            }
    }
    
    /// feed 场景
    func loadFeedMailItem(feedCardId: String,
                          timestampOperator: Bool,
                          timestamp: Int64,
                          forceGetFromNet: Bool,
                          isDraft: Bool) -> Observable<(MailItem, Bool)> {
        return MailDataSource.shared.getMessageListFromFeed(feedCardId: feedCardId,
                                                            timestampOperator: timestampOperator,
                                                            timestamp: timestamp,
                                                            forceGetFromNet: forceGetFromNet,
                                                            isDraft: isDraft)
        .subscribeOn(dataScheduler)
        .observeOn(observeScheduler)
        .do(onError: {(error) in
            MailLogger.info("message list loadFeedMailItem feedCardId: \(feedCardId) timestampOperator: \(timestampOperator) timestamp:\(timestamp) error: \(error)")
        }).map {(mailItem, hasMore) in
            MailLogger.info("message list loadFeedMailItem feedCardId: \(feedCardId) timestampOperator: \(timestampOperator) timestamp: \(timestamp)")
            return (mailItem, hasMore)
        }
    }
    
    func loadFeedDraft(feedCardId: String,
                       timestamp: Int64) -> Observable<(([MailFeedDraftItem], Bool))> {
        return MailDataSource.shared.getDraftFromFeed(feedCardId: feedCardId,
                                                      timestamp: timestamp)
        .subscribeOn(dataScheduler)
        .observeOn(observeScheduler)
        .do(onError: {(error) in
            MailLogger.info("[feed message list] loadFeedDraft feedCardId: \(feedCardId) timestamp:\(timestamp) error: \(error)")
        }).map {(draftItems, hasMore) in
            MailLogger.info("[feed message list] loadFeedDraft feedCardId: \(feedCardId) timestamp:\(timestamp)")
            return (draftItems, hasMore)
        }
    }

    func loadMessageItemWithNoMailItem(threadId: String,
                                       messageId: String) -> Observable<MailItem> {
        return MailDataSource.shared.getMessageOrDraft(messageId: messageId, ignoreConversationMode: true)
            .subscribeOn(dataScheduler)
            .observeOn(observeScheduler)
            .do(onError: { error in
                MailLogger.info("single message item get messageId: \(messageId) threadId \(threadId) error \(error)")
            }).map { (messageItem) in
                var mailItem = MailItem(threadId: threadId,
                                        messageItems: [messageItem],
                                        composeDrafts: [],
                                        labels: [],
                                        code: .owner,
                                        isExternal: false,
                                        isFlagged: false,
                                        isRead: false,
                                        isLastPage: false)
                mailItem.shouldHideContextMenu = true
                return mailItem
            }
    }

    private func updateViewModel(threadId: String, messageItem: MailMessageItem) -> MailMessageListPageViewModel? {
        let messageId = messageItem.message.id
        for (index, viewModel) in dataSource.all.enumerated()
        where viewModel.threadId == threadId {
            var mailItem = dataSource.all[index].mailItem
            mailItem?.messageItems = [messageItem]
            dataSource.all[index].mailItem = mailItem
            viewModel.mailItem = mailItem
            MailLogger.info("message item update message id: \(messageId)")
            return viewModel
        }
        return nil
    }

    private func indexOf(threadId: String) -> Int? {
        return dataSource.all.firstIndex(where: { $0.threadId == threadId })
    }

    func getViewModelAt(index: Int) -> MailMessageListPageViewModel? {
        if index >= 0 && index < dataSource.all.count {
            return dataSource.all[index]
        }
        return nil
    }

    func getViewModelOf(msgID: String) -> MailMessageListPageViewModel? {
        for (tIndex, threadItem) in dataSource.all.enumerated() {
            if let index = threadItem.mailItem?.messageItems.firstIndex(where: { $0.message.id == msgID }) {
                return dataSource.all[tIndex]
            }
        }
        return nil
    }

    func getViewModelOf(threadId: String) -> MailMessageListPageViewModel? {
        if let index = indexOf(threadId: threadId) {
            return dataSource.all[index]
        }
        return nil
    }
    
    func feedGetViewModelOf() -> MailMessageListPageViewModel? {
        return dataSource.all[0]
    }
}
