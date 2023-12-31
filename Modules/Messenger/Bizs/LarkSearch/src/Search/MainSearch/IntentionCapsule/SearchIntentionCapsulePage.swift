//
//  SearchIntentionCapsulePage.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/6/30.
//

import Foundation
import LarkSearchCore
import LarkSearchFilter
import ServerPB
import LarkContainer
import RxSwift
import RxCocoa

public final class SearchIntentionCapsuleModel: Equatable {
    enum CapsuleType {
        case tab(tab: SearchTab, recommendInfo: ServerPB_Usearch_CapsuleInfo? = nil)
        case filter(filter: SearchFilter, recommendInfo: ServerPB_Usearch_CapsuleInfo? = nil)
        case advancedSearch(selectedCount: Int) //高级搜索 跳转未展示的筛选器页面
    }
    var type: CapsuleType
    var isSelected: Bool
    init(type: CapsuleType, isSelected: Bool) {
        self.type = type
        self.isSelected = isSelected
    }
    public static func == (lhs: SearchIntentionCapsuleModel, rhs: SearchIntentionCapsuleModel) -> Bool {
        guard lhs.isSelected == rhs.isSelected else { return false }
        switch(lhs.type, rhs.type) {
        case(let .tab(lhsTab, lhsRecommend), let .tab(rhsTab, rhsRecommend)):
            return lhsTab == rhsTab && lhsRecommend == rhsRecommend
        case(let .filter(lhsFilter, lhsRecommend), let .filter(rhsFilter, rhsRecommend)):
            return lhsFilter == rhsFilter && lhsRecommend == rhsRecommend
        case(let .advancedSearch(lhsCount), let .advancedSearch(rhsCount)):
            return lhsCount == rhsCount
        default:
            break
        }
        return false
    }
}

public final class SearchIntentionCapsulePage: UserResolverWrapper {
    public let userResolver: UserResolver
    let searchTab: SearchTab // 当前tab
    let tabConfig: SearchTabConfigurable?
    // 当前选中的筛选器
    private(set) var selectedFilters: [SearchFilter] = [] {
        didSet {
            advancedSyntaxDeduplicate()
        }
    }
    // 当前通过高级语法选中的筛选器，只做埋点用
    var selectedTrackAdvancedSyntaxFilters: [SearchFilter] = []
    // 推荐胶囊, 区分推荐失败(nil)和推荐为空(empty)
    // 推荐失败使用默认筛选器进行补充，推荐为空不补充
    private(set) var recommendCapsuleInfos: [ServerPB_Usearch_CapsuleInfo]?
    // 综搜展示的tab
    var userLikeTabs: [SearchTab]
    // 支持的所有tab，有可能推出当前不支持的tab
    var availableTabs: [SearchTab]
    var lastInput: SearcherInput? //上次搜索对应的信息，query + filter
    @ScopedInjectedLazy var mainTabService: SearchMainTabService?

    private let filterChangeSubject = PublishSubject<(Bool, SearchFilter?)>()
    var filterChange: Driver<(Bool, SearchFilter?)> {
        return filterChangeSubject.asDriver(onErrorJustReturn: (false, nil))
    }

    init(userResolver: UserResolver,
         searchTab: SearchTab,
         tabConfig: SearchTabConfigurable?,
         lastInput: SearcherInput?,
         userLikeTabs: [SearchTab],
         availableTabs: [SearchTab]) {
        self.userResolver = userResolver
        self.searchTab = searchTab
        self.tabConfig = tabConfig
        self.lastInput = lastInput
        self.userLikeTabs = userLikeTabs
        self.availableTabs = availableTabs
    }

    // 筛选项在选中时需要转化为对应筛选器
    func updateSingleFilter(filter: SearchFilter) {
        if let _filter = transformFilters(filters: [filter]).first {
            if _filter.isEmpty {
                selectedFilters.removeAll { selectedFilter in
                    selectedFilter.sameType(with: _filter)
                }
                filterChangeSubject.onNext((false, _filter))
            } else {
                if let index = selectedFilters.firstIndex(where: { selectedFilter in
                    selectedFilter.sameType(with: _filter)
                }) {
                    if case .specificFilterValue(let realFilter, _, _) = _filter {
                        selectedFilters[index] = realFilter
                        filterChangeSubject.onNext((true, realFilter))
                    } else {
                        selectedFilters[index] = _filter
                        filterChangeSubject.onNext((true, _filter))
                    }
                } else {
                    if case .specificFilterValue(let realFilter, _, _) = _filter {
                        selectedFilters.append(realFilter)
                        filterChangeSubject.onNext((true, realFilter))
                    } else {
                        selectedFilters.append(_filter)
                        filterChangeSubject.onNext((true, _filter))
                    }
                }
            }
        }
    }

    func updateRecommendCapsuleInfos(capsuleInfoPB: [ServerPB_Usearch_CapsuleInfo]?) {
        guard let _capsuleInfoPB = capsuleInfoPB else {
            recommendCapsuleInfos = nil
            return
        }
        //去重
        recommendCapsuleInfos = _capsuleInfoPB.enumerated().filter { (index, info) -> Bool in
            return _capsuleInfoPB.firstIndex(of: info) == index
        }.map {
            $0.element
        }
    }

    func coverSelectedFilters(filters: [SearchFilter]) {
        selectedFilters = transformFilters(filters: filters).filter({ _filter in
            !_filter.isEmpty
        })
    }

    func resetAllFilters() {
        selectedFilters = []
        selectedTrackAdvancedSyntaxFilters = []
    }

    func selectedCapsuleModels() -> [SearchIntentionCapsuleModel] {
        var resultModels: [SearchIntentionCapsuleModel] = []
        if searchTab != .main {
            resultModels.append(SearchIntentionCapsuleModel(type: .tab(tab: searchTab), isSelected: true))
        }
        for selectedFilter in selectedFilters {
            resultModels.append(SearchIntentionCapsuleModel(type: .filter(filter: selectedFilter), isSelected: true))
        }
        return resultModels
    }

    func defaultUnSelectedCapsuleModels() -> [SearchIntentionCapsuleModel] {
        var resultModels: [SearchIntentionCapsuleModel] = []
        if searchTab == .main {
            for tab in userLikeTabs {
                if tab != .main {
                    resultModels.append(SearchIntentionCapsuleModel(type: .tab(tab: tab), isSelected: false))
                }
            }
            if let tabConfig = tabConfig {
                for filter in tabConfig.supportedFilters {
                    if !selectedFilters.contains(where: { selectedFilter in
                        selectedFilter.sameType(with: filter)
                    }) {
                        resultModels.append(SearchIntentionCapsuleModel(type: .filter(filter: filter), isSelected: false))
                    }
                }
            }
        } else {
            if let tabConfig = tabConfig {
                for filter in tabConfig.supportedFilters {
                    if !selectedFilters.contains(where: { selectedFilter in
                        selectedFilter.sameType(with: filter)
                    }) {
                        resultModels.append(SearchIntentionCapsuleModel(type: .filter(filter: filter), isSelected: false))
                    }
                }
            }
        }
        return resultModels
    }

    func recommendUnselectedCapsuleModels() -> [SearchIntentionCapsuleModel] {
        guard let _recommendCapsuleInfos = recommendCapsuleInfos else { return [] }
        var resultModels: [SearchIntentionCapsuleModel] = []
        for info in _recommendCapsuleInfos {
            switch info.capsuleType {
            case .tab:
                if let type = searchTab.cast()?.type {
                    var resultTab = ServerPB_Usearch_SearchTab()
                    resultTab.type = info.searchAction.tab
                    resultTab.appID = info.searchAction.appID
                    if let _resultTab = SearchTab(resultTab), let recommendTab = mainTabService?.getCompleteSearchTab(type: _resultTab) {
                        if recommendTab == .main {
                            continue
                        }
                        let model = SearchIntentionCapsuleModel(type: .tab(tab: recommendTab, recommendInfo: info), isSelected: false)
                        if type != info.searchAction.tab {
                            resultModels.append(model)
                        } else if let appID = searchTab.cast()?.appID, type == .openSearchTab, appID != info.searchAction.appID {
                            resultModels.append(model)
                        }
                    }
                }
            case .filterValue:
                if let tabConfig = tabConfig,
                   let filterAction = info.searchAction.filters.first,
                   let filter = SearchActionFilterPBTransform.converToFilter(actionFilter: filterAction,
                                                                             filterEntity: info.filterEntities.first,
                                                                             shouldIncludeValue: true,
                                                                             userResolver: userResolver) {
                    if !selectedFilters.contains(where: { selectedFilter in
                        selectedFilter.sameType(with: filter)
                    }), tabConfig.supportedFilters.contains(where: { searchFilter in
                        searchFilter.sameType(with: filter)
                    }) {
                        let finalFilter = SearchFilter.specificFilterValue(filter, filterAction.specificFilterActionTitle, false)
                        let model = SearchIntentionCapsuleModel(type: .filter(filter: finalFilter, recommendInfo: info), isSelected: false)
                        resultModels.append(model)
                    }
                }
            case .filter:
                if let tabConfig = tabConfig,
                   let filterAction = info.searchAction.filters.first,
                   let filter = SearchActionFilterPBTransform.converToFilter(actionFilter: filterAction,
                                                                             filterEntity: nil,
                                                                             shouldIncludeValue: false,
                                                                             userResolver: userResolver) {
                    if !selectedFilters.contains(where: { selectedFilter in
                        selectedFilter.sameType(with: filter)
                    }), tabConfig.supportedFilters.contains(where: { searchFilter in
                        searchFilter.sameType(with: filter)
                    }) {
                        //筛选器是不带值的
                        let model = SearchIntentionCapsuleModel(type: .filter(filter: filter.reset(), recommendInfo: info), isSelected: false)
                        resultModels.append(model)
                    }
                }
            case .unknown:
                fallthrough
            @unknown default:
                break
            }
        }
        return resultModels
    }

    func dislikeRecommendCapsule(dislikeInfo: ServerPB_Usearch_CapsuleInfo) {
        guard let _recommendCapsuleInfos = recommendCapsuleInfos else { return }
        recommendCapsuleInfos = _recommendCapsuleInfos.filter({ infoPB in
            !infoPB.isEqualTo(message: dislikeInfo)
        })
    }

    private func transformFilters(filters: [SearchFilter]) -> [SearchFilter] {
        guard let _tabConfig = tabConfig, !_tabConfig.supportedFilters.isEmpty else { return [] }
        var resultFilters: [SearchFilter] = Array(filters)
        for filter in filters {
            if case .specificFilterValue(let _filter, _, _) = filter {
                resultFilters.append(_filter)
            } else if case .commonFilter = filter {
                switch filter {
                case let .commonFilter(.mainFrom(fromIds, _, fromType, isRecommendResultSelected)):
                    resultFilters.append(.docFrom(fromIds: fromIds, recommends: [], fromType: fromType, isRecommendResultSelected: isRecommendResultSelected))
                    resultFilters.append(.chatter(mode: .unlimited, picker: fromIds, recommends: [], fromType: fromType, isRecommendResultSelected: isRecommendResultSelected))
                    if _tabConfig is SearchOpenTabConfig {
                        for openFilter in _tabConfig.supportedFilters {
                            if case let .general(generalFilter) = openFilter, generalFilter.canReplaceByCommonUserFilter {
                                resultFilters.append(.general(.user(generalFilter.info, fromIds)))
                            }
                        }
                    }
                case let .commonFilter(.mainWith(withIds)):
                    resultFilters.append(.withUsers(withIds))
                    resultFilters.append(.chatMemeber(mode: .unlimited, picker: withIds))
                case let .commonFilter(.mainIn(inIds)):
                    resultFilters.append(.docPostIn(inIds))
                    resultFilters.append(.chat(mode: .unlimited, picker: inIds))
                case let .commonFilter(.mainDate(date)):
                    if _tabConfig is SearchMainMessageTabConfig {
                        resultFilters.append(.date(date: date, source: .message))
                    } else if _tabConfig is SearchMainDocTabConfig {
                        resultFilters.append(.date(date: date, source: .doc))
                    } else if _tabConfig is SearchOpenTabConfig {
                        for openFilter in _tabConfig.supportedFilters {
                            if case let .general(generalFilter) = openFilter, generalFilter.canReplaceByCommonDate {
                                resultFilters.append(.general(.date(generalFilter.info, date)))
                            }
                        }
                    }
                default: break
                }
            }
        }
        resultFilters = resultFilters.filter({ filter in
            _tabConfig.supportedFilters.first { support in
                filter.sameType(with: support)
            } != nil
        })
        return resultFilters
    }

    private func advancedSyntaxDeduplicate() {
        guard !selectedTrackAdvancedSyntaxFilters.isEmpty else { return }
        var advancedSyntaxs: [SearchFilter] = []
        for selectedFilter in selectedFilters {
            if let advancedFilter = selectedTrackAdvancedSyntaxFilters.first(where: { $0.sameType(with: selectedFilter) }),
               let newAdvancedFilter = SearchAdvancedSyntaxViewModel.advancedSyntaxFilterDeduplicate(selected: selectedFilter, advancedSyntax: advancedFilter),
               !newAdvancedFilter.isEmpty {
                advancedSyntaxs.append(newAdvancedFilter)
            }
        }
        selectedTrackAdvancedSyntaxFilters = advancedSyntaxs
    }
}
