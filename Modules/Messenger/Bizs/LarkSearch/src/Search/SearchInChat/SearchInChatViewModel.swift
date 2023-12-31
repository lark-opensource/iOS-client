//
//  SearchInChatViewModel.swift
//  LarkSearch
//
//  Created by zc09v on 2018/8/17.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import LarkModel
import LarkSearchFilter
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface
import LKCommonsTracker
import Homeric
import LarkFeatureGating
import Reachability
import LarkSearchCore
import LKCommonsLogging
import RustPB
import ThreadSafeDataStructure
import LarkContainer
struct SearchInChatData {
    let searchParam: SearchParam
    let cellViewModels: [SearchInChatCellViewModel]
    let hasMore: Bool
}

// 数据刷新类型
enum SearchInChatState {
    case placeHolder
    case searching
    case result(SearchInChatData, String, IndexPath?, SearchInChatRequestInfo?)
    case noResult(String, SearchInChatRequestInfo?)
    case searchFail(String, Bool)
    case noResultForYear(String)
}

struct SearchInChatRequestInfo {
    let searchText: String
    let filters: [SearchFilter]
    let imprId: String
    let sessionID: String
    let isLoadMore: Bool
}

struct SearchParam: Equatable {
    let query: String
    let filters: [SearchFilter]

    init(query: String, filters: [SearchFilter] = []) {
        self.query = query
        self.filters = filters
    }

    static var empty: SearchParam {
        return SearchParam(query: "")
    }

    var isEmpty: Bool {
        return query.isEmpty && filters.allSatisfy { $0.isEmpty }
    }

    static func == (lhs: SearchParam, rhs: SearchParam) -> Bool {
        if lhs.query == rhs.query {
            let filterLEqualToR = lhs.filters.allSatisfy { (lhsFilter) -> Bool in
                if !lhsFilter.isEmpty {
                    return rhs.filters.contains(where: { $0 == lhsFilter })
                } else {
                    return true
                }
            }
            let filterREqualToL = rhs.filters.allSatisfy { (rhsFilter) -> Bool in
                if !rhsFilter.isEmpty {
                    return lhs.filters.first(where: { (lhsFilter) -> Bool in
                        lhsFilter == rhsFilter
                    }) != nil
                } else {
                    return true
                }
            }
            return filterLEqualToR && filterREqualToL
        }
        return false
    }
}

final class SearchInChatViewModel {
    static let logger = Logger.log(SearchInChatViewModel.self, category: "Search")
    private let chatId: String
    let config: SearchInChatVCConifg
    private let searchSession: SearchSession
    private let searchCache: SearchCache
    private let isMeetingChat: Bool
    private let searchAPI: SearchAPI
    private let chatAPI: ChatAPI
    private let router: SearchInChatRouter
    private let context: SearchInChatViewModelContext
    private var cacheKey: String {
        return "serchInChat_\(chatId)\(config.type.rawValue)"
    }
    private let stateSubject = BehaviorRelay<SearchInChatState>(value: .placeHolder)
    var stateObservable: Observable<SearchInChatState> {
        return stateSubject.asObservable().observeOn(MainScheduler.instance)
    }

    private let countPerRequest: Int32 = 15
    private(set) var currentSearchData: SearchInChatData?
    var lastSearchParam: SearchParam?
    private let threadMiniIconEnable: Bool
    private let enableDocCustomAvatar: Bool
    public var lastRequestInfo: SearchInChatRequestInfo?

    var requestOffset: Int32 = 0
    var seqID: SearchSession.Captured
    /// 是否使用Local数据源。Chat里的内容应该都是支持的
    private var useLocal = false
    // 记录当前页面是否从cache加载而来
    var whetherLoadFromCache = false

    /// 搜索冷热库之后需要展示的页面状态
    var responseTipType: HotAndColdTipType?
    private var currentRequestID: UInt16 = 0
    private var requestToken: Disposable? {
        didSet { oldValue?.dispose() }
    }

    private(set) var source: SearchSource? /// 为true时启用v2的API
    var moreToken: Any? /// 用于source加载更多用

    #if DEBUG || INHOUSE || ALPHA
    let debugDataManager: ASLContextIDProtocol
    #endif
    private let disposeBag: DisposeBag = DisposeBag()

    lazy var sourceMaker = SearchSourceMaker(searchSession: searchSession,
                                             sourceKey: nil,
                                             inChatID: chatId,
                                             resolver: self.userResolver)
    // 传递searchInChatViewController 的view页面宽度-iphone为屏幕宽度，ipad为search页面宽度
    var searchInChatWidthGetter: (() -> CGFloat)? {
        didSet {
            sourceMaker.searchViewWidthGetter = searchInChatWidthGetter
            self.source = sourceMaker.makeSearchSource(for: .rustScene(config.searchScene), userResolver: userResolver)
        }
    }
    let userResolver: UserResolver
    let searchTimeTrackManager = SearchTimeTrackManager()
    init(userResolver: UserResolver,
         chatId: String,
         config: SearchInChatVCConifg,
         searchSession: SearchSession,
         searchCache: SearchCache,
         isMeetingChat: Bool,
         searchAPI: SearchAPI,
         chatAPI: ChatAPI,
         router: SearchInChatRouter,
         context: SearchInChatViewModelContext) {
        self.userResolver = userResolver
        self.chatId = chatId
        self.config = config
        self.searchSession = searchSession
        self.seqID = searchSession.capture()
        self.searchCache = searchCache
        self.isMeetingChat = isMeetingChat
        self.searchAPI = searchAPI
        self.chatAPI = chatAPI
        self.router = router
        self.context = context
        self.threadMiniIconEnable = false
        self.enableDocCustomAvatar = SearchFeatureGatingKey.docIconCustom.isUserEnabled(userResolver: userResolver)
        #if DEBUG || INHOUSE || ALPHA
        self.debugDataManager = ASLDebugDataManager()
        #endif
        SearchRemoteSettings.shared.preload()

    }

    func loadSearchCache() {
        searchCache.getCacheData(key: cacheKey).observeOn(MainScheduler.instance)
            .map { [weak self] (cacheData) -> (SearchInChatData?, IndexPath?) in
                guard let self = self, let cacheData = cacheData, !cacheData.results.isEmpty else {
                    return (nil, nil)
                }
                var cellVMs = cacheData.results.compactMap { (data: SearchResultType) -> SearchInChatCellViewModel? in
                    return SearchInChatCellViewModel(
                        userResolver: self.userResolver,
                        chatId: self.chatId,
                        chatAPI: self.chatAPI,
                        data: data,
                        router: self.router,
                        isSearchingResult: true,
                        enableThreadMiniIcon: self.threadMiniIconEnable,
                        enableDocCustomAvatar: self.enableDocCustomAvatar,
                        context: self.context
                    )
                }
                if let showRequestColdTip = cacheData.showRequestColdTip {
                    let tipVM = SearchInChatCellViewModel(userResolver: self.userResolver,
                                                          chatId: self.chatId,
                                                          chatAPI: self.chatAPI,
                                                          data: nil,
                                                          router: self.router,
                                                          isSearchingResult: true,
                                                          enableThreadMiniIcon: self.threadMiniIconEnable,
                                                          enableDocCustomAvatar: self.enableDocCustomAvatar,
                                                          context: self.context,
                                                          useHotData: showRequestColdTip
                         )
                    cellVMs.append(tipVM)
                }

                let searchData = SearchInChatData(searchParam: SearchParam(query: cacheData.quary, filters: cacheData.filters),
                                                  cellViewModels: cellVMs,
                                                  hasMore: false)
                let lastVisitIndex = cacheData.lastVisitIndex
                self.currentSearchData = searchData
                return (searchData, lastVisitIndex)
            }
            .subscribe(onNext: { (searchData, index) in
                if let searchData = searchData {
                    self.whetherLoadFromCache = true
                    // 这个缓存目前看代码，仅用于显示默认页，且也不支持加载更多，需要重新输入进行搜索
                    self.stateSubject.accept(.result(searchData, "", index, nil))
                }
            })
            .disposed(by: disposeBag)
    }

    func saveSearchCache(visitedIndex: IndexPath) {
        guard let searchData = self.currentSearchData else { return }
        var results: [SearchResultType] = []
        var showRequestColdDataTip: Bool?
        for cellVM in searchData.cellViewModels {
            if let data = cellVM.data {
                results.append(data)
            } else {
                /// 有空数据，表示需要展示tip
                if case .oneYearHasNoMore = responseTipType {
                    showRequestColdDataTip = false
                } else if case .overYearHasNoMore = responseTipType {
                    showRequestColdDataTip = true
                }
            }
        }
        searchCache.set(key: cacheKey,
                        quary: searchData.searchParam.query,
                        filers: searchData.searchParam.filters,
                        results: results,
                        visitIndex: visitedIndex,
                        showRequestColdTip: showRequestColdDataTip)
    }

    func search(param: SearchParam) {
        lastSearchParam = param
        currentSearchData = SearchInChatData(searchParam: param,
                         cellViewModels: [],
                         hasMore: false)
        useLocal = false  // 重新搜索时尝试网络搜索
        if param.isEmpty, !config.searchWhenEmpty {
            currentRequestID &+= 1
            stateSubject.accept(.placeHolder)
            return
        }
        stateSubject.accept(.searching)
        requestOffset = 0
        seqID = searchSession.nextSeq()
        request(param: param,
                begin: requestOffset,
                end: requestOffset + countPerRequest,
                isExpand: param.query.count >= (lastSearchParam?.query.count ?? 0))
    }

    private func isSupportedColdData(type: SearchInChatType) -> Bool {
        guard SearchFeatureGatingKey.searchOneYearData.isEnabled else {
            return false
        }
        switch type {
        case .message, .file, .url, .image, .video:
            return true
        case .wiki, .doc, .docWiki:
            return false
        }
    }
    func loadMore(param: SearchParam) {
        /// 是否是可以支持的tab

        if isSupportedColdData(type: config.type) {
            request(param: param,
                    begin: requestOffset,
                    end: requestOffset + countPerRequest,
                    isExpand: true)
        } else {
            request(param: param,
                    begin: requestOffset,
                    end: requestOffset + countPerRequest,
                    isExpand: true)
        }
    }

    private func request(param: SearchParam,
                         begin: Int32,
                         end: Int32,
                         isExpand: Bool,
                         whetherSearchColdData: Bool? = nil) {
        assert(Thread.isMainThread, "should occur on main thread!")
        if SearchTrackUtil.enablePostTrack() {
            self.searchTimeTrackManager.startTime = Date().timeIntervalSince1970
            var categoryParams: [String: Any] = [
                "tab_name": self.config.type.trackRepresentation,
                "is_spotlight": false
            ]
            if let currentSearchData = self.currentSearchData {
                categoryParams["is_load_more"] = !currentSearchData.cellViewModels.isEmpty
            }
            SearchTrackUtil.trackForStableWatcher(domain: "asl_chat_search",
                                                  message: "asl_start_search",
                                                  metricParams: [:],
                                                  categoryParams: categoryParams)
        }
        let seqID = self.seqID
        let imprID = seqID.imprID

        let searchScene: SearchScene
        if param.isEmpty, let defaultSearchScene = config.defaultDataSearchScene {
            searchScene = defaultSearchScene
        } else {
            searchScene = config.searchScene
        }
        var isLocal = false

        enum ResponseType {
            case callback(SearchCallBack), response(SearchResponse)
        }
        let ob: Observable<ResponseType>?
        var request = BaseSearchRequest(
            query: param.query, filters: param.filters,
            count: Int(end - begin), moreToken: begin == 0 ? nil : moreToken)
        // 本地搜索暂时不支持本地filter
        if param.filters.contains(where: { !$0.isEmpty }) {
            request.context[SearchRequestExcludeTypes.local] = true
        }
        ob = source?.search(request: request).map { .response($0) }

        currentRequestID &+= 1
        let requestInfo = SearchInChatRequestInfo(searchText: param.query,
                                          filters: param.filters,
                                          imprId: imprID,
                                          sessionID: seqID.session,
                                          isLoadMore: !(self.currentSearchData?.cellViewModels.isEmpty ?? true))
        self.lastRequestInfo = requestInfo
        func trackForDuration() {
            guard SearchTrackUtil.enablePostTrack() != false else { return }
            self.searchTimeTrackManager.trackForDuration(domain: "asl_chat_search",
                                                         endTime: Date().timeIntervalSince1970,
                                                         isSpotlight: false,
                                                         isLoadMore: requestInfo.isLoadMore,
                                                         errorCode: nil,
                                                         tabType: self.config.type,
                                                         isInChat: true)
        }
        requestToken = ob?.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self, currentRequestID] (response) in
                guard let self = self, self.currentRequestID == currentRequestID else { return }

                let callBack: SearchCallBack
                switch response {
                case .callback(let v): callBack = v
                case .response(let response):
                    #if DEBUG || INHOUSE || ALPHA
                    if let aslContextID = response.context[SearchResponseContextID.self] {
                        self.debugDataManager.contextIDOnNext(contextID: aslContextID)
                    }
                    #endif
                    let hasMore = response.hasMore
                    let isLoadMore = !(self.currentSearchData?.cellViewModels.isEmpty ?? true)
                    if SearchFeatureGatingKey.searchOneYearData.isUserEnabled(userResolver: self.userResolver),
                       let secondStageSearchEnable = response.secondaryStageSearchable {
                        if !isLoadMore && response.results.isEmpty {
                            /// 无结果页面
                            if secondStageSearchEnable {
                                self.responseTipType = .noResultForYear
                            } else {
                                self.responseTipType = .noResultForAll
                            }
                        } else if hasMore == false {
                            /// 展示底部的提示
                            if secondStageSearchEnable {
                                self.responseTipType = .oneYearHasNoMore
                            } else {
                                self.responseTipType = .overYearHasNoMore
                            }
                        } else {
                            /// 正常的请求上拉加载更多
                            if secondStageSearchEnable {
                                self.responseTipType = .loadMoreHot
                            } else {
                                self.responseTipType = .loadMoreCold
                            }
                        }
                    }
                    Self.logger.info("""
                        HotAndColdTip for searchInChat:
                        search tip Type: \(self.responseTipType),
                        returned \(response.results.count) pieces of data,
                        hasMore = \(response.hasMore),
                        moreToken.notNull = \(response.moreToken != nil),
                        secondary_stage_searchable = \(response.secondaryStageSearchable),
                        contextID: \(response.context[SearchResponseContextID.self])
                    """)
                    // responseStatus
                    callBack = CommonSearchCallBack(
                        searchScene: .rustScene(searchScene),
                        hasMore: response.hasMore,
                        results: response.results as! [SearchResultType], // swiftlint:disable:this all
                        isRemote: true,
                        imprID: response.context[SearchResponseImprID.self],
                        contextID: response.context[SearchResponseContextID.self],
                        moreToken: response.moreToken
                    )
                    self.moreToken = response.moreToken
                    if SearchTrackUtil.enablePostTrack() {
                        SearchTrackUtil.trackForStableWatcher(domain: "asl_chat_search",
                                                              message: "asl_search_success",
                                                              metricParams: [:],
                                                              categoryParams: [
                                                                "tab_name": self.config.type.trackRepresentation,
                                                                "is_spotlight": false,
                                                                "is_load_more": requestInfo.isLoadMore,
                                                                "count": response.results.count
                                                            ])
                    }
                }
                if begin == 0 { self.useLocal = !callBack.isRemote } // 加载更多使用和首次加载相同数据源
                let cellViewModels = callBack.results.map { (searchResult) -> SearchInChatCellViewModel in
                    return SearchInChatCellViewModel(userResolver: self.userResolver,
                                                     chatId: self.chatId,
                                                     chatAPI: self.chatAPI,
                                                     data: searchResult,
                                                     router: self.router,
                                                     isSearchingResult: !param.isEmpty,
                                                     enableThreadMiniIcon: self.enableDocCustomAvatar,
                                                     enableDocCustomAvatar: self.enableDocCustomAvatar,
                                                     context: self.context
                    )
                }
                let preVMs = self.currentSearchData?.cellViewModels ?? []
                var newVMs = preVMs + cellViewModels
                if newVMs.isEmpty {
                    if let defaultSearchScene = self.config.defaultDataSearchScene, searchScene == defaultSearchScene, param.isEmpty {

                        if case .noResultForYear = self.responseTipType,
                           self.isSupportedColdData(type: self.config.type),
                           self.config.type != .message {
                            // 会话内搜索的无query页面也支持改造
                            self.stateSubject.accept(.noResultForYear(param.query))
                        } else {
                            /// 如果没有发起请求，展示默认态
                            self.stateSubject.accept(.placeHolder)
                        }

                    } else {
                        /// 无结果页面
                        if case .noResultForYear = self.responseTipType,
                           self.isSupportedColdData(type: self.config.type) {
                            self.stateSubject.accept(.noResultForYear(param.query))
                        } else {
                            self.stateSubject.accept(.noResult(param.query, requestInfo))
                        }

                    }
                } else {

                    /// tablereload不需要再次添加提示cell
                    var filterTipVM = newVMs
                    /// 结果页面
                    if !callBack.hasMore && self.isSupportedColdData(type: self.config.type) {
                        if case .overYearHasNoMore = self.responseTipType {
                            /// 冷库数据已经全部展示， 提示 “已展示全部结果“
                            let tipVM = SearchInChatCellViewModel(userResolver: self.userResolver,
                                                                  chatId: self.chatId,
                                                                  chatAPI: self.chatAPI,
                                                                  data: nil,
                                                                  router: self.router,
                                                                  isSearchingResult: !param.isEmpty,
                                                                  enableThreadMiniIcon: self.enableDocCustomAvatar,
                                                                  enableDocCustomAvatar: self.enableDocCustomAvatar,
                                                                  context: self.context,
                                                                  useHotData: false
                                 )
                            newVMs.append(tipVM)
                        } else if case .oneYearHasNoMore = self.responseTipType {
                            /// 热库数据已经全部展示，提示 “已经展示一年内消息，点击查看更多”
                            let tipVM = SearchInChatCellViewModel(userResolver: self.userResolver,
                                                                  chatId: self.chatId,
                                                                  chatAPI: self.chatAPI,
                                                                  data: nil,
                                                                  router: self.router,
                                                                  isSearchingResult: !param.isEmpty,
                                                                  enableThreadMiniIcon: self.enableDocCustomAvatar,
                                                                  enableDocCustomAvatar: self.enableDocCustomAvatar,
                                                                  context: self.context,
                                                                  useHotData: true
                                 )
                            newVMs.append(tipVM)
                        }
                    }
                    let data = SearchInChatData(searchParam: param,
                                                cellViewModels: newVMs,
                                                hasMore: callBack.hasMore)
                    let cacheData = SearchInChatData(searchParam: param,
                                                     cellViewModels: filterTipVM,
                                                     hasMore: callBack.hasMore)
                    self.currentSearchData = cacheData

                    self.stateSubject.accept(.result(data, param.query, nil, requestInfo))
                }
                self.requestOffset += (end - begin)

                var param = ["page": self.config.type.rawValue]
                if self.config.type == .doc || self.config.type == .docWiki {
                    param = param.lf_update(["search_id": callBack.contextID ?? ""])
                }
                Tracker.post(TeaEvent(Homeric.SEARCH_CHAT_HISTORY, params: param))
                trackForDuration()
            }, onError: { [weak self, currentRequestID] (error) in
                guard let self = self, self.currentRequestID == currentRequestID else { return }
                if isLocal {
                    SearchMetrics.LocalBackup.localError(query: param.query, session: seqID, scene: searchScene, error: error)
                }
                let isLoadMore = !(self.currentSearchData?.cellViewModels.isEmpty ?? true)

                if case .oneYearHasNoMore = self.responseTipType,
                   self.isSupportedColdData(type: self.config.type) {
                    self.stateSubject.accept(.noResultForYear(param.query))
                } else {
                    self.stateSubject.accept(.searchFail(param.query, isLoadMore))
                }
                if SearchTrackUtil.enablePostTrack() {
                    trackForDuration()
                    var failReason: Any = error.localizedDescription
                    if let searchError = error as? Search_V2_SearchCommonResponseHeader.InvokeAbnormalNotice {
                        failReason = searchError.rawValue.description
                    }
                    SearchTrackUtil.trackForStableWatcher(domain: "asl_chat_search",
                                                          message: "asl_search_fail",
                                                          metricParams: [:],
                                                          categoryParams: [
                                                            "fail_reason": failReason,
                                                            "is_spotlight": false,
                                                            "is_load_more": requestInfo.isLoadMore,
                                                            "tab_name": self.config.type.trackRepresentation
                                                        ])
                }
            })
    }
}
