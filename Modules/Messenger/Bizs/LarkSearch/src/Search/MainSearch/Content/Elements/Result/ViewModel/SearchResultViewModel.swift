//
//  SearchResultViewModel.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/17.
//

import UIKit
import Foundation
import LarkSearchCore
import LarkSDKInterface
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkSearchFilter
import Homeric
import RustPB
import LarkRustClient
import UniverseDesignIcon
import UniverseDesignColor
import ThreadSafeDataStructure // SafeArray
import LarkContainer
import LarkAccountInterface
import SuiteAppConfig
import LarkMessengerInterface

final class SearchResultViewModel {
    struct OpenSearchScope {
        var title: String
        var extra: String
    }
    static let logger = Logger.log(SearchResultViewModel.self, category: "Module.Search")
    private(set) var searcher: Searcher
    let config: SearchTabConfigurable
    let feedAPI: FeedAPI
    let viewModelContext: SearchViewModelContext
    var resultViewWidth: (() -> CGFloat?)?
    var bannerHeight: (() -> CGFloat?)?
    // 折叠/展开部门吸顶栏高度
    var divisionBannerHeight: (() -> CGFloat?)?
    var currentTableView: (() -> UITableView?)?
    private var searchResultSections: [SearchResultSection] = []
    // 是否有部门信息被折叠的数据， 用于控制banner是否展示
    var divisionDidhaveFolded: Bool = false
    // 部门信息是否处于折叠状态
    var divisionInFoldStatus: Bool = true

    /// 根据后端的冷热库判断本次应该展示的页面
    var coldAndHotTipType: HotAndColdTipType?
    var loadingShowDelayTimer: Timer?
    private let disposeBag = DisposeBag()

    private let blockCacheManager = BlockCacheManager()
    let templateManager = DSLTemplateManager()

    private let topInsetForPadStyle = 16

    private lazy var searchOuterService: SearchOuterService? = {
        let service = try? self.userResolver.resolve(assert: SearchOuterService.self)
        return service
    }()

    // MARK: - Debug
    #if DEBUG || INHOUSE || ALPHA
    private let debugDataManager: ASLContextIDProtocol = ASLDebugDataManager()
    var contextID: Driver<String> {
        return debugDataManager.getContextIDDriver()
    }
    #endif

    // MARK: - Forward
    private let shouldRouteSubject = PublishSubject<SearchTab>()
    var shouldRoute: Observable<SearchTab> {
        return shouldRouteSubject.asObservable()
    }

    private let shouldShowRecommendSubject = PublishSubject<Bool>()
    var shouldShowRecommend: Observable<Bool> {
        return shouldShowRecommendSubject.asObservable()
    }

    private let shouldShowNoNetworkPageSubject = PublishSubject<SearchNoNetworkPage.Status>()
    var shouldShowNoNetworkPage: Observable<SearchNoNetworkPage.Status> {
        return shouldShowNoNetworkPageSubject.asObservable()
    }

    private let goToScrollViewContentOffsetSubject = PublishSubject<(CGPoint, Bool)?>()
    var goToScrollViewContentOffset: Observable<(CGPoint, Bool)?> {
        return goToScrollViewContentOffsetSubject.asObservable()
    }

    private let queryChangedSubject = PublishSubject<String>()
    var queryChanged: Observable<String> {
        return queryChangedSubject.asObservable()
    }

    private let shouldOpenProfileSubject = PublishSubject<String>()
    var shouldOpenProfile: Observable<String> {
        return shouldOpenProfileSubject.asObservable()
    }

    private let shouldSaveHistorySubject = PublishSubject<(SearchHistoryModel?, SearchSceneSection, Int)>()
    var shouldSaveHistory: Observable<(SearchHistoryModel?, SearchSceneSection, Int)> {
        return shouldSaveHistorySubject.asObservable()
    }

    private let shouldChangeFilterStyleSubject = PublishSubject<FilterBarStyle>()
    var shouldChangeFilterStyle: Observable<FilterBarStyle> {
        return shouldChangeFilterStyleSubject.asObservable()
    }

    // MARK: - Output
    private let searchResultViewStateSubject = PublishSubject<SearchResultViewState>()
    var searchResultViewState: Driver<SearchResultViewState> {
        return searchResultViewStateSubject.asDriver(onErrorJustReturn: .noResult("", false))
    }

    private let shouldShowLowNetworkBannerSubject = PublishSubject<Bool>()
    var shouldShowLowNetworkBanner: Driver<Bool> {
        return shouldShowLowNetworkBannerSubject.asDriver(onErrorJustReturn: false)
    }

    private let shouldShowDivisionBtnSubject = PublishSubject<Bool>()
    var shouldShowDivisionBtn: Driver<Bool> {
        return shouldShowDivisionBtnSubject.asDriver(onErrorJustReturn: false)
    }
    let shouldAddBottomLoadMoreSubject = PublishSubject<Bool>()
    var shouldAddBottomLoadMore: Driver<Bool> {
        return shouldAddBottomLoadMoreSubject.asDriver(onErrorJustReturn: false)
    }

    private let shouldReconfigRowsSubject = PublishSubject<IndexPath?>()
    var shouldReconfigRows: Driver<IndexPath?> {
        return shouldReconfigRowsSubject.asDriver(onErrorJustReturn: nil)
    }

    private let goToTableViewContentOffsetSubject = PublishSubject<(CGPoint, Bool)?>()
    var goToTableViewContentOffset: Driver<(CGPoint, Bool)?> {
        return goToTableViewContentOffsetSubject.asDriver(onErrorJustReturn: nil)
    }

    private let shouldReloadDataSubject = PublishSubject<Bool>()
    var shouldReloadData: Driver<Bool> {
        return shouldReloadDataSubject.asDriver(onErrorJustReturn: false)
    }

    private lazy var searchStartTimeSubject = PublishSubject<CFTimeInterval>()
    var searchStartTime: Observable<CFTimeInterval> {
        return searchStartTimeSubject.asObservable()
    }

    // MARK: - Configs
    var resultViewBackgroundColor: UIColor {
        return config.resultViewBackgroundColor
    }

    var resultTableViewHorzontalPadding: CGFloat? {
        return config.resultTableViewHorzontalPadding
    }

    var supportLoadMore: Bool {
        return config.supportLoadMore
    }

    var hasMore: Bool {
        return searchResultSections.first?.hasMore ?? false
    }

    var currentCapturedSession: SearchSession.Captured? {
        return searcher.currentCapturedSession
    }

    var feedbackEnabled: Bool {
        return config.supportFeedback && SearchFeatureGatingKey.searchFeedback.isEnabled
    }

    var autoHideFilterEnabled: Bool {
        return config.needAutoHideFilter && !config.supportedFilters.isEmpty
    }

    private(set) var currentPage = 1

    // MARK: - Tracking
    private let resultShowTrackManager = SearchResultShowTrackMananger()
    private let searchProfileTrackManager = SearchProfileTrackManager()
    var lastRequestInfo: SearcherState.RequestInfo? {
        didSet {
            if let requestInfo = lastRequestInfo {
                requestInfoChangeSubject.onNext(requestInfo)
            }
        }
    }

    // 前缀和记录section 对应的查看全部的可点击数量，用于埋点计算
    private(set) var jumpMoreSum: [Int] = []

    private let requestInfoChangeSubject = PublishSubject<SearcherState.RequestInfo>()
    var requestInfoChange: Observable<SearcherState.RequestInfo> {
        return requestInfoChangeSubject.asObservable()
    }

    private let trackSearchEndTimeSubject = PublishSubject<(endTime: CFTimeInterval, requestInfo: SearcherState.RequestInfo)>()
    var trackSearchEndTime: Observable<(endTime: CFTimeInterval, requestInfo: SearcherState.RequestInfo)> {
        return trackSearchEndTimeSubject.asObservable()
    }

    private let shouldRenewSessionSubject = PublishSubject<Bool>()
    var shouldRenewSession: Observable<Bool> {
        return shouldRenewSessionSubject.asObservable()
    }

    private let trackSearchReqeustClickSubject = PublishSubject<SearcherState.RequestInfo>()
    var trackSearchReqeustClick: Observable<SearcherState.RequestInfo> {
        return trackSearchReqeustClickSubject.asObservable()
    }

    struct SearchRequestClickInfo {
        let requestInfo: SearcherState.RequestInfo
        let viewModel: SearchCellViewModel
        let indexPath: IndexPath
        let scene: SearchSceneSection
        let tableView: UITableView
        let isSmartSearch: Bool
        let isSpotlight: Bool
        let isSpotlightOnly: Bool
    }
    private let trackSearchResultClickSubject = PublishSubject<SearchRequestClickInfo>()
    var trackSearchResultClick: Observable<SearchRequestClickInfo> {
        return trackSearchResultClickSubject.asObservable()
    }

    private func trackSearchReqeustClick(info: SearcherState.RequestInfo) {
        if !info.isLoadMore {
            trackSearchReqeustClickSubject.onNext(info)
        }
    }

    private func trackSearchResultClick(info: SearchRequestClickInfo) {
        //点击加载更多不进行上报
        if !(info.viewModel is UnfoldMoreViewModel) {
            trackSearchResultClickSubject.onNext(info)
        }
    }

    let userResolver: UserResolver
    // MARK: - Life Cycles
    init(userResolver: UserResolver,
         searcher: Searcher,
         config: SearchTabConfigurable,
         feedAPI: FeedAPI,
         viewModelContext: SearchViewModelContext) {
        self.userResolver = userResolver
        self.searcher = searcher
        self.config = config
        self.feedAPI = feedAPI
        self.viewModelContext = viewModelContext
        setupSearcher()
    }

    deinit {
        searchProfileTrackManager.tryToTrack()
    }

    private func isResultsEmpty(callbacks: [SearchCallBack]) -> Bool {
        // 不仅要判断是否有 Callback，如果是垂搜还要判断是否 callback 中的 result 为空
        guard !callbacks.isEmpty else {
            return true
        }
        guard callbacks.first?.results.isEmpty == false else {
            return true
        }
        return false
    }

    private func updateState(withState state: SearcherState) {
        self.shouldEnableContainerScrollSubject.onNext(true)
        func trackForRequestSuccess(isSpotlight: Bool, isLoadMore: Bool, count: Int) {
            guard SearchTrackUtil.enablePostTrack() else { return }
            var categoryParams: [String: Any] = [
                "tab_name": self.config.tab.trackRepresentation,
                "is_spotlight": isSpotlight,
                "is_load_more": isLoadMore,
                "count": count
            ]
            if case.open(let info) = self.config.tab {
                categoryParams["search_app_id"] = info.id
            }
            SearchTrackUtil.trackForStableWatcher(domain: "asl_general_search",
                                                  message: "asl_search_success",
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
        switch state {
        case let .result(callbacks, requestInfo, responseTipType):
            defer {
                self.lastRequestInfo = requestInfo
                self.trackSearchReqeustClick(info: requestInfo)
                #if DEBUG || INHOUSE || ALPHA
                self.debugDataManager.contextIDOnNext(contextID: requestInfo.contextID ?? "")
                #endif
            }
            self.loadingShowDelayTimer?.invalidate()
            self.loadingShowDelayTimer = nil
            self.coldAndHotTipType = responseTipType
            self.shouldShowNoNetworkPageSubject.onNext(.hide)
            if let searchError = requestInfo.searchError {
                if self.isResultsEmpty(callbacks: callbacks) {
                    if case .subResults(.messageResults) = self.config.tabType,
                       case .noResultForYear = responseTipType,
                       SearchFeatureGatingKey.searchOneYearData.isUserEnabled(userResolver: userResolver) {
                        self.setNoResultState(withInfo: requestInfo,
                                              endBottomLoadMore: requestInfo.isLoadMore,
                                              searchHotDataForYear: true)
                    } else {
                        self.setNoResultState(withInfo: requestInfo, endBottomLoadMore: requestInfo.isLoadMore)
                    }
                    if SearchFeatureGatingKey.errorTips.isUserEnabled(userResolver: userResolver) {
                        self.shouldShowNoNetworkPageSubject.onNext(.show(searchError))
                    }
                    trackForRequestError(failReason: "Result is empty.Error code is \(searchError.rawValue)",
                                         isSpotlight: requestInfo.spotlightStatus == .spotlightResult || requestInfo.spotlightStatus == .spotlightResultEmpty,
                                         isLoadMore: requestInfo.isLoadMore)
                    return
                } else if requestInfo.spotlightStatus == .spotlightUniversalNetSearchError {
                    self.setSpotlightFinishSearchErrorState(withInfo: requestInfo)
                    if SearchTrackUtil.enablePostTrack() {
                        trackForRequestError(failReason: "SpotlightUniversalNetSearchError.Error code is \(searchError.rawValue)",
                                             isSpotlight: requestInfo.spotlightStatus == .spotlightResult || requestInfo.spotlightStatus == .spotlightResultEmpty,
                                             isLoadMore: requestInfo.isLoadMore)
                    }
                    return
                }
            }

            guard !self.isResultsEmpty(callbacks: callbacks) else {
                trackForRequestSuccess(isSpotlight: requestInfo.spotlightStatus == .spotlightResult || requestInfo.spotlightStatus == .spotlightResultEmpty,
                                       isLoadMore: requestInfo.isLoadMore,
                                       count: 0)
                self.trackSearchEndTimeSubject.onNext((endTime: CACurrentMediaTime(), requestInfo: requestInfo))
                if requestInfo.spotlightStatus == .spotlightResultEmpty {
                    self.searchResultSections = []
                    self.shouldReloadDataSubject.onNext(true)
                    self.searchResultViewStateSubject.onNext(.loading)
                    return
                }
                if case .subResults(.messageResults) = self.config.tabType,
                   case .noResultForYear = responseTipType,
                   SearchFeatureGatingKey.searchOneYearData.isUserEnabled(userResolver: userResolver) {
                    self.setNoResultState(withInfo: requestInfo, searchHotDataForYear: true)
                } else if case .noResultForQuotaExceed = responseTipType {
                    if let errorInfo = (callbacks.first as? CommonSearchCallBack)?.errorInfo {
                        self.searchResultViewStateSubject.onNext(.quotaExceed(errorInfo))
                    }
                } else {
                    self.setNoResultState(withInfo: requestInfo)
                }
                return
            }

            self.searchResultSections = self.transformResultSectionsToShowSections(state: state)
            if case .topResults = self.config.tabType {
                self.jumpMoreSum = [Int](repeating: 0, count: self.searchResultSections.count)
            }

            if requestInfo.searchError != nil, SearchFeatureGatingKey.errorTips.isUserEnabled(userResolver: userResolver) {
                self.shouldShowLowNetworkBannerSubject.onNext(true)
            } else if case .subResults(.chatterResults) = self.config.tabType,
                      self.divisionDidhaveFolded {
                /// 弱网提示与吸顶banner不同时出现
                self.shouldShowDivisionBtnSubject.onNext(true)
            }
            if requestInfo.spotlightStatus == .spotlightResult {
                self.setSpotlightReloadDataState(withInfo: requestInfo)
            } else {
                self.setReloadDataState(withInfo: requestInfo, endBottomLoadMore: self.hasMore)
            }
            self.shouldScrollToTargetIndexPath()
            self.trackSearchEndTimeSubject.onNext((endTime: CACurrentMediaTime(), requestInfo: requestInfo))
            if SearchTrackUtil.enablePostTrack() {
                var count = 0
                callbacks.forEach { (callback) in
                    count += callback.results.count
                }
                trackForRequestSuccess(isSpotlight: requestInfo.spotlightStatus == .spotlightResult || requestInfo.spotlightStatus == .spotlightResultEmpty,
                                       isLoadMore: requestInfo.isLoadMore,
                                       count: count)
            }
        case let .error(reason, requestInfo):
            defer {
                self.lastRequestInfo = requestInfo
            }

            if case .subResults(.messageResults) = self.config.tabType,
               SearchFeatureGatingKey.searchOneYearData.isUserEnabled(userResolver: userResolver) {
                self.setNoResultState(withInfo: requestInfo, endBottomLoadMore: requestInfo.isLoadMore, searchHotDataForYear: true)
            } else {
                self.setNoResultState(withInfo: requestInfo, endBottomLoadMore: requestInfo.isLoadMore)
            }
            if SearchFeatureGatingKey.errorTips.isUserEnabled(userResolver: userResolver) {
                self.shouldShowNoNetworkPageSubject.onNext(.show(requestInfo.searchError ?? .timeout))
            }
            self.trackSearchEndTimeSubject.onNext((endTime: CACurrentMediaTime(), requestInfo: requestInfo))
            self.shouldEnableContainerScrollSubject.onNext(false)
            if SearchTrackUtil.enablePostTrack() {
                var failReason: Any = reason
                if let searchError = requestInfo.searchError {
                    failReason = searchError.rawValue.description
                }
                trackForRequestError(failReason: failReason,
                                     isSpotlight: requestInfo.spotlightStatus == .spotlightResult || requestInfo.spotlightStatus == .spotlightResultEmpty,
                                     isLoadMore: requestInfo.isLoadMore)
            }
        }
    }

    private func transformResultSectionsToShowSections(state: SearcherState) -> [SearchResultSection] {
        guard case let .result(callbacks, _, responseTipType) = state else {
            assertionFailure("Only handle successful cases")
            return []
        }

        let sections = callbacks.map { (callBack) -> SearchResultSection in
            var viewModels = callBack.results.map { result in
                // 联系人Tab 部门信息折叠
                if self.config.tab == .chatter {
                    self.divisionDidhaveFolded = self.divisionDidhaveFolded || self.isResultDivisionTruncated(result: result)
                }
                let viewModel = self.config.cellFactory(forResult: result).createViewModel(userResolver: userResolver, searchResult: result, context: self.viewModelContext)
                return viewModel
            }
            switch self.config.tab {
            case .message:
                // 消息tab 冷热库提醒
                if let result = callBack.results.first,
                   !callBack.hasMore,
                   SearchFeatureGatingKey.searchOneYearData.isUserEnabled(userResolver: userResolver) {
                    switch responseTipType {
                    case .oneYearHasNoMore:
                        viewModels.append(SearchTipViewModel(userResolver: self.userResolver, searchResult: result, showHotTip: true, context: self.viewModelContext))
                    case .overYearHasNoMore:
                        viewModels.append(SearchTipViewModel(userResolver: self.userResolver, searchResult: result, showHotTip: false, context: self.viewModelContext))
                    default:
                        break
                    }
                }
            case .open(let openSearch):
                if openSearch.bizKey == .calendar {
                    viewModels = self.aggregateCalendarViewModels(viewModels: viewModels)
                }
            default: break
            }

            if case .loadMoreForQuotaExceed = responseTipType, let errorInfo = (callBack as? CommonSearchCallBack)?.errorInfo, let result = callBack.results.first {
                let tipVM = SearchTipViewModel(userResolver: self.userResolver, searchResult: result, showHotTip: false, context: self.viewModelContext)
                tipVM.errorInfo = errorInfo
                viewModels.append(tipVM)
            }

            return SearchResultSection(searchCallBack: callBack,
                                       viewModels: viewModels,
                                       searchContext: self.viewModelContext,
                                       resultFrom: self.config.tabType)
        }
        return sections
    }

    private func aggregateCalendarViewModels(viewModels: [SearchCellViewModel]) -> [SearchCellViewModel] {
        let calendarModels: [CalendarSearchViewModel] = viewModels.compactMap { model in
            model as? CalendarSearchViewModel
        }.sorted { lhs, rhs in
            if let lhsCrossDayStartTime = lhs.renderDataModel.crossDayStartTime,
               let rhsCrossDayStartTime = rhs.renderDataModel.crossDayStartTime {
                return lhsCrossDayStartTime < rhsCrossDayStartTime
            }
            return true
        }

        guard !calendarModels.isEmpty else { return [] }

        var finalModels: [SearchCellViewModel] = []
        var lastDayTitleModel = CalendarSearchDayTitleViewModel(userResolver: self.userResolver, searchResult: calendarModels[0].searchResult, renderDataModel: calendarModels[0].renderDataModel)
        finalModels.append(lastDayTitleModel)

        for model in calendarModels {
            if let lastDayTitleDate = lastDayTitleModel.renderDataModel.crossDayStartDate,
                model.renderDataModel.crossDayStartDate?.isSameDay(date: lastDayTitleDate) ?? false {
                finalModels.append(model)
            } else {
                finalModels.append(CalendarSearchDividingLineViewModel(userResolver: self.userResolver, searchResult: model.searchResult))
                lastDayTitleModel = CalendarSearchDayTitleViewModel(userResolver: self.userResolver, searchResult: model.searchResult, renderDataModel: model.renderDataModel)
                finalModels.append(lastDayTitleModel)
                finalModels.append(model)
            }
        }

        return finalModels
    }

    private func shouldScrollToTargetIndexPath() {
        guard !searchResultSections.isEmpty,
              !(searchResultSections.first?.viewModels.isEmpty ?? true), let tableView = currentTableView?() else { return }
        switch self.config.tab {
        case .open(let openSearch):
            if openSearch.bizKey == .calendar {
                let index = searchResultSections[safe: 0]?.viewModels.firstIndex(where: { model in
                    if let model = model as? CalendarSearchDayTitleViewModel,
                       (model.renderDataModel.crossDayStartIsToday ?? false || model.renderDataModel.crossDayStartIsInFuture ?? false) {
                        return true
                    } else {
                        return false
                    }
                })
                if let _index = index, _index >= 0, _index < (searchResultSections[safe: 0]?.viewModels.count ?? 0) {
                    tableView.setNeedsLayout()
                    tableView.layoutIfNeeded()
                    tableView.scrollToRow(at: IndexPath(row: _index, section: 0), at: .top, animated: false)
                    tableView.setNeedsLayout()
                    tableView.layoutIfNeeded()
                }
            }
        default: break
        }
    }

    // MARK: - Setup
    private func setupSearcher() {
        if SearchFeatureGatingKey.closeSearchResultViewModelCrashFix.isUserEnabled(userResolver: userResolver) {
            searcher.state
                .subscribe(onNext: { [weak self] state in
                    guard let self = self else { return }
                    self.updateState(withState: state)
                })
                .disposed(by: disposeBag)
        } else {
            searcher.state.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] state in
                    guard let self = self else { return }
                    self.updateState(withState: state)
                })
                .disposed(by: disposeBag)
        }
    }

    // 判断部门信息是否被截断
    private func isDivisionTruncated(summary: String, labelWidth: CGFloat) -> Bool {
        let font = UIFont.systemFont(ofSize: 14)
        let labelTextSize = (summary as NSString).boundingRect(
            with: CGSize(width: labelWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil).size
        // 产品中部门信息可以展示两行
        return Int(ceil(CGFloat(labelTextSize.height) / font.lineHeight)) > 2
    }

    // 判断结果中的部门信息是否被截断
    private func isResultDivisionTruncated(result: SearchResultType) -> Bool {
        guard let result = result as? Search.Result else { return false }

        let labelWidth = (resultViewWidth?() ?? 136) - 136
//        - 16  //avatar left spacing
//        - 48  //avatar width
//        - 12  //infoView left spacing
//        - 20 // infoView right spacing
//        - 24 // personCard width
//        - 16  //personCard right spacing

        if !result.renderData.isEmpty,
           SearchFeatureGatingKey.searchDynamicResult.isUserEnabled(userResolver: userResolver) {
            return templateManager.isDSLDivisionTruncated(renderData: result.renderData, labelWidth: labelWidth)
        } else {
            return isDivisionTruncated(summary: result.summary.string, labelWidth: labelWidth)
        }
    }

    //现状的reload, spotlightReload, spotlightFinishSearchError，调用resultShowTrackManager.reset()都是有问题的，暂时保持现状，等DA判断
    private func setReloadDataState(withInfo info: SearcherState.RequestInfo, endBottomLoadMore: Bool) {
        resultShowTrackManager.reset()
        resultShowTrackManager.captured = lastRequestInfo?.capturedSession
        resultShowTrackManager.searchTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
        searchResultViewStateSubject.onNext(.reloadData(endBottomLoadMore))
    }

    private func setSpotlightReloadDataState(withInfo info: SearcherState.RequestInfo) {
        resultShowTrackManager.reset()
        resultShowTrackManager.captured = lastRequestInfo?.capturedSession
        resultShowTrackManager.searchTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
        searchResultViewStateSubject.onNext(.spotlight(.spotlightFinishLoading))
    }

    private func setSpotlightFinishSearchErrorState(withInfo info: SearcherState.RequestInfo) {
        resultShowTrackManager.reset()
        resultShowTrackManager.captured = lastRequestInfo?.capturedSession
        resultShowTrackManager.searchTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
        searchResultViewStateSubject.onNext(.spotlight(.spotlightFinishSearchError))
    }

    private func setNoResultState(withInfo info: SearcherState.RequestInfo,
                                  endBottomLoadMore: Bool = false,
                                  searchHotDataForYear: Bool = false) {
        if info.input.isEmpty {
            searchResultViewStateSubject.onNext(.empty)
            return
        }
        resultShowTrackManager.captured = lastRequestInfo?.capturedSession
        resultShowTrackManager.searchTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
        trackSearchShow()
        if searchHotDataForYear {
            searchResultViewStateSubject.onNext(.noResultForYear(info.input.query, endBottomLoadMore))
        } else {
            searchResultViewStateSubject.onNext(.noResult(info.input.query, endBottomLoadMore))
        }

        shouldEnableContainerScrollSubject.onNext(false)
    }

    func trackSearchShow() {
        if let requestInfo = lastRequestInfo {
            let isHasThread = searchResultSections
                                .reduce([]) { $0 + $1.viewModels }
                                .hasThread
            var isCache: Bool?
            if let searchOutService = searchOuterService, searchOutService.enableUseNewSearchEntranceOnPad() {
                isCache = searchOutService.currentIsCacheVC()
            }
            let filters = requestInfo.input.filters
            let advancedFilters = requestInfo.input.advancedSyntaxFilters
            var selectedRecFilter: String?
            if !advancedFilters.isEmpty {
                selectedRecFilter = advancedFilters.convertToSelectedAdvanceSyntaxFilterTrackingInfo()
            } else {
                selectedRecFilter = filters.convertToRecommendFilterTrackingInfo()
            }
            resultShowTrackManager.track(searchLocation: config.searchLocation,
                                         query: requestInfo.input.query,
                                         sceneType: "main",
                                         captured: requestInfo.capturedSession,
                                         filterStatus: filters.withNoFilter ? .none : .some(filters.convertToFilterStatusParam()),
                                         recFilter: selectedRecFilter,
                                         offset: currentPage,
                                         isHasThread: isHasThread,
                                         isCache: isCache)
        }
    }

    // MARK: - Search Releated
    var lastInput: SearcherInput? { searcher.lastInput }

    func search(withInput input: SearcherInput?) {
        guard let input = input else { return }
        defer {
            searcher.lastInput = input
        }
        currentPage = 1
        blockCacheManager.clear()
        loadingShowDelayTimer?.invalidate()
        loadingShowDelayTimer = nil
        goToTableViewContentOffsetSubject.onNext((tableViewTopContentOffset(), false))
        goToScrollViewContentOffsetSubject.onNext((.zero, false))
        shouldAddBottomLoadMoreSubject.onNext(true)
        shouldShowLowNetworkBannerSubject.onNext(false)
        shouldShowDivisionBtnSubject.onNext(false)
        divisionDidhaveFolded = false
        divisionInFoldStatus = true
        shouldShowNoNetworkPageSubject.onNext(.hide)
        if input.isEmpty {
            self.searchResultSections = []
            self.shouldReloadDataSubject.onNext(true)
            searchResultViewStateSubject.onNext(.empty)
            if config.supportUniversalRecommend {
                shouldShowRecommendSubject.onNext(true)
                return
            }
            if !config.supportNoQuery {
                shouldShowRecommendSubject.onNext(false)
                return
            }
        }
        shouldShowRecommendSubject.onNext(false)
        let hasFilters = input.filters.contains { filter in
            !filter.isEmpty
        }
        let enableLoadingDelay = SearchRemoteSettings.shared.searchLoadingShowDelayMS > 0 && !searchResultSections.isEmpty && config.enableSpotlight && !hasFilters
        if enableLoadingDelay {
            let timer = Timer(timeInterval: TimeInterval(SearchRemoteSettings.shared.searchLoadingShowDelayMS) / 1000, repeats: false) {[weak self] timer in
                timer.invalidate()
                guard let self = self else { return }
                self.loadingShowDelayTimer = nil
                self.searchResultViewStateSubject.onNext(.loading)
            }
            RunLoop.main.add(timer, forMode: .common)
            loadingShowDelayTimer = timer
        } else {
            searchResultViewStateSubject.onNext(.loading)
        }
        searchStartTimeSubject.onNext(CACurrentMediaTime())
        searcher.search(input)
    }

    func retrySearch() {
        guard let input = lastInput else { return }
        search(withInput: input)
    }

    func loadMore() {
        searchStartTimeSubject.onNext(CACurrentMediaTime())
        currentPage += 1
        searcher.loadMore()
    }

    // MARK: - Cache
    func makeAndCacheBlockCell(cellViewModel: SearchCellViewModel,
                               indexPath: IndexPath) -> SearchBlockTableViewCell? {
        if let blockViewModel = cellViewModel as? SearchBlockViewModel {
            if let blockCell = blockCacheManager.blockCache[indexPath] {
                return blockCell
            } else {
                guard let currentAccount = (try? userResolver.resolve(assert: PassportUserService.self))?.user else {
                    return nil
                }
                let blockCell = SearchBlockTableViewCell(style: .default, reuseIdentifier: String(describing: SearchBlockTableViewCell.self))
                blockCell.set(viewModel: cellViewModel,
                              currentAccount: currentAccount,
                              searchText: lastInput?.query ?? "")
                blockCell.shouldReload = { [weak self] _ in
                    Self.logger.error("Search block cell reload")
                    self?.contentChange(indexPath: indexPath)
                }
                blockCacheManager.set(value: blockCell, forIndexPath: indexPath)
                return blockCell
            }
        }
        return nil
    }

    // MARK: - Feedback
    private var lastestShowFeedbackID: String?

    var canUpdateFeedbackVisibility: Bool {
        return !(lastestShowFeedbackID == currentCapturedSession?.imprID)
    }
    private let shouldHideFloatFeedBackViewSubject = PublishSubject<Bool>()
    var shouldHideFloatFeedBackView: Driver<Bool> {
        return shouldHideFloatFeedBackViewSubject.asDriver(onErrorJustReturn: false)
    }

    private let showFixedFeedBackViewIfNeededSubject = PublishSubject<Bool>()
    var showFixedFeedBackViewIfNeeded: Driver<Bool> {
        return showFixedFeedBackViewIfNeededSubject.asDriver(onErrorJustReturn: false)
    }

    private let shouldEnableContainerScrollSubject = PublishSubject<Bool>()
    var shouldEnableContainerScroll: Observable<Bool> {
        return shouldEnableContainerScrollSubject.asObservable()
    }

    func showFloatFeedBackView() {
        lastestShowFeedbackID = currentCapturedSession?.imprID
    }

    func feedbackStat(isSend: Bool, entrance: String) {
        var isCache: Bool?
        if let searchOutService = searchOuterService, searchOutService.enableUseNewSearchEntranceOnPad() {
            isCache = searchOutService.currentIsCacheVC()
        }
        var trackInfo: [String: Any] = [
            "click": "feedback",
            "entrance": entrance,
            "result": isSend ? "success" : "view",
            // query相关
            "query_length": lastInput?.query.count ?? 0,
            "query_id": SearchTrackUtil.encrypt(id: lastInput?.query ?? ""),
            "is_filter": false.searchStatValue,
            "impr_id": currentCapturedSession?.imprID ?? "",
            // common context
            "search_location": "quick_search",
            "search_session_id": currentCapturedSession?.session ?? "",
            "scene_type": "main",
            "request_timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ]
        if let isCache = isCache {
            trackInfo["is_cache"] = isCache
        }
        SearchTrackUtil.track(Homeric.ASL_SEARCH_CLICK, params: trackInfo)
    }

    private func instantlyShowFixedFeedbackView() {
        shouldHideFloatFeedBackViewSubject.onNext(true)
        showFixedFeedBackViewIfNeededSubject.onNext(true)
    }

    // MARK: - Filter Related
    func changeFilterStyle(_ style: FilterBarStyle) {
        shouldChangeFilterStyleSubject.onNext(style)
    }

    // MARK: - Cells
    var numberOfSections: Int {
        return searchResultSections.count
    }

    var registeredCellTypes = Set<String>()

    func numberOfRows(in section: Int) -> Int {
        guard let section = searchResultSections[safe: section] else {
            return 0
        }
        return section.viewModels.count
    }

    func isSearchTipCell(forIndexPath indexPath: IndexPath) -> Bool? {
        guard let section = searchResultSections[safe: indexPath.section],
                let viewModel = section.viewModels[safe: indexPath.row] else {
            return nil
        }
        if case .subResults(.messageResults) = self.config.tabType,
            let vm = viewModel as? SearchTipViewModel,
            SearchFeatureGatingKey.searchOneYearData.isUserEnabled(userResolver: userResolver) {
            return true
        } else if case .loadMoreForQuotaExceed = self.coldAndHotTipType, let vm = viewModel as? SearchTipViewModel {
            return true
        } else {
            return false
        }
    }

    func cellType(forIndexPath indexPath: IndexPath) -> SearchTableViewCellProtocol.Type? {
        guard let section = searchResultSections[safe: indexPath.section],
              let viewModel = section.viewModels[safe: indexPath.row] else {
            return nil
        }
        return config.cellType(for: viewModel)
    }

    func cellViewModel(forIndexPath indexPath: IndexPath) -> SearchCellViewModel? {
        guard let section = searchResultSections[safe: indexPath.section],
              let viewModel = section.viewModels[safe: indexPath.row] else {
            return nil
        }
        if let vm = viewModel as? ChatterSearchViewModel {
            vm.indexPath = indexPath
            searchProfileTrackManager.configSearchViewProfileTrackInfo(
                vm: vm,
                getTrackMeta: { [weak self] in
                    guard let self = self else { return nil }
                    let meta = SearchProfileTrackManager.searchViewProfileTrackInfoMeta(
                        sessionID: self.currentCapturedSession?.session ?? "",
                        queryLength: self.lastInput?.query.count ?? 0,
                        resultPosition: "mobile_all")
                    return meta
                }
            )
            vm.saveClickPersonCardHistory = {[weak self] (indexPath, chatterSearchViewModel) in
                guard let self = self, let _indexPath = indexPath, let _chatterSearchViewModel = chatterSearchViewModel else { return }
                guard let section = self.searchResultSections[safe: _indexPath.section] else { return }
                let searchHistoryModel = _chatterSearchViewModel.searchResult
                self.shouldSaveHistorySubject.onNext((searchHistoryModel, section.scene, _indexPath.row + 1))
                self.renewSession(withViewModel: _chatterSearchViewModel)
            }
        } else if var vm = viewModel as? SearchCardViewModel {
            vm.jsBridgeDependency = self
            vm.indexPath = indexPath
            vm.preferredWidth = resultViewWidth?() ?? 0
        } else if var vm = viewModel as? SearchBlockPresentable {
            vm.indexPath = indexPath
        }
        return viewModel
    }

    // MARK: - Header & Footer
    var tabType: SearchTabType {
        return config.tabType
    }

    var headerTypes: [SearchHeaderProtocol.Type] {
        return [SearchTableHeaderView.self]
    }

    func headerType(in section: Int) -> SearchHeaderProtocol.Type? {
        guard let sectionData = searchResultSections[safe: section] else {
            return nil
        }
        guard sectionData.isHeaderEnabled else {
            return nil
        }
        return SearchTableHeaderView.self
    }

    func heightForHeader(in section: Int) -> CGFloat {
        guard let sectionData = searchResultSections[safe: section] else {
            return 0
        }
        if !sectionData.isRemote {
            return bannerHeight?() ?? 46
        } else if self.divisionDidhaveFolded {
            return divisionBannerHeight?() ?? 40
        }
        return sectionData.headerHeight
    }

    func headerViewModel(in section: Int) -> SearchHeaderViewModel? {
        guard let sectionData = searchResultSections[safe: section] else {
            return nil
        }
        guard sectionData.isHeaderEnabled else {
            return nil
        }

        let noResultTitle = BundleI18n.LarkSearch.Lark_Search_SearchNoResult
        let viewModel = SearchHeaderViewModel(icon: nil,
                                              title: sectionData.title,
                                              label: sectionData.viewModels.isEmpty ? noResultTitle : nil,
                                              actionText: BundleI18n.LarkSearch.Lark_Legacy_LoadMore)
        viewModel.didTapHeader = { [weak self] _ in
            self?.jumpMore(section: section)
        }

        return viewModel
    }

    func setHeaderActionStatus(in section: Int, viewModel: SearchHeaderViewModel) {
        guard let sectionData = searchResultSections[safe: section] else {
            return
        }
        guard sectionData.isHeaderEnabled else {
            return
        }
        guard !SearchFeatureGatingKey.mainTabViewMoreAdjust.isUserEnabled(userResolver: userResolver) else {
            viewModel.setHeaderActionVisible(false)
            return
        }
        if sectionData.isRemote {
            if let sectionCallBack = sectionData.searchCallBack as? SectionSearchCallBack,
               getSectionCallbackAction(withSectionCallback: sectionCallBack) != nil {
                viewModel.setHeaderActionVisible(true)
                if (0 ..< jumpMoreSum.count) ~= section {
                    if section == 0 {
                        jumpMoreSum[section] = 1
                    } else {
                        if let lastSum = jumpMoreSum[safe: section - 1] {
                            jumpMoreSum[section] = lastSum + 1
                        }
                    }
                }
            } else {
                if let lastSum = jumpMoreSum[safe: section - 1], (0 ..< jumpMoreSum.count) ~= section {
                    jumpMoreSum[section] = lastSum
                }
                viewModel.setHeaderActionVisible(false)
            }
        } else {
            viewModel.setHeaderActionVisible(true)
        }
    }

    var footerTypes: [SearchFooterProtocol.Type] {
        return [SearchTableFooterView.self]
    }

    func footerType(in section: Int) -> SearchFooterProtocol.Type? {
        guard let sectionData = searchResultSections[safe: section] else {
            return nil
        }
        guard sectionData.isFooterEnabled else {
            return nil
        }
        return SearchTableFooterView.self
    }

    func heightForFooter(in section: Int) -> CGFloat {
        guard let sectionData = searchResultSections[safe: section] else {
            return 0
        }
        if isEnableFooterJunpMore(in: section) {
            return 48 + 8
        } else {
            return sectionData.footerHeight
        }
    }

    func footerViewModel(in section: Int) -> SearchFooterViewModel? {
        guard isEnableFooterJunpMore(in: section) else { return nil }
        guard let sectionData = searchResultSections[safe: section] else { return nil }

        let color = UDColor.primaryContentDefault
        let actionText = BundleI18n.LarkSearch.Lark_Search_ComprehensiveSearch_ResultsInCategories_SearchWithinCategory(sectionData.title)
        let iconImage = UDIcon.getIconByKey(.searchOutlineOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(color)
        let viewModel = SearchFooterViewModel(icon: iconImage, actionText: actionText, titleColor: color)

        viewModel.didTapFooter = { [weak self] _ in
            self?.jumpMore(section: section)
        }

        return viewModel
    }

    //对齐header埋点计数的操作
    func setFooterActionStatus(in section: Int) {
        guard isEnableFooterJunpMore(in: section) else {
            if let lastSum = jumpMoreSum[safe: section - 1], (0 ..< jumpMoreSum.count) ~= section {
                jumpMoreSum[section] = lastSum
            }
            return
        }

        if (0 ..< jumpMoreSum.count) ~= section {
            if section == 0 {
                jumpMoreSum[section] = 1
            } else {
                if let lastSum = jumpMoreSum[safe: section - 1] {
                    jumpMoreSum[section] = lastSum + 1
                }
            }
        }
    }

    //对齐header的setHeaderActionVisible 但是sectionData.isRemote header把actionVisible设置成了true
    func isEnableFooterJunpMore(in section: Int) -> Bool {
        guard let sectionData = searchResultSections[safe: section] else { return false }

        if SearchFeatureGatingKey.mainTabViewMoreAdjust.isUserEnabled(userResolver: userResolver) && sectionData.isFooterEnabled {
            if sectionData.isRemote {
                if let sectionCallBack = sectionData.searchCallBack as? SectionSearchCallBack,
                   getSectionCallbackAction(withSectionCallback: sectionCallBack) != nil {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - tableView
    func didSelect(at indexPath: IndexPath, from: UIViewController) {
        defer {
            // 搜索反馈入口
            instantlyShowFixedFeedbackView()
        }
        guard let viewModel = cellViewModel(forIndexPath: indexPath) else { return }
        if needDealSpecialFilter(viewModel: viewModel) { return }
        viewModel.peakFeedCard(feedAPI, disposeBag: disposeBag)

        // 点击加载更多
        if let vm = viewModel as? UnfoldMoreViewModel, let hideItem = (vm.searchResult as? OpenJumpResult)?.moreResult {
            searchResultSections[indexPath.section].viewModels.removeLast()
            for item in hideItem {
                searchResultSections[indexPath.section].viewModels.append(OpenSearchJumpViewModel(searchResult: item, searchRouteResponder: viewModelContext.searchRouteResponder))
            }
            shouldReloadDataSubject.onNext(true)
            var isCache: Bool?
            if let service = searchOuterService, service.enableUseNewSearchEntranceOnPad() {
                isCache = service.currentIsCacheVC()
            }
            SearchTrackUtil.trackOpenSearchLoadMoreClick(click: "function", target: "none", actionType: "more_entrances", isCache: isCache)
            return
        }

        if SearchFeatureGatingKey.rustSDKSearchFeedbackV2.isUserEnabled(userResolver: userResolver) {
            resultClickActionRustFeedback(at: indexPath)
        }

        // 搜索历史
        let searchHistoryModel = viewModel.didSelectCell(from: from)
        let section = searchResultSections[indexPath.section]
        shouldSaveHistorySubject.onNext((searchHistoryModel, section.scene, indexPath.row + 1))

        // 点击搜索结果
        if let requestInfo = lastRequestInfo,
           let tableView = currentTableView?(),
           let sectionData = searchResultSections[safe: indexPath.section] {
            var isSmartSearch = false
            if let sectionCallback = sectionData.searchCallBack as? SectionSearchCallBack,
               let extra = sectionCallback.extra,
               let jsonData = extra.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any],
               let sectionType = json["sectionType"] as? String {
                isSmartSearch = sectionType == "SectionType_RECOMMEND"
            }
            let isSpotlight = section.isSpotlight(at: indexPath.row)
            var isSpotlightOnly = false
            if let spotlightStatus = lastRequestInfo?.spotlightStatus, isSpotlight {
                isSpotlightOnly = (spotlightStatus == .spotlightResult || spotlightStatus == .spotlightUniversalNetSearchError)
            }
            trackSearchResultClick(info: SearchRequestClickInfo(requestInfo: requestInfo,
                                                                viewModel: viewModel,
                                                                indexPath: indexPath,
                                                                scene: section.scene,
                                                                tableView: tableView,
                                                                isSmartSearch: isSmartSearch,
                                                                isSpotlight: isSpotlight,
                                                                isSpotlightOnly: isSpotlightOnly))
        }
        trackSearchShow()
        renewSession(withViewModel: viewModel)
    }

    private func resultClickActionRustFeedback(at indexPath: IndexPath) {
        guard let viewModel = cellViewModel(forIndexPath: indexPath) else { return }
        // 跳转更多cell的点击事件不反馈
        guard viewModel as? UnfoldMoreViewModel == nil else { return }

        var request: RustPB.Search_V1_SearchFeedbackRequest = RustPB.Search_V1_SearchFeedbackRequest()
        request.query = lastInput?.query ?? ""
        request.imprID = currentCapturedSession?.imprID ?? ""
        var searchFeedback: Search_V1_SearchFeedbackRequest.Feedback = Search_V1_SearchFeedbackRequest.Feedback()
        searchFeedback.entityID = viewModel.searchResult.id
        searchFeedback.typeV2 = Int32(viewModel.searchResult.type.convertToRustSearchEntityType().rawValue)
        var offset: Int = 0
        for i in 0..<indexPath.section {
            offset += numberOfRows(in: i)
        }
        offset += (indexPath.row + 1)
        searchFeedback.offset = Int32(offset)
        request.feedbacks = [searchFeedback]

        let rustService = try? userResolver.resolve(type: RustService.self)
        rustService?.sendAsyncRequest(request).subscribe(onNext: nil).disposed(by: disposeBag)
    }

    private func renewSession(withViewModel viewModel: SearchCellViewModel) {
        // 点击跳转按钮不更新 session
        if viewModel is OpenSearchJumpViewModel || viewModel is UnfoldMoreViewModel {
            return
        }

        // Renew Session
        shouldRenewSessionSubject.onNext(true)
    }

    func willDisplay(at indexPath: IndexPath, in tableView: UITableView) {
        guard let section = searchResultSections[safe: indexPath.section],
              let viewModel = section.viewModels[safe: indexPath.row] else {
            return
        }
        var isSmartSearch: Bool?
        if let extra = (section.searchCallBack as? SectionSearchCallBack)?.extra,
           let jsonData = extra.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any],
           let sectionType = json["sectionType"] as? String {
           isSmartSearch = (sectionType == "SectionType_RECOMMEND")
        }
        let isSpotlight = section.isSpotlight(at: indexPath.row)
        var isSpotlightOnly = false
        if let spotlightStatus = lastRequestInfo?.spotlightStatus, isSpotlight {
            isSpotlightOnly = (spotlightStatus == .spotlightResult || spotlightStatus == .spotlightUniversalNetSearchError)
        }
        let extraJudgement = SearchResultShowTrackMananger.ExtraJudgement(isSmartSearch: isSmartSearch, isSpotlight: isSpotlight, isSpotlightOnly: isSpotlightOnly)

        resultShowTrackManager.willDisplay(result: viewModel.searchResult, searchScene: section.scene, at: indexPath, in: tableView, extraJudgement: extraJudgement)
    }

    /// 处理filter放在result里的特化情况，返回true代表处理成功
    func needDealSpecialFilter(viewModel: SearchCellViewModel) -> Bool {
        if case .slash(let meta) = viewModel.searchResult.meta, meta.slashCommand == .filter {
            assertionFailure("this type is deprecated!")
            return true
        } else {
            return false
        }
    }

    // MARK: - Router
    func jumpMore(section: Int) {
        guard showMore(section: section) else { return }
        guard let sectionData = searchResultSections[safe: section] else {
            return
        }
        if let sectionCallBack = sectionData.searchCallBack as? SectionSearchCallBack,
           let action = getSectionCallbackAction(withSectionCallback: sectionCallBack) {
            var isSmartSearch = false
            if let jsonData = sectionCallBack.extra?.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any],
               let sectionType = json["sectionType"] as? String {
                isSmartSearch = (sectionType == "SectionType_RECOMMEND")
            }

            var slashId: String?
            if let extra = sectionCallBack.extra,
               let jsonData = extra.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any],
               let appId = json["appID"] as? String {
                slashId = appId
            }

            let calendarMigration = SearchFeatureGatingKey.searchCalendarMigration.isUserEnabled(userResolver: userResolver)
            let emailMigration = SearchFeatureGatingKey.searchEmailMigration.isUserEnabled(userResolver: userResolver)
            var isCalendarResult: Bool = false
            var isEmailResult: Bool = false

            if let result = sectionData.viewModels.first?.searchResult,
               result.type == .calendarEvent,
               result.bid.elementsEqual("lark"),
               result.entityType.elementsEqual("calendar-event") {
                isCalendarResult = true
            }
            if let type = sectionData.viewModels.first?.searchResult.type, type == .email {
                isEmailResult = true
            }

            if calendarMigration != emailMigration, ((calendarMigration && isEmailResult) || (emailMigration && isCalendarResult)) {
                if let tableView = currentTableView?() {
                    let filters = lastInput?.filters ?? []
                    var isCache: Bool?
                    if let searchOutService = searchOuterService, searchOutService.enableUseNewSearchEntranceOnPad() {
                        isCache = searchOutService.currentIsCacheVC()
                    }
                    SearchTrackUtil.trackSearchMoreResultClick(action: isEmailResult ? SearchSectionAction.mail : SearchSectionAction.calendar,
                                                               sessionId: currentCapturedSession?.session ?? "",
                                                               searchLocation: config.searchLocation,
                                                               isSmartSearch: isSmartSearch,
                                                               query: lastInput?.query ?? "",
                                                               sceneType: "main",
                                                               filterStatus: filters.withNoFilter ? .none : .some(filters.convertToFilterStatusParam()),
                                                               imprID: currentCapturedSession?.imprID ?? "",
                                                               at: IndexPath(row: -1, section: section),
                                                               in: tableView,
                                                               slashId: nil,
                                                               moreButton: jumpMoreSum,
                                                               isCache: isCache)
                }
                shouldRouteSubject.onNext(isEmailResult ? .email : .calendar)
            } else {
                if let tableView = currentTableView?() {
                    let filters = lastInput?.filters ?? []
                    SearchTrackUtil.trackSearchMoreResultClick(action: action,
                                                               sessionId: currentCapturedSession?.session ?? "",
                                                               searchLocation: config.searchLocation,
                                                               isSmartSearch: isSmartSearch,
                                                               query: lastInput?.query ?? "",
                                                               sceneType: "main",
                                                               filterStatus: filters.withNoFilter ? .none : .some(filters.convertToFilterStatusParam()),
                                                               imprID: currentCapturedSession?.imprID ?? "",
                                                               at: IndexPath(row: -1, section: section),
                                                               in: tableView,
                                                               slashId: slashId,
                                                               moreButton: jumpMoreSum)
                }
                guard let type = makeSearchTab(withAction: action, callback: sectionCallBack, appId: slashId) else { return }
                shouldRouteSubject.onNext(type)
            }
        }

        instantlyShowFixedFeedbackView()
    }

    func showMore(section: Int) -> Bool {
        guard let sectionData = searchResultSections[safe: section] else {
            return false
        }
        if let sectionCallBack = sectionData.searchCallBack as? SectionSearchCallBack,
           getSectionCallbackAction(withSectionCallback: sectionCallBack) != nil {
            return true
        }
        return false
    }

    func openSearchTab(appId: String, tabName: String) {
        shouldRouteSubject.onNext(SearchTab.open(SearchTab.OpenSearch(id: appId, label: tabName, icon: nil, resultType: .slashCommand, filters: [])))
    }

    private func getSectionCallbackAction(withSectionCallback sectionCallBack: SectionSearchCallBack) -> SearchSectionAction? {
        guard let url = URL(string: sectionCallBack.footerInfo.action.uri),
           let target = url.queryParameters.first(where: { $0.key == "target" })?.value,
           let actionType = SearchSectionAction(rawValue: target),
           sectionCallBack.footerInfo.action.type == .searchInside else {
            return nil
        }
        return actionType
    }

    private func makeSearchTab(withSection section: SearchResultSection) -> SearchTab? {
        switch section.scene {
        case .rustScene(.searchOpenAppScene):
            return .app
        case .rustScene(.searchCalendarEventScene):
            return .calendar
        case .searchChatInAdvanceOnly, .rustScene(.searchChatsInAdvanceScene), .rustScene(.searchChats):
            return .chat
        case .rustScene(.searchChatters):
            return .chatter
        case .rustScene(.searchDoc):
            return .doc
        case .searchMessageOnly, .rustScene(.searchMessages):
            return .message
        case .rustScene(.searchOncallScene):
            return .oncall
        default:
            return nil
        }
    }

    private func makeSearchTab(withAction action: SearchSectionAction, callback: SectionSearchCallBack, appId: String?) -> SearchTab? {
        switch action {
        case .doc: return .doc
        case .wiki: return .wiki
        case .calendar: return .calendar
        case .mail: return .email
        case .group: return .chat
        case .message: return .message
        case .thread: return .thread
        case .topic: return .topic
        case .app: return .app
        case .contacts: return .chatter
        case .oncall: return .oncall
        case .openSearch, .slashCommand:
            guard let appId = appId else { return nil }
            return .open(SearchTab.OpenSearch(id: appId, label: callback.headerInfo.title, icon: nil, resultType: .slashCommand, filters: []))
        default:
            assertionFailure("No such search Tab!")
            return nil
        }
    }
}

extension SearchResultViewModel: ASLynxBridgeDependencyDelegate {
    func contentChange(indexPath: IndexPath?) {
        guard let indexPath = indexPath else {
            return
        }
        shouldReconfigRowsSubject.onNext(indexPath)
    }

    func changeQuery(_ query: String, vm: SearchCardViewModel) {
        goToTableViewContentOffsetSubject.onNext((tableViewTopContentOffset(), false))
        goToScrollViewContentOffsetSubject.onNext((.zero, false))
        queryChangedSubject.onNext(query)
    }

    func sendClickEvent(vm: SearchCardViewModel, params: [String: Any]) {
        guard let indexPath = vm.indexPath else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let tableView = self.currentTableView?() {
                var isCache: Bool?
                if let searchOutService = searchOuterService, searchOutService.enableUseNewSearchEntranceOnPad() {
                    isCache = searchOutService.currentIsCacheVC()
                }
                let filters = self.lastInput?.filters ?? []
                let advancedFilters = self.lastInput?.advancedSyntaxFilters ?? []
                var selectedRecFilter: String?
                if !advancedFilters.isEmpty {
                    selectedRecFilter = advancedFilters.convertToSelectedAdvanceSyntaxFilterTrackingInfo()
                } else {
                    selectedRecFilter = filters.convertToSelectedRecommendFilterTrackingInfo()
                }
                SearchTrackUtil.trackSearchResultClick(viewModel: vm,
                                                       sessionId: self.currentCapturedSession?.session ?? "",
                                                       searchLocation: self.config.searchLocation,
                                                       isSmartSearch: false,
                                                       isSuggested: false,
                                                       query: self.lastInput?.query ?? "",
                                                       sceneType: "main",
                                                       filterStatus: filters.withNoFilter ? .none : .some(filters.convertToFilterStatusParam()),
                                                       selectedRecFilter: selectedRecFilter,
                                                       imprID: self.currentCapturedSession?.imprID ?? "",
                                                       at: indexPath,
                                                       in: tableView,
                                                       extraParam: params,
                                                       isCache: isCache)
            }
        }
    }

    func openProfile(userId: String, vm: SearchCardViewModel) {
        shouldOpenProfileSubject.onNext(userId)
    }

    func openSearchTab(appId: String, tabName: String, vm: SearchCardViewModel) {
        shouldRouteSubject.onNext(SearchTab.open(SearchTab.OpenSearch(id: appId, label: tabName, icon: nil, resultType: .customization, filters: [])))
    }

    func tableViewTopOffset() -> Int {
        if let searchOutService = searchOuterService, searchOutService.enableUseNewSearchEntranceOnPad() {
            let isShowCapsule = SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: self.userResolver) && !AppConfigManager.shared.leanModeIsOn
            // ipad改版样式&全屏模式下&胶囊样式需要顶部宽度
            if !searchOutService.isCompactStatus() && isShowCapsule {
                return topInsetForPadStyle
            } else {
                return 0
            }
        }
        return 0
    }

    private func tableViewTopContentOffset() -> CGPoint {
        return CGPoint(x: 0, y: -1 * tableViewTopOffset())
    }

}

extension SearchResultViewModel: FeedbackContextDelegate {
    func getSearchRequestV1() -> Search_V1_IntegrationSearchRequest {
        var request = Search_V1_IntegrationSearchRequest()
        request.query = lastInput?.query ?? ""
        request.end = 15
        request.sceneType = .smartSearch
        if let captured = currentCapturedSession {
            request.searchSession = captured.session
            request.imprID = captured.imprID
        }
        return request
    }
    func getFeedBackSearchResult() -> [Search_Feedback_V1_SearchResult] {
        return searchResultSections.flatMap { $0.searchCallBack.results }.map {
            Search_Feedback_V1_SearchResult(resultType: $0)
        }
    }
}

struct SearchResultSection: Equatable {
    static func == (lhs: SearchResultSection, rhs: SearchResultSection) -> Bool {
        // 通过相等复用，修复SearchDataCenter的增量Push导致重建ViewModel，打断点击的问题。
        // 但当发起新请求时，不应该复用（远端更新，高亮更新等）。此处用contextID来区分是否新请求。
        // 没实现在searchResult的== 是因为去重还是用id和type来保证唯一性的。避免影响到其它代码
        return lhs.scene == rhs.scene && lhs.searchCallBack.contextID == rhs.searchCallBack.contextID
        && lhs.searchCallBack.results.elementsEqual(rhs.searchCallBack.results) { $0.optionIdentifier == $1.optionIdentifier }
    }

    let searchCallBack: SearchCallBack
    var viewModels: [SearchCellViewModel]
    let searchContext: SearchViewModelContext
    let resultFrom: SearchTabType

    // 只有综合搜索的时候才需要展示 section title
    var title: String {
        if let sectionCallback = searchCallBack as? SectionSearchCallBack {
            return sectionCallback.headerInfo.title
        }
        return ""
    }

    var isRemote: Bool {
        return searchCallBack.isRemote
    }

    var isHeaderEnabled: Bool {
        switch resultFrom {
        case .topResults:
            return true
        case .subResults:
            return !searchCallBack.isRemote
        }
    }

    var isFooterEnabled: Bool {
        switch resultFrom {
        case .topResults:
            return true
        case .subResults:
            return false
        }
    }

    var headerHeight: CGFloat {
        switch resultFrom {
        case .topResults:
            // 卡片不需要 section 标题
            if searchCallBack.searchScene == .searchServiceCard {
                return 0
            }

            // block
            if searchCallBack.searchScene == .searchBlock {
                if title.isEmpty {
                    return 0
                }
                return SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled ? 42 : 46
            }

            if viewModels.isEmpty {
                return 107
            }

            if !searchCallBack.isRemote {
                return SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled ? 42 : 46
            }

            if title.isEmpty {
                return 12
            }

            return SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled ? 42 : 46
        case .subResults:
            return 0
        }
    }

    var footerHeight: CGFloat {
        switch resultFrom {
        case .topResults:
            //卡片不用留高度，卡片内部自己画
            if searchCallBack.searchScene == .searchServiceCard {
                return 0
            }

            return 20
        case .subResults:
            return 0
        }
    }

    var scene: SearchSceneSection {
        return searchCallBack.searchScene
    }

    var hasMore: Bool {
        return searchCallBack.hasMore
    }

    var resultsCount: Int {
        return searchCallBack.results.count
    }

    func isSpotlight(at row: Int) -> Bool {
        guard searchCallBack.isSpotlight else { return false }
        guard let result = searchCallBack.results[safe: row] else { return false }
        return result.isSpotlight
    }
}

final class BlockCacheManager {
    static let logger = Logger.log(BlockCacheManager.self, category: "Module.IM.Search")
    private(set) var blockCache: [IndexPath: SearchBlockTableViewCell] = [:]
    func clear() {
        for (_, blockCell) in blockCache {
            guard let uniqueId = blockCell.currentUniqueId, let blockViewModel = blockCell.viewModel as? SearchBlockViewModel else { continue }
            Self.logger.info("Search block unmount \(uniqueId)")
            blockViewModel.blockService?.unMountBlock(id: uniqueId)
            blockCell.reset()
        }
        blockCache = [:]
    }
    deinit {
        clear()
    }
    func set(value: SearchBlockTableViewCell, forIndexPath indexPath: IndexPath) {
        blockCache[indexPath] = value
    }
}

protocol FeedbackContextDelegate: AnyObject {
    var lastInput: SearcherInput? { get }
    func getSearchRequestV1() -> Search_V1_IntegrationSearchRequest
    func getFeedBackSearchResult() -> [Search_Feedback_V1_SearchResult]
    func feedbackStat(isSend: Bool, entrance: String)
}

struct FeedbackContext: SearchFeedBackViewControllerContext {
    weak var delegate: FeedbackContextDelegate?
    let entrance: String
    func willSend(feedback: inout Search_Feedback_V1_FeedbackRequest) -> Bool {
        guard let delegate = delegate else { return false }

        var param = Search_Feedback_V1_FeedbackParam()
        param.integrationSearch.searchRequest = delegate.getSearchRequestV1()
        param.integrationSearch.searchRequest.query = delegate.lastInput?.query ?? ""
        param.integrationSearch.results = delegate.getFeedBackSearchResult()

        feedback.scene = .integrationSearch
        feedback.param = param
        return true
    }
    func didSendFeedback() {
        delegate?.feedbackStat(isSend: true, entrance: entrance)
    }
}

extension Array where Element == SearchCellViewModel {
    var hasThread: Bool {
        for viewModel in self {
            if viewModel.searchResult.hasThread { return true }
        }
        return false
    }
}

extension String {
    func trimmingForSearch() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
