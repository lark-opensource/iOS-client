//
//  SearchInChatResourceRepo.swift
//  LarkSearch
//
//  Created by Patrick on 2022/1/6.
//

import Foundation
import RxSwift
import RxCocoa
import LarkSearchCore
import RustPB
import LarkSDKInterface
import LarkAccountInterface
import LarkUIKit
import LKCommonsLogging
import LarkContainer

final class SearchInChatResourceRepo: SearchInChatResourcePresntable {
    static let logger = Logger.log(SearchInChatResourceRepo.self, category: "Search.SearchResourceRepo")
    private let searchSession: SearchSession
    private let searchAPI: SearchAPI
    private let chatId: String
    let messageAPI: MessageAPI
    let chatAPI: ChatAPI

    let userResolver: UserResolver
    init(userResolver: UserResolver,
         chatId: String,
         searchSession: SearchSession,
         searchAPI: SearchAPI,
         chatAPI: ChatAPI,
         messageAPI: MessageAPI) {
        self.userResolver = userResolver
        self.chatId = chatId
        self.searchSession = searchSession
        self.searchAPI = searchAPI
        self.messageAPI = messageAPI
        self.chatAPI = chatAPI
        self.seqID = searchSession.capture()
    }

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

    private var countInitRequest: Int32 {
        if Display.phone { return  countPerRequest }
        return countPerRequest * 2
    }
    private let countPerRequest: Int32 = 15

    private var requestOffset: Int32 = 0

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

    private lazy var sourceMaker: SearchSourceMaker = {
        return SearchSourceMaker(searchSession: searchSession,
                                 sourceKey: nil,
                                 inChatID: chatId,
                                 resolver: self.userResolver)
    }()

    private lazy var source: SearchSource? = {
        return sourceMaker.makeSearchSource(for: .searchResourceInChat, userResolver: userResolver)
    }()

    private let disposeBag = DisposeBag()

    private var hasMore: Bool = false
    private var moreToken: Any? /// 用于source加载更多用
    private var loading: Bool = false
    private(set) var lastSearchParam: SearchParam?
    private var seqID: SearchSession.Captured

    func fetchInitData() {
        let searchParam = SearchParam(query: "")
        lastSearchParam = searchParam
        requestOffset = 0
        seqID = searchSession.nextSeq()
        self._status.accept(.initialLoading)
        request(param: searchParam,
                begin: 0,
                end: countInitRequest) { [weak self] success in
            guard let self = self else { return }
            guard success else {
                self._status.accept(.initialFailed)
                return
            }
            self._status.accept(.initialFinish(hasMore: self.hasMore))
        }
    }

    func loadMore() {
        guard !loading, let moreToken = moreToken, let lastSearchParam = lastSearchParam else { return }
        loading = true
        let startTime = CFAbsoluteTimeGetCurrent()
        request(param: lastSearchParam,
                begin: requestOffset,
                end: requestOffset + countPerRequest) { [weak self] success in
            guard let self = self else { return }
            defer {
                self.loading = false
            }
            guard success else {
                self._status.accept(.loadMoreFailed(hasMore: self.hasMore))
                return
            }
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            self._loadMoreDuration.onNext(duration)
            self._status.accept(.loadMoreFinished(hasMore: self.hasMore))
        }
    }

    func search(param: SearchParam) {
        lastSearchParam = param
        requestOffset = 0
        seqID = searchSession.nextSeq()
        request(param: param,
                begin: requestOffset,
                end: requestOffset + countPerRequest) { [weak self] success in
            guard let self = self else { return }
            defer {
                self.loading = false
            }
            guard success else {
                self._status.accept(.searchFailed(hasMore: self.hasMore))
                return
            }
            self._status.accept(.searchFinished(hasMore: self.hasMore))
        }
    }

    private func request(param: SearchParam,
                         begin: Int32,
                         end: Int32,
                         completion: ((Bool) -> Void)? = nil) {
        let request = BaseSearchRequest(
            query: param.query, filters: param.filters,
            count: Int(end - begin), moreToken: begin == 0 ? nil : moreToken)
        source?.search(request: request)
            .observeOn(dataScheduler)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                self.handle(response: response, searchParam: param)
                self.requestOffset += (end - begin)
                #if DEBUG || INHOUSE || ALPHA
                if let aslContextID = response.context[SearchResponseContextID.self] {
                    self._status.accept(.requestFinished(contextID: aslContextID))
                }
                #endif
                completion?(true)
            }, onError: { (_) in
                completion?(false)
            })
            .disposed(by: disposeBag)
    }

    private func handle(response: SearchResponse, searchParam: SearchParam) {
        hasMore = response.hasMore
        let results = response.results as! [SearchResultType] // swiftlint:disable:this all
        let metas = results.map { $0.meta }
        var metaResources: [SearchResource] = []
        for meta in metas {
            if case let .resource(resourceMeta) = meta {
                resourceMeta.resourceContent
                let metaCreateDate = Date(timeIntervalSince1970: TimeInterval(resourceMeta.messageRelatedInfo.createTime))
                let resource = SearchResource(messageId: resourceMeta.messageRelatedInfo.id,
                                              threadID: resourceMeta.messageRelatedInfo.threadID,
                                              messagePosition: resourceMeta.messageRelatedInfo.position,
                                              threadPosition: resourceMeta.messageRelatedInfo.threadPosition,
                                              data: SearchResource.Data(content: resourceMeta.resourceContent),
                                              createTime: metaCreateDate,
                                              hasPreviewPremission: resourceMeta.hasResourceAccessAuth_p)
                metaResources.append(resource)
            }
        }

        var responseTipType: HotAndColdTipType?
        if SearchFeatureGatingKey.searchOneYearData.isEnabled,
           let secondStageSearchEnable = response.secondaryStageSearchable {
            if requestOffset == 0 && response.results.isEmpty {
                /// 无结果页面
                if secondStageSearchEnable {
                    responseTipType = .noResultForYear
                } else {
                    responseTipType = .noResultForAll
                }
            } else if hasMore == false {
                /// 展示底部的提示
                if secondStageSearchEnable {
                    responseTipType = .oneYearHasNoMore
                } else {
                    responseTipType = .overYearHasNoMore
                }
            } else {
                /// 正常的请求上拉加载更多
                if secondStageSearchEnable {
                    responseTipType = .loadMoreHot
                } else {
                    responseTipType = .loadMoreCold
                }
            }
        }
        Self.logger.info("""
                         HotAndColdTip for searchResource:
                         search tip Type: \(responseTipType),
                         hasMore = \(response.hasMore),
                         returned \(response.results.count) pieces of data,
                         moreToken.notNull = \(response.moreToken != nil),
                         secondary_stage_searchable = \(response.secondaryStageSearchable),
                         contextID: \(response.context[SearchResponseContextID.self])
       """)
        _resoures.onNext((metaResources, searchParam.query, responseTipType))
        moreToken = response.moreToken
    }
}
