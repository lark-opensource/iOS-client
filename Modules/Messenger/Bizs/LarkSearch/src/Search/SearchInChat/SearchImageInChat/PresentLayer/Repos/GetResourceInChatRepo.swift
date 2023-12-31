//
//  GetResourceInChatRepo.swift
//  LarkSearch
//
//  Created by Patrick on 2022/1/6.
//

import Foundation
import RxSwift
import RxCocoa
import LarkSDKInterface
import LarkUIKit
import RustPB
import Homeric
import LKCommonsTracker

final class GetResourceInChatRepo: SearchInChatResourcePresntable {
    let messageAPI: MessageAPI
    let chatAPI: ChatAPI
    private let chatId: String

    init(chatId: String,
         chatAPI: ChatAPI,
         messageAPI: MessageAPI) {
        self.messageAPI = messageAPI
        self.chatAPI = chatAPI
        self.chatId = chatId
    }

    private var countInitRequest: Int32 {
        if Display.phone { return  countPerRequest }
        return countPerRequest * 2
    }
    private let countPerRequest: Int32 = 15

    private let requestResourceTypes: [RustPB.Media_V1_ChatResourceType] = [.image]

    private let disposeBag = DisposeBag()

    private var hasMore: Bool = false
    private var lastResourceMessageId: String?
    private var loadingMore: Bool = false

    var status: Observable<SearchImageInChatViewModel.Status> {
        return _status.asObservable()
    }
    private let _status = BehaviorRelay<SearchImageInChatViewModel.Status>(value: .initialLoading)

    var resoures: Observable<([SearchResource], String, HotAndColdTipType?)> {
        return _resoures.asObservable()
    }
    private let _resoures = PublishSubject<([SearchResource], String, HotAndColdTipType?)>()

    var loadMoreDuration: Observable<Double> {
        return _loadMoreDuration.asObservable()
    }
    private let _loadMoreDuration = PublishSubject<Double>()

    private lazy var dataQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "SearchImageInChatViewModelDataQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    private lazy var dataScheduler: OperationQueueScheduler = {
        let scheduler = OperationQueueScheduler(operationQueue: dataQueue)
        return scheduler
    }()

    func fetchInitData() {
        self.chatAPI
            .fetchChatResources(chatId: chatId, count: countInitRequest, resourceTypes: requestResourceTypes)
            .observeOn(dataScheduler)
            .subscribe(onNext: { [weak self] (result) in
                guard let `self` = self else { return }
                self.handle(result: result)
                self._status.accept(.initialFinish(hasMore: self.hasMore))
            }, onError: { [weak self] (_) in
                self?._status.accept(.initialFailed)
            }).disposed(by: self.disposeBag)
    }

    func loadMore() {
        guard !loadingMore, let lastResourceMessageId = lastResourceMessageId else {
            return
        }
        loadingMore = true
        let startTime = CFAbsoluteTimeGetCurrent()
        self.chatAPI
            .fetchChatResources(chatId: chatId,
                                fromMessageId: lastResourceMessageId,
                                count: countPerRequest,
                                direction: .before,
                                resourceTypes: requestResourceTypes)
            .observeOn(dataScheduler)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }
                self.handle(result: result)
                self._status.accept(.loadMoreFinished(hasMore: self.hasMore))
                self.loadingMore = false
                let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                self._loadMoreDuration.onNext(duration)
            }, onError: { [weak self] (_) in
                guard let self = self else { return }
                self._status.accept(.loadMoreFailed(hasMore: self.hasMore))
                self.loadingMore = false
            }).disposed(by: self.disposeBag)
    }

    private func handle(result: FetchChatResourcesResult) {
        self.hasMore = result.hasMoreBefore
        for meta in result.messageMetas {
            let metaCreateDate = Date(timeIntervalSince1970: TimeInterval(meta.createTime))
            let metaResources = meta.resources.map { (responseResource) -> SearchResource in
                var resource = SearchResource(messageId: meta.id,
                                              threadID: meta.threadID,
                                              messagePosition: meta.position,
                                              threadPosition: meta.threadPosition,
                                              data: SearchResource.Data(resource: responseResource),
                                              createTime: metaCreateDate,
                                              originSize: responseResource.originSize,
                                              isOriginSource: responseResource.isOriginSource)
                if let chat = chatAPI.getLocalChat(by: chatId) {
                    if chat.chatMode == .threadV2 {
                        resource = SearchResource(messageId: meta.id,
                                                  threadID: meta.threadID,
                                                  messagePosition: meta.position,
                                                  threadPosition: meta.threadPosition,
                                                  data: SearchResource.Data(resource: responseResource),
                                                  createTime: metaCreateDate,
                                                  originSize: responseResource.originSize,
                                                  isOriginSource: responseResource.isOriginSource)
                    }
                }
                return resource
            }
            _resoures.onNext((metaResources, "", nil))
        }
        self.lastResourceMessageId = result.messageMetas.last?.id
    }

}
