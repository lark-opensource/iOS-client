//
//  UniversalSearchService.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/15.
//

import UIKit
import Foundation
import LarkRustClient
import LarkSDKInterface
import LarkAccountInterface
import LarkSearchCore
import RustPB
import EEAtomic
import RxSwift
import RxCocoa
import LKCommonsLogging
import LKMetric
import Homeric
import LarkContainer
import LarkListItem

public enum HotAndColdTipType: String {
    /// 请求冷库的加载更多，无提示页面
    case loadMoreCold
    /// 请求热库的加载更多，无提示页面
    case loadMoreHot
    /// 一年内已经展示完，底部提示“查看更多”
    case oneYearHasNoMore
    /// 冷库无结果，底部提示 “已展示全部结果”
    case overYearHasNoMore
    /// 无结果页面，“一年内无结果，可点击查看更多”
    case noResultForYear
    /// 无结果页面，“没有查找到相关信息”
    case noResultForAll
    /// 无结果页面，搜索超过次数
    case noResultForQuotaExceed
    /// 加载更多，搜索超过次数页面，底部提示页面
    case loadMoreForQuotaExceed
}
final class UniversalSearchService: SearchRepo {
    static let logger = Logger.log(UniversalSearchService.self, category: "Search.SearchRepo")
    var sourceMaker: SearchSourceMaker {
        didSet {
            searchSource = sourceMaker.makeSearchSource(for: config.scene, userResolver: userResolver)
        }
    }

    var searchSource: SearchSource?

    var searchWidthGetter: (() -> CGFloat)? {
        didSet {
            sourceMaker.searchViewWidthGetter = searchWidthGetter
            searchSource = sourceMaker.makeSearchSource(for: config.scene, userResolver: userResolver)
        }
    }

    let config: SearchTabConfigurable
    let searchSession: SearchSession

    private var moreToken: Any? /// 用于source加载更多用
    private var errorInfo: Search_V2_SearchCommonResponseHeader.ErrorInfo?
    var lastInput: SearcherInput?
    private let disposeBag = DisposeBag()

    private var searchCallbacks: [SearchCallBack] = []
    private var spotlightResults: [[SearchResultType]] = [] //use for merge and deduplicate
    private var didUniversalFinishedBeforeSpotlight: Bool
    private var lastRequestIsSpotlight: Bool
    private var scene: SearchSceneSection?

    private(set) var currentCapturedSession: SearchSession.Captured?

    let userResolver: UserResolver
    init(userResolver: UserResolver,
         searchSession: SearchSession,
         config: SearchTabConfigurable) {
        self.userResolver = userResolver
        self.searchSession = searchSession
        self.config = config
        var openSearchInfo: SearchSourceMaker.OpenSearchInfo?
        if let openSearchConfig = config as? SearchOpenTabConfig {
            openSearchInfo = SearchSourceMaker.OpenSearchInfo(openSearchInfo: openSearchConfig.info)
        }
        let sourceMaker = SearchSourceMaker(searchSession: searchSession,
                                            sourceKey: config.sourceKey,
                                            shouldRequestBasedOnResult: config.shouldRequestBasedOnResult,
                                            recommendFilterTypes: config.recommendFilterTypes,
                                            openSearchInfo: openSearchInfo,
                                            resolver: userResolver)
        self.sourceMaker = sourceMaker
        searchSource = sourceMaker.makeSearchSource(for: config.scene, userResolver: userResolver)
        didUniversalFinishedBeforeSpotlight = false
        lastRequestIsSpotlight = false
    }

    private let stateSubject = PublishSubject<SearcherState>()
    var state: Observable<SearcherState> {
        return stateSubject.asObservable()
    }

    private let recommendedFilterInfosSubject = PublishSubject<[RecommendFilterInfo]>()
    var recommendedFilterInfos: Observable<[RecommendFilterInfo]> {
        return recommendedFilterInfosSubject.asObservable()
    }

    private let recommendedFilterResultsSubject = PublishSubject<[SearchResultType]>()
    var recommendedFilterResults: Observable<[SearchResultType]> {
        return recommendedFilterResultsSubject.asObservable()
    }

    func search(_ input: SearcherInput) {
        moreToken = nil
        errorInfo = nil
        searchCallbacks = []
        spotlightResults = []
        didUniversalFinishedBeforeSpotlight = false
        spotlightSearch(input)
        universalSearch(input)
    }

    // TODO(@lijinru)
    // spotlight 和 universal Search需要降低冗余，本类应当转化为纯粹的工具类，将状态转化和状态之间影响全部抛到调用方处理
    // nolint: long_function
    private func spotlightSearch(_ input: SearcherInput,
                         contextID: UInt = SearchSession.getRequestID) {
        lastRequestIsSpotlight = false
        guard SearchFeatureGatingKey.enableSupportSpotlight.isUserEnabled(userResolver: userResolver) else { return }
        guard searchCallbacks.isEmpty else { return }
        guard !didUniversalFinishedBeforeSpotlight else { return }
        guard !input.filters.contains(where: { filter in
            !filter.isEmpty
        }) else { return }

        let scene: SearchSceneSection
        switch config.scene.remoteRustScene {
        case .smartSearch:
            scene = .spotlight
        case .searchChatters:
            scene = .spotlightChatter
        case .searchChatsInAdvanceScene:
            scene = .spotlightChat
        case .searchOpenAppScene:
            guard SearchFeatureGatingKey.enableSpotlightNativeApp.isUserEnabled(userResolver: userResolver) else { return }
            scene = .spotlightApp
        @unknown default:
            return
        }

        guard let spotlightSearchSource = sourceMaker.makeSearchSource(for: scene, userResolver: userResolver) else { return }

        let captured = searchSession.nextSeq()
        currentCapturedSession = captured

        let requestStartTime = Date()
        var pageInfos: [SearchRequestPageInfo] = []
        if SearchFeatureGatingKey.jumpTabMoreOpenSearch.isUserEnabled(userResolver: userResolver), config.shouldShowJumpMore {
            pageInfos = [SearchRequestPageInfo(clusteringType: .sectionItems, pageSize: 15)]
        }
        let request = BaseSearchRequest(query: input.query,
                                        filters: input.filters,
                                        count: config.requestPageSize,
                                        moreToken: moreToken,
                                        pageInfos: pageInfos)
        if SearchTrackUtil.enablePostTrack() {
            var categoryParams: [String: Any] = [
                "tab_name": self.config.tab.trackRepresentation,
                "is_spotlight": true,
                "is_load_more": false
             ]
            if case.open(let info) = self.config.tab {
                categoryParams["search_app_id"] = info.id
            }
            SearchTrackUtil.trackForStableWatcher(domain: "asl_general_search",
                                                  message: "asl_start_search",
                                                  metricParams: [:],
                                                  categoryParams: categoryParams)
        }
        spotlightSearchSource.search(request: request)
            .subscribe(onNext: { [weak self] (response) in
                //spotlight属于本地搜索,上报offline错误属于正常,需要业务方自行规避
                //spotlight的isRemote默认为true,否则会出现弱网断网相关UI
                guard let `self` = self, input.isCompleteSame(with: self.lastInput, userResolver: self.userResolver) else { return }
                guard let responseResults = response.results as? [SearchResultType] else { return }
                guard !self.didUniversalFinishedBeforeSpotlight else { return }

                //错误拦截
                if let searchError = response.searchError, searchError != .offline {
                    let requestInfo = SearcherState.RequestInfo(input: input,
                                                                isLoadMore: false,
                                                                capturedSession: captured,
                                                                requestTimeInterval: Date().timeIntervalSince(requestStartTime),
                                                                scene: self.config.scene,
                                                                contextID: response.context[SearchResponseContextID.self],
                                                                requestID: contextID,
                                                                searchError: nil,
                                                                spotlightStatus: .spotlightResultEmpty)

                    self.searchCallbacks = [SearchCallBack]()
                    self.stateSubject.onNext(.result(callbacks: self.searchCallbacks, requestInfo: requestInfo, responseTipType: nil))
                    Self.logger.info("Spotlight Search rust error \(response.searchError)")
                    return
                }

                var callbacks = [SearchCallBack]()
                if responseResults.isEmpty {
                    Self.logger.info("Spotlight Search responseResults is empty")
                } else {
                    //hasMore默认是true，后续由universalSearch纠正
                    if case .topResults = self.config.tabType {
                        for result in responseResults {
                            if case .section(let meta) = result.meta, !meta.results.isEmpty {
                                let metaResults = meta.results
                                for var res in metaResults {
                                    res.isSpotlight = true
                                }
                                let sectionCallback = SectionSearchCallBack(
                                    searchScene: self.config.scene,
                                    hasMore: true,
                                    results: metaResults,
                                    isRemote: true,
                                    headerInfo: meta.headerInfo,
                                    footerInfo: meta.footerInfo,
                                    imprID: response.context[SearchResponseImprID.self],
                                    contextID: response.context[SearchResponseContextID.self],
                                    extra: meta.extras,
                                    isSpotlight: true
                                )
                                callbacks.append(sectionCallback)
                                self.spotlightResults.append(meta.results)
                            }
                        }
                    } else if self.config.tabType == .subResults(.chatterResults) || self.config.tabType == .subResults(.chatResults)
                                || (self.config.tabType == .subResults(.appResults) && SearchFeatureGatingKey.enableSpotlightNativeApp.isUserEnabled(userResolver: self.userResolver)) {
                        // remote 判断 数据是否来自服务端，虽然spotlight不是来自服务端，但是有较多断网/弱网状态展示依赖这个
                        for var res in responseResults {
                            res.isSpotlight = true
                        }
                        callbacks.append(CommonSearchCallBack(
                            searchScene: self.config.scene,
                            hasMore: true,
                            results: responseResults,
                            isRemote: true,
                            imprID: response.context[SearchResponseImprID.self],
                            contextID: response.context[SearchResponseContextID.self],
                            moreToken: response.moreToken,
                            isSpotlight: true
                        ))
                        self.spotlightResults.append(responseResults)
                    }
                }

                if callbacks.isEmpty {
                    Self.logger.info("Spotlight Search responseResults.callbacks is empty")
                }

                self.lastRequestIsSpotlight = true

                let requestInfo = SearcherState.RequestInfo(input: input,
                                                            isLoadMore: false,
                                                            capturedSession: captured,
                                                            requestTimeInterval: Date().timeIntervalSince(requestStartTime),
                                                            scene: self.config.scene,
                                                            contextID: response.context[SearchResponseContextID.self],
                                                            requestID: contextID,
                                                            searchError: nil,
                                                            spotlightStatus: callbacks.isEmpty ? .spotlightResultEmpty : .spotlightResult)

                self.searchCallbacks = callbacks
                self.stateSubject.onNext(.result(callbacks: self.searchCallbacks, requestInfo: requestInfo, responseTipType: nil))
            }, onError: { [weak self] (error) in
                guard let self = self, input.isCompleteSame(with: self.lastInput, userResolver: self.userResolver) else { return }
                guard !self.didUniversalFinishedBeforeSpotlight else { return }
                self.searchCallbacks = [SearchCallBack]()
                let requestInfo = SearcherState.RequestInfo(input: input,
                                                            isLoadMore: false,
                                                            capturedSession: captured,
                                                            requestTimeInterval: Date().timeIntervalSince(requestStartTime),
                                                            scene: self.config.scene,
                                                            contextID: nil,
                                                            requestID: contextID,
                                                            searchError: nil,
                                                            spotlightStatus: .spotlightResultEmpty)
                self.stateSubject.onNext(.result(callbacks: self.searchCallbacks, requestInfo: requestInfo, responseTipType: nil))
                Self.logger.info("Spotlight Search rust error \(error)")
            })
            .disposed(by: disposeBag)
    }
    // enable-lint: long_function

    func loadMore() {
        let input = lastInput ?? SearcherInput(query: "")
        universalSearch(input)
    }

    // nolint: long_function
    private func universalSearch(_ input: SearcherInput,
                                 contextID: UInt = SearchSession.getRequestID) {
        let captured = searchSession.nextSeq()
        currentCapturedSession = captured

        let requestStartTime = Date()
        var pageInfos: [SearchRequestPageInfo] = []
        if SearchFeatureGatingKey.jumpTabMoreOpenSearch.isUserEnabled(userResolver: userResolver), config.shouldShowJumpMore {
            pageInfos = [SearchRequestPageInfo(clusteringType: .sectionItems, pageSize: 15)]
        }
        var isQueryTemplate: Bool = false
        let calendarMigration: Bool = SearchFeatureGatingKey.searchCalendarMigration.isUserEnabled(userResolver: userResolver)
        let emailMigration: Bool = SearchFeatureGatingKey.searchEmailMigration.isUserEnabled(userResolver: userResolver)
        if calendarMigration, (config.tab == .main || config.tab.isOpenSearchCalendar) {
            isQueryTemplate = true
        } else if emailMigration, (config.tab == .main || config.tab.isOpenSearchEmail) {
            isQueryTemplate = true
        }
        var request = BaseSearchRequest(query: input.query,
                                        filters: input.filters,
                                        count: config.requestPageSize,
                                        moreToken: moreToken,
                                        pageInfos: pageInfos,
                                        isQueryTemplate: isQueryTemplate)
        /// 支持场景：综搜和云文档Tab下
        if self.config.tabType == .topResults || self.config.tabType == .subResults(.docResults) {
            request.context[SearchRequestEnableShortcut.self] = SearchFeatureGatingKey.searchShortcut.isUserEnabled(userResolver: userResolver)
        }

        if let errorInfo = self.errorInfo, let op = errorInfo.ops.first, case .ignoreQuotaSearch = op.opType {
            request.context[SearchRequestOpAfterError.self] = op
        }

        if SearchTrackUtil.enablePostTrack() {
            var categoryParams: [String: Any] = [
                "tab_name": self.config.tab.trackRepresentation,
                "is_spotlight": false,
                "is_load_more": !self.searchCallbacks.isEmpty
            ]
            if case.open(let info) = self.config.tab {
                categoryParams["search_app_id"] = info.id
            }
            SearchTrackUtil.trackForStableWatcher(domain: "asl_general_search",
                                                  message: "asl_start_search",
                                                  metricParams: [:],
                                                  categoryParams: categoryParams)
        }
        func trackForRequestError(failReason: Any, isSpotlight: Bool, isLoadMore: Bool) {
            guard SearchTrackUtil.enablePostTrack() else { return }
            var categoryParams: [String: Any] = [
                "fail_reason": failReason,
                "is_spotlight": isSpotlight,
                "is_load_more": isLoadMore,
                "tab_name": self.config.tab.trackRepresentation
                ]
            if case.open(let info) = self.config.tab {
                categoryParams["search_app_id"] = info.id
            }
            SearchTrackUtil.trackForStableWatcher(domain: "asl_general_search",
                                                    message: "asl_search_fail",
                                                    metricParams: [:],
                                                    categoryParams: categoryParams)
        }
        searchSource?.search(request: request)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self, input.isCompleteSame(with: self.lastInput, userResolver: self.userResolver) else {
                    if let `self` = self, !input.isCompleteSame(with: self.lastInput, userResolver: self.userResolver) {
                        trackForRequestError(failReason: "during input search", isSpotlight: false, isLoadMore: !self.searchCallbacks.isEmpty)
                    }
                    return
                }
                guard let responseResults = response.results as? [SearchResultType] else {
                    trackForRequestError(failReason: "response result is not searchResultType", isSpotlight: false, isLoadMore: !self.searchCallbacks.isEmpty)
                    return
                }
                Self.logger.info("Universal Search rust error \(response.searchError)")
                self.didUniversalFinishedBeforeSpotlight = true
                if SearchFeatureGatingKey.enableSupportSpotlight.isUserEnabled(userResolver: self.userResolver)
                    && response.searchError != nil
                    && !self.spotlightResults.isEmpty
                    && self.config.tabType == .topResults {
                    let requestTimeInterval = Date().timeIntervalSince(requestStartTime)
                    let requestInfo = SearcherState.RequestInfo(input: input,
                                                                isLoadMore: true,
                                                                capturedSession: captured,
                                                                requestTimeInterval: requestTimeInterval,
                                                                scene: self.config.scene,
                                                                contextID: response.context[SearchResponseContextID.self],
                                                                requestID: contextID,
                                                                searchError: response.searchError,
                                                                spotlightStatus: SearcherState.SpotlightResultStatus.spotlightUniversalNetSearchError)
                    self.stateSubject.onNext(.result(callbacks: self.searchCallbacks, requestInfo: requestInfo, responseTipType: nil))
                    return
                }
                let isLoadMore = !self.searchCallbacks.isEmpty
                let lastRequestIsSpotlight = self.lastRequestIsSpotlight
                self.lastRequestIsSpotlight = false
                if case .topResults = self.config.tabType {
                    var localResults: [SearchResultType] = []
                    // 是否展示 section 化的数据（暂时只有综合搜索）
                    for result in responseResults {
                        switch result.meta {
                        case .section(let meta):
                            if self.spotlightDeduplicateWith(results: meta.results, isSectionType: true) != nil {
                                var sectionCallback = SectionSearchCallBack(
                                    searchScene: self.config.scene,
                                    hasMore: response.hasMore,
                                    results: meta.results,
                                    isRemote: true,
                                    headerInfo: meta.headerInfo,
                                    footerInfo: meta.footerInfo,
                                    imprID: response.context[SearchResponseImprID.self],
                                    contextID: response.context[SearchResponseContextID.self],
                                    extra: meta.extras
                                )
                                self.searchCallbacks.append(sectionCallback)
                            }
                        case .qaCard:
                            self.searchCallbacks.append(CommonSearchCallBack(
                                searchScene: .searchServiceCard,
                                hasMore: response.hasMore,
                                results: [result],
                                isRemote: true,
                                imprID: response.context[SearchResponseImprID.self],
                                contextID: response.context[SearchResponseContextID.self],
                                moreToken: nil
                            ))
                        case .customization(let meta):
                            let scene: SearchSceneSection
                            switch meta.cardType {
                            case .block:
                                scene = .searchBlock
                            @unknown default:
                                scene = .searchServiceCard
                            }
                            self.searchCallbacks.append(CommonSearchCallBack(
                                searchScene: scene,
                                hasMore: response.hasMore,
                                results: [result],
                                isRemote: true,
                                imprID: response.context[SearchResponseImprID.self],
                                contextID: response.context[SearchResponseContextID.self],
                                moreToken: nil
                            ))
                        // 在收到非 section 化的时候把结果封装成 section
                        default:
                            localResults.append(result)
                        }
                    }
                    if !localResults.isEmpty {
                        let isRemote = SearchFeatureGatingKey.errorTips.isUserEnabled(userResolver: self.userResolver) ? false : true
                        self.searchCallbacks.append(CommonSearchCallBack(
                            searchScene: self.config.scene,
                            hasMore: response.hasMore,
                            results: localResults,
                            isRemote: isRemote,
                            imprID: response.context[SearchResponseImprID.self],
                            contextID: response.context[SearchResponseContextID.self],
                            moreToken: nil
                        ))
                    }
                } else {
                    // 非 section 化的数据
                    let isRemote = SearchFeatureGatingKey.errorTips.isUserEnabled(userResolver: self.userResolver) ? response.searchError == nil : true
                    if self.searchCallbacks.isEmpty {
                        if let results = self.spotlightDeduplicateWith(results: responseResults, isSectionType: false) {
                            var searchCallBack = CommonSearchCallBack(
                                searchScene: self.config.scene,
                                hasMore: response.hasMore,
                                results: results,
                                isRemote: isRemote,
                                imprID: response.context[SearchResponseImprID.self],
                                contextID: response.context[SearchResponseContextID.self],
                                moreToken: response.moreToken
                            )
                            if let errorInfo = response.errorInfo {
                                searchCallBack.errorInfo = errorInfo
                            }
                            self.searchCallbacks.append(searchCallBack)
                        }
                    } else if var searchCallback = self.searchCallbacks.first as? CommonSearchCallBack {
                        if let results = self.spotlightDeduplicateWith(results: responseResults, isSectionType: false) {
                            searchCallback.results.append(contentsOf: results)
                            searchCallback.hasMore = response.hasMore
                            searchCallback.isRemote = isRemote
                            if let errorInfo = response.errorInfo {
                                searchCallback.errorInfo = errorInfo
                            }
                            // 能确保有至少一个元素，不会引起数组越界
                            self.searchCallbacks[0] = searchCallback
                        }
                    }
                }
                if let jumpTabInfo = (response as? BaseSearchResponse)?.suggestionInfo?.jumpTabInfo,
                   !jumpTabInfo.jumpTabs.isEmpty,
                   self.config.shouldShowJumpMore {
                    // 跳转数据（只有综合搜索展示）
                    let jumpTabInfoSection = self.jumpTabInfoIntegrate(jumpTabInfo: jumpTabInfo)
                    self.searchCallbacks.append(SectionSearchCallBack(
                        searchScene: .rustScene(.smartSearch),
                        hasMore: response.hasMore,
                        results: jumpTabInfoSection.jumpResults,
                        isRemote: true,
                        headerInfo: jumpTabInfoSection.sectionHeader,
                        footerInfo: jumpTabInfoSection.sectionFooter,
                        imprID: response.context[SearchResponseImprID.self],
                        contextID: response.context[SearchResponseContextID.self],
                        extra: jumpTabInfoSection.extra
                    ))
                }

                // 设置翻页的 moreToken
                self.moreToken = response.moreToken
                self.errorInfo = response.errorInfo

                let requestTimeInterval = Date().timeIntervalSince(requestStartTime)

                let requestInfo = SearcherState.RequestInfo(input: input,
                                                            isLoadMore: isLoadMore,
                                                            capturedSession: captured,
                                                            requestTimeInterval: requestTimeInterval,
                                                            scene: self.config.scene,
                                                            contextID: response.context[SearchResponseContextID.self],
                                                            requestID: contextID,
                                                            searchError: response.searchError)

                var responseTipType: HotAndColdTipType?
                let hasMore = response.hasMore
                if SearchFeatureGatingKey.searchOneYearData.isUserEnabled(userResolver: self.userResolver),
                   let secondStageSearchEnable = response.secondaryStageSearchable {
                    if !isLoadMore && response.results.isEmpty {
                        /// 无结果页面
                        if secondStageSearchEnable {
                            responseTipType = .noResultForYear
                        } else if response.errorInfo != nil, response.errorCode == 9999 {
                            responseTipType = .noResultForQuotaExceed
                        } else {
                            responseTipType = .noResultForAll
                        }
                    } else if hasMore == false {
                        /// 展示底部的提示
                        if secondStageSearchEnable {
                            responseTipType = .oneYearHasNoMore
                        } else if response.errorInfo != nil, response.errorCode == 9999, response.results.isEmpty {
                            responseTipType = .loadMoreForQuotaExceed
                        } else {
                            responseTipType = .overYearHasNoMore
                        }
                    } else {
                        /// 正常的请求加载
                        if secondStageSearchEnable {
                            responseTipType = .loadMoreHot
                        } else {
                            responseTipType = .loadMoreCold
                        }
                    }
                }
                Self.logger.info("""
                                 HotAndColdTip for MainSearch:
                                 search tip Type: \(responseTipType),
                                 returned \(response.results.count) pieces of data,
                                 hasMore = \(response.hasMore),
                                 moreToken.notNull = \(response.moreToken != nil),
                                 secondary_stage_searchable = \(response.secondaryStageSearchable),
                                 contextID: \(self.searchCallbacks.first?.contextID)
               """)

                self.stateSubject.onNext(.result(callbacks: self.searchCallbacks, requestInfo: requestInfo, responseTipType: responseTipType))
                // Filter Recommendation
                if let baseResponse = response as? BaseSearchResponse, let suggestionInfo = baseResponse.suggestionInfo {
                    let recommendedFilterInfos = suggestionInfo.recommendFilter.filterResults
                        .filter { $0.recommendFilterStrategy == .basedOnQuery }
                        .flatMap { filterResult -> RecommendFilterInfo? in
                            // 只需要拿到第一个
                            guard let first = filterResult.results.first else { return nil }
                            let firstResult = Search.Result(base: first, contextID: baseResponse.context[SearchResponseContextID.self])
                            let chatterItem = SearchChatterPickerItem.searchResultType(firstResult)

                            switch filterResult.filterInTab {
                            case .smartUser:
                                return RecommendFilterInfo(recommendFilter: .recommend(.commonFilter(.mainFrom(fromIds: [chatterItem],
                                                                                                               recommends: [],
                                                                                                               fromType: .recommended,
                                                                                                               isRecommendResultSelected: false))),
                                                           slotSpan: filterResult.slotSpan)
                            case .msgSender:
                                return RecommendFilterInfo(recommendFilter: .recommend(.chatter(mode: .unlimited,
                                                                                                picker: [chatterItem],
                                                                                                recommends: [],
                                                                                                fromType: .recommended,
                                                                                                isRecommendResultSelected: false)),
                                                           slotSpan: filterResult.slotSpan)
                            case .docFrom:
                                return RecommendFilterInfo(recommendFilter: .recommend(.docFrom(fromIds: [chatterItem],
                                                                                                recommends: [],
                                                                                                fromType: .recommended,
                                                                                                isRecommendResultSelected: false)),
                                                           slotSpan: filterResult.slotSpan)
                            @unknown default: return nil
                            }
                        }
                    let _recommendedFilterBasedOnResults = suggestionInfo.recommendFilter.filterResults
                        .filter { $0.recommendFilterStrategy == .basedOnSearchResults }
                        .map { $0.results }
                        .reduce([], { $0 + $1 })
                        .map { Search.Result(base: $0, contextID: baseResponse.context[SearchResponseContextID.self]) }
                    if !isLoadMore || lastRequestIsSpotlight {
                        self.recommendedFilterResultsSubject.onNext(_recommendedFilterBasedOnResults)
                        self.recommendedFilterInfosSubject.onNext(recommendedFilterInfos)
                    }
                }
            }, onError: { [weak self] (error) in
                guard let `self` = self, input.isCompleteSame(with: self.lastInput, userResolver: self.userResolver) else {
                    if let `self` = self, !input.isCompleteSame(with: self.lastInput, userResolver: self.userResolver) {
                        trackForRequestError(failReason: "during input search", isSpotlight: false, isLoadMore: !self.searchCallbacks.isEmpty)
                    }
                    return
                }
                self.didUniversalFinishedBeforeSpotlight = true
                let requestTimeInterval = Date().timeIntervalSince(requestStartTime)
                let isLoadMore = !self.searchCallbacks.isEmpty
                var searchError: SearchError = .timeout
                Self.logger.info("Universal Search error \(error)")
                let requestInfo = SearcherState.RequestInfo(input: input,
                                                            isLoadMore: isLoadMore,
                                                            capturedSession: captured,
                                                            requestTimeInterval: requestTimeInterval,
                                                            scene: self.config.scene,
                                                            contextID: nil,
                                                            requestID: contextID,
                                                            searchError: searchError)
                self.stateSubject.onNext(.error(reason: BundleI18n.LarkSearch.Lark_Legacy_NetworkOrServiceError, requestInfo: requestInfo))
            })
            .disposed(by: disposeBag)
    }
    // enable-lint: long_function
}

extension UniversalSearchService {
    func jumpTabInfoIntegrate(jumpTabInfo: Search_Common_JumpTabInfo) -> OpenSearchJumpCallback {
        var sectionHeader = OpenJumpSectionHeader(title: jumpTabInfo.titleHighlighted)
        var sectionFooter = OpenJumpSectionFooter()
        var jumpResults: [OpenJumpResult] = []
        var jumpMore = OpenJumpResult(type: .openSearchJumpMore)
        var count = 0
        for jumpTab in jumpTabInfo.jumpTabs {
            let iconURL = jumpTab.iconURL
            let titleHighlited = jumpTab.formattedText
            let appLink = jumpTab.appLink
            let jumpResult = OpenJumpResult(type: .openSearchJumpMore,
                                            imageURL: iconURL,
                                            titleHiglited: titleHighlited,
                                            appLink: appLink)
            count += 1
            if count > SearchMainTopResultsTabConfig.openSearchSectionMaxItemNumber {
                jumpMore.moreResult.append(jumpResult)
            } else {
                jumpResults.append(jumpResult)
            }
        }
        if count > SearchMainTopResultsTabConfig.openSearchSectionMaxItemNumber {
            jumpResults.append(jumpMore)
        }
        return OpenSearchJumpCallback(sectionHeader: sectionHeader, sectionFooter: sectionFooter, jumpResults: jumpResults, extra: "")
    }

    func spotlightDeduplicateWith(results: [SearchResultType], isSectionType: Bool) -> [SearchResultType]? {
        var _results = results
        guard !spotlightResults.isEmpty else { return _results }
        guard !_results.isEmpty else { return nil }
        if isSectionType {
            let type = _results.first?.type
            let spotlightCount = spotlightResults.count
            spotlightResults = spotlightResults.filter({ spotlight in
                spotlight.first?.type != type
            })
            if spotlightCount == spotlightResults.count {
                return _results
            } else {
                return nil
            }
        } else {
            guard var _spotlightResults = spotlightResults.first else { return _results }
            let spotlightIds = Set(_spotlightResults.map({ $0.id }))
            let resultIds = Set(_results.map({ $0.id }))
            let commonIds = spotlightIds.intersection(resultIds)
            guard !commonIds.isEmpty else { return _results }

            _results = _results.filter({
                !commonIds.contains($0.id)
            })

            _spotlightResults = _spotlightResults.filter({
                !commonIds.contains($0.id)
            })

            if _spotlightResults.isEmpty {
                spotlightResults.removeFirst()
            } else {
                spotlightResults = Array([_spotlightResults])
            }
            if _results.isEmpty {
                return nil
            } else {
                return _results
            }
        }
    }
}

struct OpenJumpSectionHeader: SearchSectionHeader {
    var title: String
    var avatarKey: String
    var avatarURL: String
    var titleModifiers: [Search_Sections_V1_Modifier]
    init(title: String = "",
         avatarKey: String = "",
         avatarURL: String = "",
         titleModifiers: [Search_Sections_V1_Modifier] = []) {
        self.title = title
        self.avatarKey = avatarKey
        self.avatarURL = avatarURL
        self.titleModifiers = titleModifiers
    }
}
struct OpenJumpSectionFooter: SearchSectionFooter {
    var avatarKey: String
    var text: String
    var action: Search_Sections_V1_Action
    init(avatarKey: String = "",
         text: String = "",
         action: Search_Sections_V1_Action = Search_Sections_V1_Action()) {
        self.avatarKey = avatarKey
        self.text = text
        self.action = action
    }
}
struct OpenJumpResult: SearchResultType {
    var id: String
    var type: LarkSDKInterface.Search.Types
    var contextID: String?
    var avatarID: String?
    var avatarKey: String
    func title(by tag: String) -> NSAttributedString { title }
    var summary: NSAttributedString
    var extra: NSAttributedString
    func extra(by tag: String) -> NSAttributedString { NSAttributedString(string: tag) }
    var meta: LarkSDKInterface.Search.Meta?
    var card: LarkSDKInterface.Search.Card?
    var icon: Basic_V1_Icon?
    var imageURL: String
    var tags: [Basic_V1_Tag]
    var historyType: SearchHistoryType
    // 新增title 和AppLink两个字段，表示cell 展示文本以及 跳转链接
    var title: NSAttributedString
    var appLink: String
    var moreResult: [OpenJumpResult]
    var bid: String
    var entityType: String
    var extraInfos: [Search_V2_ExtraInfoBlock] = []
    var extraInfoSeparator: String = ""
    public var isSpotlight: Bool = false
    public init(id: String = "",
                type: LarkSDKInterface.Search.Types = .unknown,
                contextID: String? = nil,
                avatarID: String? = nil,
                avatarKey: String = "",
                summary: NSAttributedString = NSAttributedString(),
                extra: NSAttributedString = NSAttributedString(),
                meta: LarkSDKInterface.Search.Meta? = nil,
                card: LarkSDKInterface.Search.Card? = nil,
                icon: Basic_V1_Icon? = nil,
                imageURL: String = "",
                tags: [Basic_V1_Tag] = [],
                historyType: SearchHistoryType = SearchHistoryType(),
                titleHiglited: String = "",
                appLink: String = "",
                moreResult: [OpenJumpResult] = [],
                bid: String = "",
                entityType: String = "") {
        self.id = id
        self.type = type
        self.contextID = contextID
        self.avatarID = avatarID
        self.avatarKey = avatarKey
        self.summary = summary
        self.extra = extra
        self.meta = meta
        self.card = card
        self.icon = icon
        self.imageURL = imageURL
        self.tags = tags
        self.historyType = historyType
        self.title = SearchAttributeString(searchHighlightedString: titleHiglited).attributeText
        self.appLink = appLink
        self.moreResult = moreResult
        self.bid = bid
                self.entityType = entityType
    }

}
struct OpenSearchJumpCallback {
    var sectionHeader: OpenJumpSectionHeader
    var sectionFooter: OpenJumpSectionFooter
    var jumpResults: [OpenJumpResult]
    var extra: String
}

extension Search_V2_SearchEntityType {

    static var smartSearchCases: [Search_V2_SearchEntityType] {
        var searchCases: [Search_V2_SearchEntityType] = [.user, .bot, .groupChat, .cryptoP2PChat, .message, .doc, .app, .oncall, .thread]
        // My AI
        if SearchFeatureGatingKey.myAiMainSwitch.isEnabled {
            searchCases.append(.myAi)
        }

        if SearchFeatureGatingKey.isSupportShieldChat.isEnabled {
            searchCases.append(.shieldP2PChat)
        }

        searchCases += [.slashCommand, .wiki, .section]
        return searchCases
    }

}

extension Search_Feedback_V1_SearchResult {
    init(resultType value: SearchResultType) {
        self.init()
        self.id = SearchTrackUtil.encrypt(id: value.id) // 安全起见，所有的id都进行加密传输
        // selboe_larksearch_threadsult.type
        let v1Type: Search_V1_SearchResult.TypeEnum
        switch value.type {
        case .chatter, .bot: v1Type = .chatter
        case .chat:          v1Type = .chat
        case .message:       v1Type = .message
        case Search.Types("docFeed"):       v1Type = .docFeed
        case .email:         v1Type = .email
        case .doc:           v1Type = .doc
        case Search.Types("emailMessage"):  v1Type = .emailMessage
        case .thread:        v1Type = .thread
        case .box:           v1Type = .box
        case .oncall:        v1Type = .oncall
        case .cryptoP2PChat: v1Type = .cryptoP2PChat
        case .openApp:       v1Type = .openApp
        case .link:          v1Type = .link
        case .external:      v1Type = .external
        case .wiki:          v1Type = .wiki
        case .mailContact:   v1Type = .mailContact
        case .department:    v1Type = .department
        case Search.Types("qa"):            v1Type = .qa
        case Search.Types("panoTag"):       v1Type = .panoTag
        case Search.Types("panoView"):      v1Type = .panoView
        case .slashCommand:  v1Type = .slashCommand
        case .section:       v1Type = .section
        default:             v1Type = .unknown
        }
        self.type = Int32(v1Type.rawValue)
        self.name = value.title.string
    }
}
