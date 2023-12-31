//
//  SearchMainRootViewModel.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/7/11.
//

import Foundation
import RxSwift
import RxCocoa
import UniverseDesignTabs
import LKCommonsLogging
import Lynx
import LarkContainer
import LarkMessengerInterface
import LarkSearchCore
import LarkSearchFilter
import ServerPB

// 赞不支持 leanModeIsOn 模式
final class SearchMainRootViewModel: SearchRootViewModelProtocol {
    typealias SearchAction = ServerPB_Usearch_SearchAction
    static let logger = Logger.log(SearchMainRootViewModel.self, category: "SearchMainRootViewModel")
    var tabService: SearchMainTabService?
    let searchSession: SearchSession
    let historyStore: SearchQueryHistoryStore
    var advancedSyntaxViewModel: SearchAdvancedSyntaxViewModel?
    let sourceOfSearch: SourceOfSearch
    public lazy var capsuleViewModel: SearchIntentionCapsuleViewModel = {
        let capsuleViewModel = SearchIntentionCapsuleViewModel(userResolver: userResolver,
                                                               capsulePage: self.createCapsulePage(withTab: self.currentTab))
        return capsuleViewModel
    }()
    var jumpTab: SearchTab?
    var currentTab: SearchTab
    var applinkSource: String = ""
    private(set) var tabTypes: [SearchTab] {
        didSet {
            Self.logger.info("SearchMainRootViewModel set tabTypes: \(self.tabTypes.map { $0.shortDescription }.joined(separator: ", "))")
        }
    }
    private var currentRequestInfo: SearcherState.RequestInfo?
    let userResolver: UserResolver
    private let disposeBag = DisposeBag()

    private let shouldUpdateTabsSubject = PublishSubject<[SearchTab]>()
    var shouldUpdateTabs: Driver<[SearchTab]> {
        return shouldUpdateTabsSubject.asDriver(onErrorJustReturn: tabTypes)
    }

    private let shouldUpdateAvailableTabsSubject = PublishSubject<[SearchTab]>()
    var shouldUpdateAvailableTabs: Driver<[SearchTab]> {
        return shouldUpdateAvailableTabsSubject.asDriver(onErrorJustReturn: tabService?.currentAvailableTabs() ?? [])
    }

    private let shouldNoticeSearchEndSubject = PublishSubject<SearcherState.RequestInfo?>()
    var shouldNoticeSearchEnd: Driver<SearcherState.RequestInfo?> {
        return shouldNoticeSearchEndSubject.asDriver(onErrorJustReturn: nil)
    }

    private let shouldNoticeSearchStartSubject = PublishSubject<(SearchTab?, SearcherInput?)>()
    var shouldNoticeSearchStart: Driver<(SearchTab?, SearcherInput?)> {
        return shouldNoticeSearchStartSubject.asDriver(onErrorJustReturn: (nil, nil))
    }

    private let shouldShowClearHistorySubject = PublishSubject<((Bool) -> Void)?>()
    var shouldShowClearHistory: Driver<((Bool) -> Void)?> {
        return shouldShowClearHistorySubject.asDriver(onErrorJustReturn: nil)
    }

    private let shouldChangeQuerySubject = PublishSubject<String?>()
    var shouldChangeQuery: Driver<String?> {
        return shouldChangeQuerySubject.asDriver(onErrorJustReturn: nil)
    }

    private let shouldRouteSubject = PublishSubject<SearchRouteParam?>()
    var shouldRoute: Driver<SearchRouteParam?> {
        return shouldRouteSubject.asDriver(onErrorJustReturn: nil)
    }

    init(userResolver: UserResolver,
         searchSession: SearchSession,
         historyStore: SearchQueryHistoryStore,
         sourceOfSearch: SourceOfSearch,
         applinkSource: String = "",
         jumpTab: SearchTab?) {
        self.userResolver = userResolver
        self.searchSession = searchSession
        self.historyStore = historyStore
        self.sourceOfSearch = sourceOfSearch
        self.applinkSource = applinkSource
        let tabService = try? userResolver.resolve(assert: SearchMainTabService.self)
        self.tabService = tabService
        self.tabTypes = tabService?.currentTabs() ?? []
        self.currentTab = .main
        if SearchFeatureGatingKey.enableAdvancedSyntax.isUserEnabled(userResolver: userResolver) {
            self.advancedSyntaxViewModel = SearchAdvancedSyntaxViewModel(userResolver: userResolver)
        }
        if let _jumpTab = jumpTab, let completeJumpTab = tabService?.getCompleteSearchTab(type: _jumpTab) {
            self.jumpTab = completeJumpTab
            if !self.tabTypes.contains(completeJumpTab) {
                addTempTab(completeJumpTab)
            }
        }
        setupSubscribe()
        tabService?.pullTabs()
        tabService?.pullAvailableTabsAndSave()
        tabService?.getAllCalendars()
        // 更新DSL模版
        let templateManager = DSLTemplateManager()
        templateManager.updateDSLTemplate(userResolver: userResolver)
    }

    func addTempTab(_ tab: SearchTab) {
        tabTypes.append(tabService?.getCompleteSearchTab(type: tab) ?? tab)
    }

    private func setupSubscribe() {
        tabService?.tabs
            .compactMap({ $0 })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](_) in
                guard let self = self, let tabService = self.tabService else { return }
                self.tabTypes = tabService.currentTabs()
                if let jumpTab = self.jumpTab, !self.tabTypes.contains(jumpTab) {
                    self.addTempTab(jumpTab)
                }
                if !self.tabTypes.isEmpty {
                    self.shouldUpdateTabsSubject.onNext(self.tabTypes)
                }
            })
            .disposed(by: disposeBag)
        tabService?.availableTabs
            .compactMap({ $0 })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, let tabService = self.tabService else { return }
                if !tabService.currentAvailableTabs().isEmpty {
                    self.shouldUpdateAvailableTabsSubject.onNext(tabService.currentAvailableTabs())
                }
            })
            .disposed(by: disposeBag)
        tabService?.shouldClearJumpTabSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] shouldClean in
                guard let self = self else { return }
                if shouldClean {
                    self.jumpTab = nil
                }
            })
            .disposed(by: disposeBag)
    }

    func trackTabChange(tab: SearchTab, currentController: AnyObject?) {
        guard currentTab != tab else { return }
        var slashIds = [String]()
        if case let .open(info) = currentTab {
            slashIds.append(info.id)
        }
        if case let .open(info) = tab {
            slashIds.append(info.id)
        }
        var lastTabRequestInfo: SearcherState.RequestInfo?
        if let currentController = currentController as? SearchContentViewController {
            lastTabRequestInfo = currentController.viewModel.lastRequestInfo
        }
        var isCache: Bool?
        if let service = try? self.userResolver.resolve(assert: SearchOuterService.self), service.enableUseNewSearchEntranceOnPad() {
            isCache = service.currentIsCacheVC()
        }
        SearchTrackUtil.trackTabClick(searchLocation: currentTab.trackRepresentation,
                                      tabName: tab.trackRepresentation,
                                      sceneType: "main",
                                      requestInfo: lastTabRequestInfo,
                                      slashIds: slashIds,
                                      isCache: isCache)
        if SearchTrackUtil.enablePostTrack() {
            var categoryParams: [String: Any] = ["tab_name": tab.trackRepresentation]
            if case.open(let openSearch) = tab {
                categoryParams["search_app_id"] = openSearch.id
            }
            SearchTrackUtil.trackForStableWatcher(domain: "asl_general_search",
                                                  message: "asl_search_enter_tab",
                                                  metricParams: [:],
                                                  categoryParams: categoryParams)
        }
    }

    func createCapsulePage(withTab tab: SearchTab) -> SearchIntentionCapsulePage {
        let config = SearchTabConfigFactory.createConfig(resolver: self.userResolver, tab: tab, sourceOfSearch: sourceOfSearch)
        return SearchIntentionCapsulePage(userResolver: userResolver,
                                          searchTab: tab,
                                          tabConfig: config,
                                          lastInput: nil,
                                          userLikeTabs: tabTypes,
                                          availableTabs: tabService?.currentAvailableTabs() ?? [])
    }

    func appendTabFilters(searchTabConfig: SearchTabConfigurable?, inputFilters: [SearchFilter]) -> [SearchFilter] {
        guard let searchTabConfig = searchTabConfig else { return inputFilters }
        var resultFilters: [SearchFilter] = inputFilters
        switch searchTabConfig.tab {
        case .open:
            if searchTabConfig.tab.isOpenSearchCalendar,
               var allCalendars = tabService?.allCalendarItems,
               case .general(.calendar(let info, _)) = searchTabConfig.supportedFilters.first(where: { filter in
                   if case .general(.calendar(_, _)) = filter {
                       return true
                   }
                   return false
               }) {
                allCalendars = allCalendars.filter({ item in
                    item.isSelected
                })
                if let index = inputFilters.firstIndex(where: { filter in
                    return filter.sameType(with: .general(.calendar(info, [])))
                }), case .general(.calendar(_, let calendarItems)) = inputFilters[safe: index] {
                    allCalendars = allCalendars.filter({ item in
                        calendarItems.contains(item)
                    })
                    resultFilters[index] = .general(.calendar(info, allCalendars + calendarItems))
                } else {
                    resultFilters.append(.general(.calendar(info, allCalendars)))
                }
            }
        case .message:
            if SearchFeatureGatingKey.enableFilterEludeBot.isUserEnabled(userResolver: self.userResolver),
               let filters = searchTabFilters(searchTab: searchTabConfig.tab),
               case.messageMatch(let array) = filters.first,
               case.excludeBot = array.first {
                //如果带有筛选器，在其基础上拼接上记忆的。暂不考虑带的筛选项是单选的，且传入的筛选项和记忆的不一致的场景（后续通用能力可以选择只配置多选项）
                for filter in filters {
                    let index = resultFilters.firstIndex(where: {
                        $0.sameType(with: filter)})
                    if let index = index, index < resultFilters.count, index >= 0 {
                        //输入筛选项中有记忆的筛选项，需要过滤每个记忆的筛选项中有没有传入的筛选值，没得话拼接
                        if case.messageMatch(let inputArray) = resultFilters[index], case.messageMatch(let saveArray) = filter {
                            let inputSet = Set(inputArray)
                            let saveSet = Set(saveArray)
                            let appendArray = Array(inputSet.union(saveSet))
                            resultFilters[index] = .messageMatch(appendArray)
                        }
                    } else {
                        resultFilters.append(filter)
                    }
                }
            } else {
                break
            }
        default: break
        }
        return resultFilters
    }

    func searchTabFilters(searchTab: SearchTab) -> [SearchFilter]? {
        guard SearchFeatureGatingKey.enableFilterEludeBot.isUserEnabled(userResolver: self.userResolver) else { return nil }
        guard case.message = searchTab, let tabsFilters = tabService?.tabsFilters, !tabsFilters.isEmpty else { return nil }

        if tabsFilters.keys.contains(searchTab) {
            return tabsFilters[searchTab]
        }
        return nil
    }

    func buildSearchAction(selectedFilters: [SearchFilter]) -> SearchAction? {
        guard SearchFeatureGatingKey.enableFilterEludeBot.isUserEnabled(userResolver: self.userResolver) else { return nil }
        guard let searchTab = currentTab.cast() else { return nil }
        var searchAction = SearchAction()
        searchAction.tab = searchTab.type
        if searchTab.type == .openSearchTab {
            searchAction.appID = searchTab.appID
        }
        searchAction.filters = selectedFilters.compactMap({ filter in
            let filterAction = filter.convertToServerPBSearchActionFilter()
            return filterAction.typedFilter != nil ? filterAction : nil
        })
        return searchAction
    }

    func updateTabFilters(searchTab: SearchTab, filter: SearchFilter, isAdd: Bool, selectedFilters: [SearchFilter]) {
        guard SearchFeatureGatingKey.enableFilterEludeBot.isUserEnabled(userResolver: self.userResolver) else { return }
        guard case.message = searchTab, case.messageMatch(let messageMatchTypeArray) = filter else { return }
        guard let tabService = tabService else { return }
        var searchAction: SearchAction?

        if let filters = tabService.tabsFilters[searchTab], let index = filters.firstIndex(where: {
            $0.sameType(with: filter)}), index < filters.count, index >= 0 {
            var updateFilters = filters
            if !isAdd {
                updateFilters.remove(at: index) //移除filter
                searchAction = buildSearchAction(selectedFilters: selectedFilters)
            } else {
                let savedFilter = updateFilters[index]
                if case.messageMatch(let savedMessageMatchTypeArray) = savedFilter, savedMessageMatchTypeArray.contains(.excludeBot), !messageMatchTypeArray.contains(.excludeBot) {
                    //保存的筛选器的筛选项有「不看机器人」，但是更新的filter中同一个筛选器的筛选项 没有「不看机器人」，需要移除
                    updateFilters.remove(at: index) //移除filter
                    searchAction = buildSearchAction(selectedFilters: selectedFilters)
                }
            }
            tabService.updateTabsFilter(searchTab: searchTab, filters: updateFilters)
        } else if isAdd {
            guard messageMatchTypeArray.contains(.excludeBot) else { return }
            var realFilter = filter
            if messageMatchTypeArray.count > 1 {
                //只保存「不看机器人」
                realFilter = .messageMatch([.excludeBot])
            }
            if let filters = tabService.tabsFilters[searchTab] {
                //当前tab记忆的数据中已经带了别的筛选器，但是没带选中的筛选器「不看机器人」，做拼接
                var updateFilters = filters
                updateFilters.append(realFilter)
                tabService.updateTabsFilter(searchTab: searchTab, filters: updateFilters)
            } else {
                tabService.updateTabsFilter(searchTab: searchTab, filters: [realFilter])
            }
            searchAction = buildSearchAction(selectedFilters: selectedFilters)
        }
        if let searchAction = searchAction {
            tabService.putFilterDataRequest(searchAction: searchAction)
        }
    }

    func resetTabFilters() {
        guard SearchFeatureGatingKey.enableFilterEludeBot.isUserEnabled(userResolver: self.userResolver) else { return }
        guard case.message = self.currentTab, let tabService = tabService else { return }
        tabService.updateTabsFilter(searchTab: self.currentTab, filters: [])
        if let searchAction = buildSearchAction(selectedFilters: []) {
            tabService.putFilterDataRequest(searchAction: searchAction)
        }
    }

    // MARK: - 生命周期
    func viewDidLoad() {
        if let service = try? self.userResolver.resolve(assert: SearchOuterService.self), service.enableUseNewSearchEntranceOnPad() {
            let entryAction = service.currentEntryAction()
            SearchTrackUtil.trackSearchView(session: searchSession,
                                            searchLocation: jumpTab?.trackRepresentation ?? "quick_search",
                                            sceneType: "main",
                                            applinkSource: self.applinkSource,
                                            entryAction: entryAction?.rawValue,
                                            isCache: false)
            return
        }
        SearchTrackUtil.trackSearchView(session: searchSession, searchLocation: jumpTab?.trackRepresentation ?? "quick_search", sceneType: "main", applinkSource: self.applinkSource)
    }

    func changeSearchText(_ text: String) {
        shouldChangeQuerySubject.onNext(text)
    }

    func route(withParam param: SearchRouteParam?) {
        shouldRouteSubject.onNext(param)
    }

    func clearHistory(callback: @escaping (Bool) -> Void) {
        shouldShowClearHistorySubject.onNext(callback)
    }

    func renewSession() {
        searchSession.renewSession()
    }

    func endSearchNotice(withRequestInfo requestInfo: SearcherState.RequestInfo) {
        currentRequestInfo = requestInfo
        shouldNoticeSearchEndSubject.onNext(requestInfo)
    }

    func inputChangeSearchNotice(withTab tab: SearchTab, input: SearcherInput) {
        shouldNoticeSearchStartSubject.onNext((tab, input))
    }
}
