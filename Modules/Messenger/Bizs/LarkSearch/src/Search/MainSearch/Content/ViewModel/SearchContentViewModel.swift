//
//  SearchContentViewModel.swift
//  LarkSearch
//
//  Created by Patrick on 2022/5/19.
//

import UIKit
import Foundation
import LarkSearchFilter
import RxSwift
import ServerPB
import RxCocoa
import LarkSearchCore
import LarkSDKInterface
import LarkAccountInterface
import LarkContainer
import SuiteAppConfig
import LKCommonsLogging
import LarkMessengerInterface

final class SearchContentViewModel {
    static let logger = Logger.log(SearchContentViewModel.self, category: "Module.IM.Search")
    var config: SearchTabConfigurable
    var searchRepo: SearchRepo
    let historyStore: SearchQueryHistoryStore

    let searchResultViewModel: SearchResultViewModel
    let searchFilterViewModel: SearchFilterViewModel?
    let universalRecommendViewModel: UniversalRecommendViewModel?
    let viewModelContext: SearchViewModelContext
    let rootViewModel: SearchRootViewModelProtocol

    // MARK: - Tracking
    private let searchTimeTrackManager = SearchTimeTrackManager()

    private let queryBehavior = BehaviorRelay<String?>(value: nil)
    private let filtersBehavior: BehaviorRelay<[SearchFilter]>

    // MARK: - Output
    private let shouldShowRecommendSubject = PublishSubject<Bool>()
    var shouldShowRecommend: Driver<Bool> {
        return shouldShowRecommendSubject.asDriver(onErrorJustReturn: false)
    }

    private let shouldChangeFilterStyleSubject = PublishSubject<FilterBarStyle>()
    var shouldChangeFilterStyle: Driver<FilterBarStyle> {
        return shouldChangeFilterStyleSubject.asDriver(onErrorJustReturn: config.filterBarStyle)
    }

    private let shouldShowNoNetworkPageSubject = PublishSubject<SearchNoNetworkPage.Status>()
    var shouldShowNoNetworkPage: Driver<SearchNoNetworkPage.Status> {
        return shouldShowNoNetworkPageSubject.asDriver(onErrorJustReturn: .hide)
    }

    private let goToScrollViewContentOffsetSubject = PublishSubject<(CGPoint, Bool)?>()
    var goToScrollViewContentOffset: Driver<(CGPoint, Bool)?> {
        return goToScrollViewContentOffsetSubject.asDriver(onErrorJustReturn: nil)
    }

    private let shouldEnableContainerScrollSubject = PublishSubject<Bool>()
    var shouldEnableContainerScroll: Driver<Bool> {
        return shouldEnableContainerScrollSubject.asDriver(onErrorJustReturn: false)
    }

    private let shouldOpenProfileSubject = PublishSubject<String>()
    var shouldOpenProfile: Observable<String> {
        return shouldOpenProfileSubject.asObservable()
    }

    // MARK: - Config
    var autoHideFilterEnabled: Bool {
        return config.needAutoHideFilter && !config.supportedFilters.isEmpty
    }

    var resultViewBackgroundColor: UIColor {
        return config.resultViewBackgroundColor
    }

    var lastRequestInfo: SearcherState.RequestInfo? {
        return searchResultViewModel.lastRequestInfo
    }

    var searchWidthGetter: (() -> CGFloat)? {
        didSet {
            searchRepo.searchWidthGetter = searchWidthGetter
        }
    }

    var isIntentionCapsuleStyle: Bool {
        if rootViewModel as? SearchMainRootViewModel != nil &&
            SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: userResolver) &&
            !AppConfigManager.shared.leanModeIsOn {
            return true
        }
        return false
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver,
         config: SearchTabConfigurable,
         searchRepo: SearchRepo,
         historyStore: SearchQueryHistoryStore,
         viewModelContext: SearchViewModelContext,
         rootViewModel: SearchRootViewModelProtocol,
         searchResultViewModelFactory: SearchResultViewModelFactory,
         searchFilterViewModelFactory: SearchFilterViewModelFactory,
         universalRecommendViewModelFactory: UniversalRecommendViewModelFactory) {
        self.userResolver = userResolver
        self.config = config
        self.searchRepo = searchRepo
        self.historyStore = historyStore
        self.viewModelContext = viewModelContext
        self.rootViewModel = rootViewModel
        self.searchResultViewModel = searchResultViewModelFactory.makeSearchResultViewModel()
        self.searchFilterViewModel = searchFilterViewModelFactory.makeSearchFilterViewModel()
        self.universalRecommendViewModel = universalRecommendViewModelFactory.makeUniversalRecommendViewModel()
        self.filtersBehavior = BehaviorRelay<[SearchFilter]>(value: config.supportedFilters)
        self.universalRecommendViewModel?.delegate = self
        setupSubscribe()
        self.viewModelContext.clickInfo = { [weak self] in
            return SearchViewModelContext.ClickInfo(sessionId: self?.lastRequestInfo?.capturedSession.session,
                                                    imprId: self?.lastRequestInfo?.capturedSession.imprID,
                                                    query: self?.lastRequestInfo?.input.query,
                                                    searchLocation: self?.config.searchLocation ?? "quick_search",
                                                    sceneType: "main",
                                                    filters: self?.lastRequestInfo?.input.filters ?? [])
        }
    }

    func retrySearch() {
        searchResultViewModel.retrySearch()
    }

    func queryChange(text: String) {
        queryBehavior.accept(text)
    }

    func filtersChange(filters: [SearchFilter]) {
        filtersBehavior.accept(filters)
    }

    func routeTo(withSearchInput input: SearcherInput, isCapsuleStyle: Bool) {
        if isCapsuleStyle {
            // 胶囊无缓存，无需重置
            // commonFilter转化，前置做了
            queryChange(text: input.query)
            filtersBehavior.accept(input.filters)
        } else {
            // 暂时只需要转换 commonFilter
            // 把之前filterViewModel里缓存的筛选器数据清除
            searchFilterViewModel?.resetAllFilters()

            let routeFilters = makeRouteFilterWithCommonFilter(input.filters)
            searchFilterViewModel?.refocusTo(filters: routeFilters)
            searchFilterViewModel?.replaceAllFilters(routeFilters)
            queryChange(text: input.query)
        }
    }

    private let disposeBag = DisposeBag()
    private func setupSubscribe() {
        // Search
        let searchOutService = try? self.userResolver.resolve(assert: SearchOuterService.self)
        let trimmedQuery = queryBehavior.flatMap { text -> Observable<String> in
            guard let text = text else { return Observable.empty() }
            return Observable.just(text.trimmingForSearch())
        }
        if let searchFilterViewModel = self.searchFilterViewModel {
            searchFilterViewModel.filterChanged.subscribe { [weak self] filters in
                guard let self = self else { return }
                self.filtersBehavior.accept(filters)
            }.disposed(by: disposeBag)
        }

        if isIntentionCapsuleStyle {
            Observable.combineLatest(trimmedQuery, filtersBehavior)
                .debounce(.milliseconds(SearchRemoteSettings.shared.searchDebounceMs), scheduler: MainScheduler.instance)
                .map { SearcherInput(query: $0, filters: $1) }
                .distinctUntilChanged()
                .subscribe(onNext: { [weak self] input in
                    guard let self = self else { return }
                    // messageType 需要单独处理
                    for case .messageType(let type) in input.filters {
                        self.updateCurrentMessageSubConfig(by: type)
                        break
                    }
                    self.searchTimeTrackManager.startTime = CACurrentMediaTime()
                    self.searchFilterViewModel?.removeAllRecommendFilters()
                    self.search(withTab: self.config.tab, input: input)
                })
                .disposed(by: disposeBag)
        } else {
            let filters: Observable<[SearchFilter]> = {
                return Observable.create { [weak self] observer in
                    guard let searchFilterViewModel = self?.searchFilterViewModel else {
                        observer.onNext([])
                        return Disposables.create()
                    }
                    return searchFilterViewModel.filterChanged
                        .do(onNext: { [weak self] filters in
                            guard let self = self else { return }
                            // messageType 需要单独处理
                            for case .messageType(let type) in filters {
                                self.updateCurrentMessageSubConfig(by: type)
                                break
                            }
                        })
                            .subscribe(observer)
                }
            }()
            Observable.combineLatest(trimmedQuery, filters)
                .debounce(.milliseconds(SearchRemoteSettings.shared.searchDebounceMs), scheduler: MainScheduler.instance)
                .map { SearcherInput(query: $0, filters: $1) }
                .distinctUntilChanged()
                .subscribe(onNext: { [weak self] input in
                    guard let self = self else { return }
                    self.searchTimeTrackManager.startTime = CACurrentMediaTime()
                    self.searchFilterViewModel?.removeAllRecommendFilters()
                    self.search(withTab: self.config.tab, input: input)
                })
                .disposed(by: disposeBag)
        }

        // 对shouldShowRecommendSubject发布true时，需要对status进行检验
        if let status = universalRecommendViewModel?.status.asObservable() {
            Observable
                .combineLatest(searchResultViewModel.shouldShowRecommend, status)
                .subscribe { [weak self] (shouldShowRecommend, status) in
                    guard let self = self else { return }
                    if shouldShowRecommend, status == .result {
                        self.shouldShowRecommendSubject.onNext(true)
                    }
                }
                .disposed(by: disposeBag)
        }

        searchResultVMSubscribe()
        searchFilterVMSubscribe()
        searchResultVMTrackSubscribe()
    }

    private func searchResultVMSubscribe() {
        // 对shouldShowRecommendSubject发布false时，无需校验
        searchResultViewModel.shouldShowRecommend.subscribe(onNext: { [weak self] shouldShowRecommend in
            guard let self = self else { return }
            if !shouldShowRecommend {
                self.shouldShowRecommendSubject.onNext(false)
            }
        })
        .disposed(by: disposeBag)

        searchResultViewModel.shouldRoute
            .subscribe(onNext: { [weak self] type in
                guard let self = self else { return }
                let query = self.queryBehavior.value ?? ""
                var filters: [SearchFilter]
                if self.isIntentionCapsuleStyle {
                    filters = self.filtersBehavior.value
                } else {
                    filters = self.searchFilterViewModel?.filters ?? []
                }
                self.rootViewModel.route(withParam: SearchRouteParam(type: type, input: SearcherInput(query: query, filters: filters)))
            })
            .disposed(by: disposeBag)

        searchResultViewModel.shouldSaveHistory
            .subscribe(onNext: { [weak self] (historyModel, scene, offset) in
                guard let self = self else { return }
                self.saveQueryHistory(searchHistoryModel: historyModel, scene: scene, offset: offset)
            })
            .disposed(by: disposeBag)

        searchResultViewModel.shouldOpenProfile
            .bind(to: shouldOpenProfileSubject)
            .disposed(by: disposeBag)

        searchResultViewModel.queryChanged
            .subscribe(onNext: { [weak self] newQuery in
                guard let self = self else { return }
                self.rootViewModel.changeSearchText(newQuery)
                self.queryBehavior.accept(newQuery)
            })
            .disposed(by: disposeBag)

        searchResultViewModel.shouldShowNoNetworkPage
            .bind(to: shouldShowNoNetworkPageSubject)
            .disposed(by: disposeBag)

        searchResultViewModel.goToScrollViewContentOffset
            .bind(to: goToScrollViewContentOffsetSubject)
            .disposed(by: disposeBag)

        universalRecommendViewModel?.goToScrollViewContentOffset
            .bind(to: goToScrollViewContentOffsetSubject)
            .disposed(by: disposeBag)

        if autoHideFilterEnabled {
            searchResultViewModel.shouldChangeFilterStyle
                .bind(to: shouldChangeFilterStyleSubject)
                .disposed(by: disposeBag)
            searchResultViewModel.shouldEnableContainerScroll
                .bind(to: shouldEnableContainerScrollSubject)
                .disposed(by: disposeBag)
            universalRecommendViewModel?.shouldChangeFilterStyle
                .bind(to: shouldChangeFilterStyleSubject)
                .disposed(by: disposeBag)
            universalRecommendViewModel?.shouldEnableContainerScroll
                .bind(to: shouldEnableContainerScrollSubject)
                .disposed(by: disposeBag)
        }
    }

    private func searchResultVMTrackSubscribe() {
        let searchOutService = try? self.userResolver.resolve(assert: SearchOuterService.self)
        // Tracking
        searchResultViewModel.trackSearchEndTime
            .subscribe(onNext: { [weak self] (endTime, requestInfo) in
                guard let self = self else { return }
                var isSpotlight = false
                if requestInfo.spotlightStatus == .spotlightResult || requestInfo.spotlightStatus == .spotlightResultEmpty {
                    isSpotlight = true
                }
                self.searchTimeTrackManager.track(endTime: endTime,
                                                  searchLocation: self.config.searchLocation,
                                                  query: requestInfo.input.query,
                                                  sceneType: "main",
                                                  imprID: requestInfo.capturedSession.imprID,
                                                  searchId: requestInfo.contextID ?? "none",
                                                  isSpotlight: isSpotlight)
                self.searchTimeTrackManager.trackForDuration(domain: "asl_general_search",
                                                             endTime: endTime,
                                                             isSpotlight: isSpotlight,
                                                             isLoadMore: requestInfo.isLoadMore,
                                                             errorCode: requestInfo.searchError,
                                                             tabType: self.config.tab,
                                                             isInChat: false)
            })
            .disposed(by: disposeBag)

        searchResultViewModel.trackSearchReqeustClick
            .subscribe(onNext: { [weak self] requestInfo in
                guard let self = self else { return }
                var isCache: Bool?
                if let searchOutService = searchOutService, searchOutService.enableUseNewSearchEntranceOnPad() {
                    isCache = searchOutService.currentIsCacheVC()
                }
                let filters = requestInfo.input.filters
                let advancedFilters = requestInfo.input.advancedSyntaxFilters
                var selectedRecFilter: String?
                if !advancedFilters.isEmpty {
                    selectedRecFilter = advancedFilters.convertToSelectedAdvanceSyntaxFilterTrackingInfo()
                } else {
                    selectedRecFilter = filters.convertToSelectedRecommendFilterTrackingInfo()
                }
                SearchTrackUtil.trackSearchReqeustClick(searchLocation: self.config.searchLocation,
                                                        query: requestInfo.input.query,
                                                        sceneType: "main",
                                                        sessionId: requestInfo.capturedSession.session,
                                                        filterStatus: filters.withNoFilter ? .none : .some(filters.convertToFilterStatusParam()),
                                                        selectedRecFilter: selectedRecFilter,
                                                        imprID: requestInfo.capturedSession.imprID,
                                                        slashID: (self.config as? SearchOpenTabConfig)?.info.id,
                                                        isCache: isCache)
            })
            .disposed(by: disposeBag)

        searchResultViewModel.trackSearchResultClick
            .subscribe(onNext: { [weak self] info in
                guard let self = self else { return }
                let requestInfo = info.requestInfo
                var isCache: Bool?
                if let searchOutService = searchOutService, searchOutService.enableUseNewSearchEntranceOnPad() {
                    isCache = searchOutService.currentIsCacheVC()
                }
                let filters = requestInfo.input.filters
                let advancedFilters = requestInfo.input.advancedSyntaxFilters
                var selectedRecFilter: String?
                if !advancedFilters.isEmpty {
                    selectedRecFilter = advancedFilters.convertToSelectedAdvanceSyntaxFilterTrackingInfo()
                } else {
                    selectedRecFilter = filters.convertToSelectedRecommendFilterTrackingInfo()
                }
                SearchTrackUtil.trackSearchResultClick(viewModel: info.viewModel,
                                                       sessionId: requestInfo.capturedSession.session,
                                                       searchLocation: self.config.searchLocation,
                                                       isSmartSearch: info.isSmartSearch,
                                                       isSpotlight: info.isSpotlight,
                                                       isSpotlightOnly: info.isSpotlightOnly,
                                                       isSuggested: false,
                                                       query: requestInfo.input.query,
                                                       sceneType: "main",
                                                       filterStatus: filters.withNoFilter ? .none : .some(filters.convertToFilterStatusParam()),
                                                       selectedRecFilter: selectedRecFilter,
                                                       imprID: requestInfo.capturedSession.imprID,
                                                       at: info.indexPath,
                                                       in: info.tableView,
                                                       bid: info.viewModel.searchResult.bid,
                                                       entityType: info.viewModel.searchResult.entityType,
                                                       moreButton: self.searchResultViewModel.jumpMoreSum,
                                                       isCache: isCache)
            })
            .disposed(by: disposeBag)

        searchResultViewModel.shouldRenewSession
            .subscribe(onNext: { [weak self] shouldRenewSession in
                guard let self = self, shouldRenewSession else { return }
                self.rootViewModel.renewSession()
            })
            .disposed(by: disposeBag)

        searchResultViewModel.requestInfoChange
            .subscribe(onNext: { [weak self] requestInfo in
                guard let self = self else { return }
                self.rootViewModel.endSearchNotice(withRequestInfo: requestInfo)
            })
            .disposed(by: disposeBag)

        searchResultViewModel.searchStartTime
            .subscribe(onNext: { [weak self] startTime in
                self?.searchTimeTrackManager.startTime = startTime
            })
            .disposed(by: disposeBag)
    }

    private func searchFilterVMSubscribe() {
        searchFilterViewModel?.slotSpanApplied
            .subscribe(onNext: { [weak self] slotSpan in
                guard let self = self, let currentText = self.queryBehavior.value else { return }
                if slotSpan.startIndex >= 0 && slotSpan.endIndex <= currentText.count {
                    var changableTextArray = currentText.map { String($0) }
                    let startIndex = Int(slotSpan.startIndex)
                    let endIndex = Int(slotSpan.endIndex)
                    changableTextArray.removeSubrange(startIndex ..< endIndex)
                    let changableText = changableTextArray.joined().trimmingForSearch()
                    self.queryChange(text: changableText)
                    self.rootViewModel.changeSearchText(changableText)
                }
            })
            .disposed(by: disposeBag)

        searchFilterViewModel?.commonlyUsedfilterShow
            .subscribe(onNext: { [weak self] filters in
                let filterStatus = filters.convertToFilterStatusParamWithoutEmpty()
                SearchTrackUtil.trackSearchCommonlyUsedFilterShow(
                    sessionId: self?.searchRepo.searchSession.session ?? "",
                    searchLocation: self?.config.searchLocation ?? "",
                    filterStatus: filterStatus,
                    imprID: self?.searchResultViewModel.currentCapturedSession?.imprID ?? "")
            })
            .disposed(by: disposeBag)
        searchFilterViewModel?.commonlyUsedfilterClick
            .subscribe(onNext: { [weak self] filter in
                SearchTrackUtil.trackSearchCommonlyUsedFilterClick(
                    sessionId: self?.searchRepo.searchSession.session ?? "",
                    searchLocation: self?.config.searchLocation ?? "",
                    filterStatus: filter.trackingRepresentation,
                    imprID: self?.searchResultViewModel.currentCapturedSession?.imprID ?? "")
            })
            .disposed(by: disposeBag)
    }

    private func search(withTab tab: SearchTab, input: SearcherInput) {
        if SearchFeatureGatingKey.enableAdvancedSyntax.isUserEnabled(userResolver: userResolver),
           let mainRootViewModel = rootViewModel as? SearchMainRootViewModel {
            var realInput = input
            realInput.advancedSyntaxFilters = mainRootViewModel.capsuleViewModel.capsulePage.selectedTrackAdvancedSyntaxFilters
            self.searchResultViewModel.search(withInput: realInput)
            self.rootViewModel.inputChangeSearchNotice(withTab: tab, input: realInput)
        } else {
            self.searchResultViewModel.search(withInput: input)
            self.rootViewModel.inputChangeSearchNotice(withTab: tab, input: input)
        }
    }

    // MARK: - 综合过滤器变化回调
    private func makeRouteFilterWithCommonFilter(_ filters: [SearchFilter]) -> [SearchFilter] {
        var newFilters = searchFilterViewModel?.filters ?? []
        for filter in filters {
            newFilters = mergeFilters(newFilters, withFilter: filter)
            switch filter {
            case let .commonFilter(.mainFrom(fromIds, _, fromType, isRecommendResultSelected)):
                newFilters = mergeFilters(newFilters, withFilter: .docFrom(fromIds: fromIds, recommends: [], fromType: fromType, isRecommendResultSelected: isRecommendResultSelected))
                newFilters = mergeFilters(newFilters, withFilter: .chatter(mode: .unlimited, picker: fromIds, recommends: [], fromType: fromType, isRecommendResultSelected: isRecommendResultSelected))
                if config is SearchOpenTabConfig {
                    for filter in config.supportedFilters {
                        if case let .general(generalFilter) = filter, generalFilter.canReplaceByCommonUserFilter {
                            newFilters = mergeFilters(newFilters, withFilter: .general(.user(generalFilter.info, fromIds)))
                        }
                    }
                }
            case let .commonFilter(.mainWith(withIds)):
                newFilters = mergeFilters(newFilters, withFilter: .withUsers(withIds))
                newFilters = mergeFilters(newFilters, withFilter: .chatMemeber(mode: .unlimited, picker: withIds))
            case let .commonFilter(.mainIn(inIds)):
                newFilters = mergeFilters(newFilters, withFilter: .docPostIn(inIds))
                newFilters = mergeFilters(newFilters, withFilter: .chat(mode: .unlimited, picker: inIds))
            case let .commonFilter(.mainDate(date)):
                if config is SearchMainMessageTabConfig {
                    newFilters = mergeFilters(newFilters, withFilter: .date(date: date, source: .message))
                } else if config is SearchMainDocTabConfig {
                    newFilters = mergeFilters(newFilters, withFilter: .date(date: date, source: .doc))
                } else if config is SearchOpenTabConfig {
                    for filter in config.supportedFilters {
                        if case let .general(generalFilter) = filter, generalFilter.canReplaceByCommonDate {
                            newFilters = mergeFilters(newFilters, withFilter: .general(.date(generalFilter.info, date)))
                        }
                    }
                }
            default: break
            }
        }
        return newFilters
    }

    private func mergeFilters(_ filters: [SearchFilter], withFilter filter: SearchFilter) -> [SearchFilter] {
        let originFilters = filters
        return filters.map { (originFilter) -> SearchFilter in
            if filter.sameType(with: originFilter) {
                return filter
            } else {
                return originFilter
            }
        }
    }

    private var lastMessageType: MessageFilterType = .all
    private func updateCurrentMessageSubConfig(by messageType: MessageFilterType) {
        guard config is SearchMainMessageTabConfig else { return }
        guard messageType != lastMessageType else { return }
        switch messageType {
        case .all:
            searchRepo.searchSource = searchRepo.sourceMaker.makeSearchSource(for: .rustScene(.searchMessages), userResolver: userResolver)
            config.scene = .rustScene(.searchMessages)
        case .link:
            searchRepo.searchSource = searchRepo.sourceMaker.makeSearchSource(for: .rustScene(.searchLinkScene), userResolver: userResolver)
            config.scene = .rustScene(.searchLinkScene)
        case .file:
            searchRepo.searchSource = searchRepo.sourceMaker.makeSearchSource(for: .rustScene(.searchFileScene), userResolver: userResolver)
            config.scene = .rustScene(.searchFileScene)
        @unknown default:
            searchRepo.searchSource = searchRepo.sourceMaker.makeSearchSource(for: .rustScene(.searchMessages), userResolver: userResolver)
            config.scene = .rustScene(.searchMessages)
        }
        lastMessageType = messageType
    }

    // MARK: - 搜索历史
    private func saveQueryHistory(searchHistoryModel: SearchHistoryModel?, scene: SearchSceneSection, offset: Int) {
        var info = ServerPB_Usearch_QueryHistoryInfo()
        info.query = searchResultViewModel.lastInput?.query ?? ""
        info.searchAction.tab = config.historyType

        if SearchFeatureGatingKey.searchHistoryOptimize.isEnabled {
            var selectedFilters: [SearchFilter] = []
            if isIntentionCapsuleStyle {
                selectedFilters = filtersBehavior.value.filter({ filter in
                    !filter.isEmpty
                })
            } else if let viewModel = searchFilterViewModel {
                selectedFilters = viewModel.filters.filter({ filter in
                    !filter.isEmpty
                })
            }
            let actionFilters = selectedFilters
                .map({ (filter) -> ServerPB_Usearch_SearchActionFilter in
                    return filter.convertToServerPBSearchActionFilter()
                })
            info.searchAction.filters = actionFilters

            let entities = selectedFilters
                .map { (filter) -> ServerPB_Usearch_SearchEntity  in
                    return filter.convertToSearchEntity()
                }
            info.entities = entities
        }

        var applink = ""
        if let openInfo = (config as? SearchOpenTabConfig)?.info {
            applink = "https://applink.larksuite.com/client/search/open?query=" + info.query +
                          "&target=" + getApplinkTarget() +
                          "&title=" + openInfo.label +
                          "&commandId=" + openInfo.id
        } else {
            applink = "https://applink.larksuite.com/client/search/open?query=" + info.query +
                          "&target=" + getApplinkTarget()
        }
        info.appLink = applink

        info.digest = ""
        info.action = ServerPB_Section_Action()

        historyStore.save(info: info, userResolver: userResolver)
        if !SearchFeatureGatingKey.rustSDKSearchFeedbackV2.isUserEnabled(userResolver: userResolver), let searchHistoryModel = searchHistoryModel {
            historyStore.saveSearch(searchText: searchResultViewModel.lastInput?.query ?? "",
                                    offset: Int32(offset),
                                    searchModel: searchHistoryModel,
                                    scene: scene.remoteRustScene,
                                    session: searchRepo.searchSession.session,
                                    imprID: searchResultViewModel.currentCapturedSession?.imprID)
        }
    }

    func getApplinkTarget() -> String {
        switch config.historyType {
        case .smartSearchTab: return "QUICK_JUMP"
        case .messageTab: return "MESSAGE"
        case .docsTab: return "DOC"
        case .appTab: return "APP"
        case .chatterTab: return "CONTACTS"
        case .chatTab: return "CHAT"
        case .calendarTab: return "CALENDAR"
        case .openSearchTab: return "SLASH_COMMAND"
        case .helpdeskTab: return "ONCALL"
        case .wikiTab, .panoTab, .unknownTab, .emailTab: return ""
        @unknown default:
            return ""
        }
    }

    // MARK: - Feedback
    func showFloatFeedBackView() {
        searchResultViewModel.showFloatFeedBackView()
    }

    func feedbackStat(isSend: Bool, entrance: String) {
        searchResultViewModel.feedbackStat(isSend: isSend, entrance: entrance)
    }
}

extension SearchContentViewModel: UniversalRecommendDelegate, UniversalRecommendTrackingDelegate {
    func clearHistory(callback: @escaping (Bool) -> Void) {
        rootViewModel.clearHistory(callback: callback)
    }

    // MARK: - 通用推荐
    func getCaptureId() -> SearchSession.Captured? {
        return searchResultViewModel.currentCapturedSession
    }

    func didSelect(history: UniversalRecommendSearchHistory) {
        if SearchFeatureGatingKey.searchHistoryOptimize.isEnabled {
            showV2History(history: history)
        } else {
            showV1History(history: history)
        }
    }

    func showV1History(history: UniversalRecommendSearchHistory) {
        guard let chatAPI = try? userResolver.resolve(assert: ChatAPI.self),
              let chatterAPI = try? userResolver.resolve(assert: ChatterAPI.self) else {
            return
        }
        switch history.searchAction.tab {
        case .smartSearchTab:
            let input = SearcherInput(query: history.query)
            let routeParam = SearchRouteParam(type: .main, input: input)
            goToHistory(withParam: routeParam)
        case .chatterTab:
            let input = SearcherInput(query: history.query)
            let routeParam = SearchRouteParam(type: .chatter, input: input)
            goToHistory(withParam: routeParam)
        case .chatTab:
            let input = SearcherInput(query: history.query)
            let routeParam = SearchRouteParam(type: .chat, input: input)
            goToHistory(withParam: routeParam)
        case .messageTab:
            let input = SearcherInput(query: history.query)
            let routeParam = SearchRouteParam(type: .message, input: input)
            goToHistory(withParam: routeParam)
        case .docsTab:
            let input = SearcherInput(query: history.query)
            let routeParam = SearchRouteParam(type: .doc, input: input)
            goToHistory(withParam: routeParam)
        case .wikiTab:
            let input = SearcherInput(query: history.query)
            let routeParam = SearchRouteParam(type: .wiki, input: input)
            goToHistory(withParam: routeParam)
        case .unknownTab:
            let input = SearcherInput(query: history.query)
            let routeParam = SearchRouteParam(type: .main, input: input)
            goToHistory(withParam: routeParam)
        case .calendarTab, .appTab, .emailTab, .panoTab, .helpdeskTab, .openSearchTab:
            fallthrough // use unknown default setting to fix warning
        @unknown default:
            assert(false, "new value")
            break
        }
    }

    func showV2History(history: UniversalRecommendSearchHistory) {
        guard let chatAPI = try? userResolver.resolve(assert: ChatAPI.self),
              let chatterAPI = try? userResolver.resolve(assert: ChatterAPI.self) else {
            return
        }
        switch history.searchAction.tab {
        case .smartSearchTab:
            convert(chatAPI: chatAPI, chatterAPI: chatterAPI, filterParam: history)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (filters) in
                    guard let self = self else { return }
                    let input = SearcherInput(query: history.query, filters: filters)
                    let routeParam = SearchRouteParam(type: .main, input: input)
                    self.goToHistory(withParam: routeParam)
                })
                .disposed(by: disposeBag)
        case .chatterTab:
            let input = SearcherInput(query: history.query)
            let routeParam = SearchRouteParam(type: .chatter, input: input)
            goToHistory(withParam: routeParam)
        case .chatTab:
            convert(chatAPI: chatAPI, chatterAPI: chatterAPI, filterParam: history)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (filters) in
                    guard let self = self else { return }
                    let input = SearcherInput(query: history.query, filters: filters)
                    let routeParam = SearchRouteParam(type: .chat, input: input)
                    self.goToHistory(withParam: routeParam)
                })
                .disposed(by: disposeBag)
        case .messageTab:
            convert(chatAPI: chatAPI, chatterAPI: chatterAPI, filterParam: history)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (filters) in
                    guard let self = self else { return }
                    let input = SearcherInput(query: history.query, filters: filters)
                    let routeParam = SearchRouteParam(type: .message, input: input)
                    self.goToHistory(withParam: routeParam)
                })
                .disposed(by: disposeBag)
        case .docsTab:
            convert(chatAPI: chatAPI, chatterAPI: chatterAPI, filterParam: history)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (filters) in
                    guard let self = self else { return }
                    let input = SearcherInput(query: history.query, filters: filters)
                    let routeParam = SearchRouteParam(type: .doc, input: input)
                    self.goToHistory(withParam: routeParam)
                })
                .disposed(by: disposeBag)
        case .wikiTab:
            let input = SearcherInput(query: history.query)
            let routeParam = SearchRouteParam(type: .wiki, input: input)
            goToHistory(withParam: routeParam)
        case .appTab:
            let input = SearcherInput(query: history.query)
            let routeParam = SearchRouteParam(type: .app, input: input)
            goToHistory(withParam: routeParam)
        case .calendarTab:
            let input = SearcherInput(query: history.query)
            let routeParam = SearchRouteParam(type: .calendar, input: input)
            goToHistory(withParam: routeParam)
        case .emailTab:
            let input = SearcherInput(query: history.query)
            let routeParam = SearchRouteParam(type: .email, input: input)
            goToHistory(withParam: routeParam)
        case .helpdeskTab:
            let input = SearcherInput(query: history.query)
            let routeParam = SearchRouteParam(type: .oncall, input: input)
            goToHistory(withParam: routeParam)
        case .openSearchTab:
            guard let appLinkEncoded = history.appLink.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: appLinkEncoded) else { return }
            let appId = url.queryParameters.first(where: { $0.key == "commandId" })?.value ?? ""
            var title = url.queryParameters.first(where: { $0.key == "title" })?.value ?? "Open Search" + appId
            if title.isEmpty {
                title = "Open Search" + appId
            }
            let input = SearcherInput(query: history.query)
            let routeParam = SearchRouteParam(type: .open(SearchTab.OpenSearch(id: appId,
                                                                               label: title,
                                                                               icon: nil,
                                                                               resultType: .slashCommand,
                                                                               filters: [])),
                                              input: input)
            goToHistory(withParam: routeParam)
        case .unknownTab:
            let input = SearcherInput(query: history.query)
            let routeParam = SearchRouteParam(type: .main, input: input)
            goToHistory(withParam: routeParam)
        case .panoTab: // use unknown default setting to fix warning
            assert(false, "new value")
            break
        @unknown default:
            assert(false, "new value")
            break
        }
    }

    func didSelect(hotword: UniversalRecommendHotword) {
        guard !hotword.title.isEmpty else { return }
        queryChange(text: hotword.title)
    }

    private func convert(chatAPI: ChatAPI, chatterAPI: ChatterAPI, filterParam: UniversalRecommendSearchHistory) -> Observable<[SearchFilter]> {
        let inChatFilterIds = filterParam.searchAction.filters.flatMap { (filter) -> [String] in
            return filter.docsInChat.groupChatIds +
                    filter.docsInChat.p2PChatterIds +
                    filter.messageInChat.groupChatIds +
                    filter.messageInChat.p2PChatterIds +
                    filter.smartSearchInChat.groupChatIds +
                    filter.smartSearchInChat.p2PChatterIds
        }
        let fromUserFilterIds = filterParam.searchAction.filters.flatMap { (filter) -> [String] in
            return filter.docsFromUser.userIds +
                    filter.messageFromUser.userIds +
                    filter.smartSearchFromUser.userIds +
                    filter.smartSearchWithUser.userIds +
                    filter.docsOwner.userIds +
                    filter.docsSharer.userIds +
                    filter.groupChatIncludeUser.userIds +
                    filter.messageWithUser.userIds
        }
        let ob1 = chatAPI.fetchChats(by: inChatFilterIds, forceRemote: false)
        let ob2 = chatterAPI.getChatters(ids: fromUserFilterIds)
        return Observable.zip(ob1, ob2)
            .map({ (chatMap, chatterMap) -> ([SearchFilter]) in
                var searchFilters: [SearchFilter] = []
                let datas = filterParam.getDigestData()
                searchFilters = datas.map({ [weak self] (data) -> SearchFilter? in
                    guard let self = self else { return nil }
                    return data.convertToFilter(userResovler: self.userResolver, chatMap: chatMap, chatterMap: chatterMap)
                }).compactMap({ $0 })
                return searchFilters
            })
    }

    private func goToHistory(withParam routeParam: SearchRouteParam) {
        if !SearchFeatureGatingKey.searchLeanModeIsOnBugfix.isUserEnabled(userResolver: userResolver) {
            guard rootViewModel.tabService?.getCompleteSearchTab(type: routeParam.type) != nil else {
                Self.logger.error("[LarkSearch] goToHistory error " + routeParam.type.shortDescription)
                return
            }
        }
        rootViewModel.changeSearchText(routeParam.input.query)
        rootViewModel.route(withParam: routeParam)
    }
}
