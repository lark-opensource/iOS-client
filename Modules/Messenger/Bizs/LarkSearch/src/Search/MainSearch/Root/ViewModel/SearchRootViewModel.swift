//
//  SearchRootViewModel.swift
//  LarkSearch
//
//  Created by Patrick on 2022/5/20.
//

import Foundation
import LarkSearchCore
import UniverseDesignTabs
import RxSwift
import RxCocoa
import Lynx
import LKCommonsLogging
import LarkContainer
import SuiteAppConfig
import LarkSearchFilter
import LarkMessengerInterface

struct SearchRouteParam {
    let type: SearchTab
    let input: SearcherInput
}

final class SearchRootViewModel: SearchRootViewModelProtocol {
    static let logger = Logger.log(SearchRootViewModel.self, category: "SearchRootViewModel")
    var tabService: SearchMainTabService?
    let searchSession: SearchSession
    let historyStore: SearchQueryHistoryStore
    var commonlyUsedFilterStore: SearchCommonlyUsedFilterStore?
    var jumpTab: SearchTab?
    var applinkSource: String = ""
    private(set) var tabTypes: [SearchTab] {
        didSet {
            Self.logger.info("SearchRootViewModel set tabTypes: \(self.tabTypes.map { $0.shortDescription }.joined(separator: ", "))")
        }
    }
    private(set) var lastIndex: Int?
    private(set) var lastSelectTabBeforeTabChange: SearchTab?
    private var currentRequestInfo: SearcherState.RequestInfo?
    private let disposeBag = DisposeBag()

    private lazy var shouldReloadTabsViewSubject = PublishSubject<Bool>()
    var shouldReloadTabsView: Driver<Bool> {
        return shouldReloadTabsViewSubject.asDriver(onErrorJustReturn: false)
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

    let userResolver: UserResolver
    init(userResolver: UserResolver,
         searchSession: SearchSession,
         historyStore: SearchQueryHistoryStore,
         applinkSource: String = "",
         jumpTab: SearchTab?) {
        self.userResolver = userResolver
        self.searchSession = searchSession
        self.applinkSource = applinkSource
        if AppConfigManager.shared.leanModeIsOn {
            self.tabService = nil
            self.tabTypes = [.main, .chatter, .chat]
        } else {
            self.tabService = try? userResolver.resolve(assert: SearchMainTabService.self)
            self.tabTypes = tabService?.currentTabs() ?? []
            self.commonlyUsedFilterStore = SearchCommonlyUsedFilterStore(userResolver: userResolver, commonlyUsedFiltersDataList: tabService?.commonlyUsedFilters ?? [])
        }
        self.jumpTab = jumpTab
        self.historyStore = historyStore
        setupSubscribe()
        if let tabService = tabService {
            tabService.pullTabs()
            tabService.pullAvailableTabsAndSave()
            tabService.pullCommonlyUsedFilters()
            tabService.getAllCalendars()
        }
        if let jumpTab = jumpTab, !self.tabTypes.contains(jumpTab) {
            addTempTab(jumpTab)
        }
        // 更新DSL模版
        let templateManager = DSLTemplateManager()
        templateManager.updateDSLTemplate(userResolver: userResolver)
        // 开启 Gecko
        // 暂时关闭动态 下发，使用本地兜底文件
        // let manager = ASTemplateManager()
        // manager.initGecko()
    }

    func addTempTab(_ tab: SearchTab) {
        tabTypes.append(tabService?.getCompleteSearchTab(type: tab) ?? tab)
    }

    // MARK: - Tracking
    func didSelectedItem(at index: Int, currentController: AnyObject?) {
        defer {
            lastIndex = index
        }
        if let last = lastIndex, last < tabTypes.count, index < tabTypes.count, index != last {
            var slashIds = [String]()
            if case let .open(info) = tabTypes[last] {
                slashIds.append(info.id)
            }
            if case let .open(info) = tabTypes[index] {
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
            SearchTrackUtil.trackTabClick(searchLocation: tabTypes[last].trackRepresentation,
                                          tabName: tabTypes[index].trackRepresentation,
                                          sceneType: "main",
                                          requestInfo: lastTabRequestInfo,
                                          slashIds: slashIds,
                                          isCache: isCache)
            if SearchTrackUtil.enablePostTrack() {
                var categoryParams: [String: Any] = ["tab_name": tabTypes[index].trackRepresentation]
                if case.open(let info) = tabTypes[index] {
                    categoryParams["search_app_id"] = info.id
                }
                SearchTrackUtil.trackForStableWatcher(domain: "asl_general_search",
                                                      message: "asl_search_enter_tab",
                                                      metricParams: [:],
                                                      categoryParams: categoryParams)
            }
        }
    }

    private func setupSubscribe() {
        if !AppConfigManager.shared.leanModeIsOn {
            tabService?.tabs
                .compactMap({ $0 })
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self](_) in
                    guard let self = self, let tabService = self.tabService else { return }
                    if let lastSelect = self.lastIndex {
                        self.lastSelectTabBeforeTabChange = self.tabTypes[safe: lastSelect]
                    }
                    self.tabTypes = tabService.currentTabs()
                    if let jumpTab = self.jumpTab, !self.tabTypes.contains(jumpTab) {
                        self.addTempTab(jumpTab)
                    }
                    self.shouldReloadTabsViewSubject.onNext(true)
                })
                .disposed(by: disposeBag)
            if SearchFeatureGatingKey.enableCommonlyUsedFilter.isEnabled {
                tabService?.commonlyUsedFiltersData.observeOn(MainScheduler.instance)
                    .subscribe(onNext: {[weak self] (dataLists: [CommonlyUsedFilterDataList]?) in
                        guard let self = self else { return }
                        self.commonlyUsedFilterStore?.update(dataLists ?? [])
                    })
                    .disposed(by: disposeBag)
            }
            tabService?.shouldClearJumpTabSubject.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] shouldClean in
                guard let self = self else { return }
                if shouldClean {
                    self.jumpTab = nil
                }
            })
            .disposed(by: disposeBag)
        }
    }

    func appendTabFilters(searchTab: SearchTab, inputFilters: [SearchFilter]) -> [SearchFilter] {
        var resultFilters: [SearchFilter] = inputFilters
            switch searchTab {
            case .open(let openSearch):
                if searchTab.isOpenSearchCalendar,
                   var allCalendars = tabService?.allCalendarItems,
                   case .general(.calendar(let info, _)) = openSearch.filters.first(where: { filter in
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
            default: break
            }
        return resultFilters
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
    }

    func inputChangeSearchNotice(withTab tab: SearchTab, input: SearcherInput) { }
}

protocol SearchRootViewModelProtocol {
    var tabService: SearchMainTabService? { get }
    func changeSearchText(_ text: String)
    func route(withParam param: SearchRouteParam?)
    func clearHistory(callback: @escaping (Bool) -> Void)
    func renewSession()
    func endSearchNotice(withRequestInfo requestInfo: SearcherState.RequestInfo)
    func inputChangeSearchNotice(withTab tab: SearchTab, input: SearcherInput)
}

extension SearchRootViewModelProtocol {
    var commonlyUsedFilterStore: SearchCommonlyUsedFilterStore? { nil }
}
