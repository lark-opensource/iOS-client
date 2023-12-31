//
//  MailSearchCapsuleModel.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/15.
//

import Foundation
//import LarkSearchCore
//import LarkSearchFilter
import ServerPB
import LarkContainer
import RxSwift
import RxCocoa

//enum SearchFilter {
//    case from(String)
//    case to(String)
//    case date((startDate: Date?, endDate: Date)?)
//    case attachment(Bool)
//    case subject(String)
//    case notContain(String)
//}

public final class SearchIntentionCapsuleModel: Equatable {
    enum CapsuleType {
        case filter(filter: MailSearchFilter, recommendInfo: ServerPB_Usearch_CapsuleInfo? = nil)
        case advancedSearch(selectedCount: Int)
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

struct SearcherInput: Equatable {
    let query: String
    let filters: [MailSearchFilter]

    init(query: String, filters: [MailSearchFilter] = []) {
        self.query = query
        self.filters = filters
    }

    var isEmpty: Bool {
        return query.isEmpty && filters.allSatisfy { $0.isEmpty }
    }

    static func ==(lsi: SearcherInput, rsi: SearcherInput) -> Bool {
        if lsi.query == rsi.query {
            let filterLEqualToR = lsi.filters.allSatisfy { (lhsFilter) -> Bool in
                if !lhsFilter.isEmpty {
                    return rsi.filters.contains(where: { $0 == lhsFilter })
                } else {
                    return true
                }
            }
            let filterREqualToL = rsi.filters.allSatisfy { (rhsFilter) -> Bool in
                if !rhsFilter.isEmpty {
                    return lsi.filters.first(where: { (lhsFilter) -> Bool in
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

public final class SearchIntentionCapsulePage {
//    let searchTab: SearchTab // 当前tab
//    let tabConfig: SearchTabConfigable?
    private(set) var selectedFilters: [MailSearchFilter] = [] // 当前选中的筛选器
    // 推荐胶囊, 区分推荐失败(nil)和推荐为空(empty)
    // 推荐失败使用默认筛选器进行补充，推荐为空不补充
    private(set) var recommendCapsuleInfos: [ServerPB_Usearch_CapsuleInfo]?
    // 综搜展示的tab
    var lastInput: SearcherInput? //上次搜索对应的信息，query + filter
//    @ScopedInjectedLazy var mainTabService: SearchMainTabService?

    private let filterChangeSubject = PublishSubject<(Bool, MailSearchFilter?)>()
    var filterChange: Driver<(Bool, MailSearchFilter?)> {
        return filterChangeSubject.asDriver(onErrorJustReturn: (false, nil))
    }

    init(/*searchTab: SearchTab,*/
//         tabConfig: SearchTabConfigable?,
         lastInput: SearcherInput?) {
//        self.searchTab = searchTab
//        self.tabConfig = tabConfig
        self.lastInput = lastInput
    }

    // 筛选项在选中时需要转化为对应筛选器
    func updateSingleFilter(filter: MailSearchFilter, reset: Bool) {
        let _filter = filter
        if reset {
            selectedFilters.removeAll { selectedFilter in
                selectedFilter.sameType(with: _filter)
            }
            filterChangeSubject.onNext((false, _filter))
//        if let _filter = transformFilters(filters: [filter]).first {
//            if _filter.isEmpty {
//                selectedFilters.removeAll { selectedFilter in
//                    selectedFilter.sameType(with: _filter)
//                }
//                MailLogger.info("[mail_search_debug] selectedFilters result1: false filter: \(filter)")
//                filterChangeSubject.onNext((false, _filter))
        } else {
            if let index = selectedFilters.firstIndex(where: { selectedFilter in
                selectedFilter.sameType(with: _filter)
            }) {
//                if case .specificFilterValue(let realFilter, _, _) = _filter {
//                    selectedFilters[index] = realFilter
//                    MailLogger.info("[mail_search_debug] selectedFilters result2: true filter: \(filter)")
//                    filterChangeSubject.onNext((true, realFilter))
//                } else {
                    selectedFilters[index] = _filter
                    filterChangeSubject.onNext((true, _filter))
//                }
            } else {
//                if case .specificFilterValue(let realFilter, _, _) = _filter {
//                    selectedFilters.append(realFilter)
//                    MailLogger.info("[mail_search_debug] selectedFilters result4: true filter: \(filter)")
//                    filterChangeSubject.onNext((true, realFilter))
//                } else {
                    selectedFilters.append(_filter)
                    filterChangeSubject.onNext((true, _filter))
//                }
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

    func coverSelectedFilters(filters: [MailSearchFilter]) {
        selectedFilters = transformFilters(filters: filters).filter({ _filter in
            !_filter.isEmpty
        })
    }

    func resetAllFilters() {
        selectedFilters = []
    }

    func selectedCapsuleModels() -> [SearchIntentionCapsuleModel] {
        var resultModels: [SearchIntentionCapsuleModel] = []
        for selectedFilter in selectedFilters where !selectedFilter.isEmpty {
            resultModels.append(SearchIntentionCapsuleModel(type: .filter(filter: selectedFilter), isSelected: true))
        }
        return resultModels
    }

    func defaultUnSelectedCapsuleModels() -> [SearchIntentionCapsuleModel] {
        var resultModels: [SearchIntentionCapsuleModel] = []
        let supportedFilters: [MailSearchFilter] = MailSearchFilter.supportFilters()
        for filter in supportedFilters {
            if !selectedFilters.contains(where: { selectedFilter in
                selectedFilter.sameType(with: filter)
            }) {
                resultModels.append(SearchIntentionCapsuleModel(type: .filter(filter: filter), isSelected: false))
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

    private func transformFilters(filters: [MailSearchFilter]) -> [MailSearchFilter] {
//        guard let _tabConfig = tabConfig, !_tabConfig.supportedFilters.isEmpty else { return [] }
        var resultFilters: [MailSearchFilter] = Array(filters)
        resultFilters = resultFilters.filter({ filter in
            MailSearchFilter.supportFilters().first { support in
                filter.sameType(with: support)
            } != nil
        })
        return resultFilters
    }
}

