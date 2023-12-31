//
//  PreloadMailItemOperation.swift
//  MailSDK
//
//  Created by ByteDance on 2023/5/26.
//

import Foundation
import RxSwift

protocol PreloadMailItemDelegate: AnyObject {
    func operation(_ operation: PreloadMailItemOperation, result: Result<[MailClientDraftImage], Error>)
    func netStatusAvalibleToPreload() -> Bool
}

// 加载邮件内容
class PreloadMailItemOperation: Operation {
    let source: MailPreloadSource
    var preloadName: String {
        return source.preloadName
    }
    // 唯一标识一个Operation
    var key: String {
        if let info = forwardInfo {
            return threadID + labelID + info.cardId + info.ownerUserId
        } else {
            return threadID + labelID
        }
    }
    weak var delegate: PreloadMailItemDelegate?
    private let threadID: String
    private let labelID: String
    // 预加载邮件消息卡片需要使用
    private let forwardInfo: DataServiceForwardInfo?
    private let dataService = MailMessageListDataService()
    private let bag = DisposeBag()
    init(threadID: String,
         labelID: String,
         source: MailPreloadSource,
         forwardInfo: DataServiceForwardInfo? = nil) {
        self.threadID = threadID
        self.labelID = labelID
        self.forwardInfo = forwardInfo
        self.source = source
    }


    // MARK: - Async Operation Properties
    private var executingState = false
    private var finishedState = false
    override var isExecuting: Bool {
        return executingState
    }
    override var isFinished: Bool {
        return finishedState
    }
    override var isAsynchronous: Bool {
        return true
    }

    override func start() {
        if isCancelled {
            willChangeValue(for: \PreloadMailItemOperation.isFinished)
            finishedState = true
            didChangeValue(for: \PreloadMailItemOperation.isFinished)
            return
        }
        loadItem()
    }

    private func loadItem() {
        willChangeValue(for: \PreloadMailItemOperation.isExecuting)
        executingState = true
        didChangeValue(for: \PreloadMailItemOperation.isExecuting)
        guard delegate?.netStatusAvalibleToPreload() == true else {
            MailLogger.error("MailPreloadServices: LoadMailItem net work status not avalible to preload")
            let error = NSError(domain: "mail.preload.mailItem", code: -1) as Error
            finished()
            delegate?.operation(self, result: .failure(error))
            return
        }
        MailLogger.info("MailPreloadServices: LoadMailItem start load mailItem \(self.threadID), source: \(self.source)")
        self.dataService.loadMailItem(threadId: threadID, labelId: labelID, messageId: nil, forwardInfo: forwardInfo)
            .subscribe(onNext: { [weak self] mailItem, isFromNet in
                guard let self = self else { return }
                MailLogger.info("MailPreloadServices: LoadMailItem get mail item from net \(isFromNet)")
                let images = mailItem.messageItems.flatMap { item in
                    return item.message.images
                }
                self.finished()
                self.delegate?.operation(self, result: .success(images))
            }, onError: {[weak self] e in
                guard let self = self else { return }
                MailLogger.error("MailPreloadServices: LoadMailItem rustError t_id: \(self.threadID), source: \(self.source) \(e)")
                self.finished()
                self.delegate?.operation(self, result: .failure(e))
            }).disposed(by: self.bag)
    }

    private func finished() {
        willChangeValue(for: \PreloadMailItemOperation.isFinished)
        willChangeValue(for: \PreloadMailItemOperation.isExecuting)
        executingState = false
        finishedState = true
        didChangeValue(for: \PreloadMailItemOperation.isExecuting)
        didChangeValue(for: \PreloadMailItemOperation.isFinished)
    }
}
