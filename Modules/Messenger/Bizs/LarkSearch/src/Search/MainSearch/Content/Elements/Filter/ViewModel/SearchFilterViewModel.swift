//
//  SearchFilterViewModel.swift
//  LarkSearch
//
//  Created by Patrick on 2022/5/20.
//

import UIKit
import Foundation
import LarkSearchFilter
import RxSwift
import RxCocoa
import RustPB

final class SearchFilterViewModel {
    let recommender: SearchFilterRecommmender
    let config: SearchTabConfigurable
    private(set) var recommendFilters: [SearchFilter] = [] {
        didSet {
            shouldReloadFiltersSubject.onNext(true)
        }
    }
    private(set) var filters: [SearchFilter] {
        didSet {
            updateCommoblyUsedFilters()
            filterChangedSubject.accept(filters)
            shouldReloadFiltersSubject.onNext(true)
        }
    }

    //常用筛选器的值是固定值，不会发生变化，点击事件会改变filters，从而触发filterChange 和 reload
    private(set) var commonlyUsedFilters: [SearchFilter]

    private let disposeBag = DisposeBag()

    // MARK: - Output
    private let shouldReloadFiltersSubject = PublishSubject<Bool>()
    var shouldReloadFilters: Driver<Bool> {
        return shouldReloadFiltersSubject.asDriver(onErrorJustReturn: false)
    }

    private lazy var filterRefocusSubject = PublishSubject<[SearchFilter]>()
    var filterRefocus: Driver<[SearchFilter]> {
        return filterRefocusSubject.asDriver(onErrorJustReturn: [])
    }

    // MARK: - Forward
    private lazy var filterChangedSubject = BehaviorRelay<[SearchFilter]>(value: filters)
    var filterChanged: Observable<[SearchFilter]> {
        return filterChangedSubject.asObservable()
    }

    private let slotSpanAppliedSubject = PublishSubject<Search_V2_SuggestionInfo.Span>()
    var slotSpanApplied: Observable<Search_V2_SuggestionInfo.Span> {
        return slotSpanAppliedSubject.asObservable()
    }

    // MARK: - Tracking
    private lazy var commonlyUsedfilterShowSubject = PublishSubject<[SearchFilter]>()
    var commonlyUsedfilterShow: Observable<[SearchFilter]> {
        return commonlyUsedfilterShowSubject.asObservable()
    }
    // MARK: - Tracking
    private lazy var commonlyUsedfilterClickSubject = PublishSubject<SearchFilter>()
    var commonlyUsedfilterClick: Observable<SearchFilter> {
        return commonlyUsedfilterClickSubject.asObservable()
    }

    private var currentRecommendedFilterInfos: [RecommendFilterInfo] = []

    init(recommender: SearchFilterRecommmender,
         config: SearchTabConfigurable) {
        self.recommender = recommender
        self.config = config
        self.commonlyUsedFilters = config.commonlyUsedFilters
        self.filters = config.supportedFilters
        setupRecommender()
    }

    func viewDidLoad() {
        shouldReloadFiltersSubject.onNext(true)
    }

    func viewDidAppear(_ animated: Bool) {
        if !commonlyUsedFilters.isEmpty {
            commonlyUsedfilterShowSubject.onNext(commonlyUsedFilters)
        }
    }

    private func setupRecommender() {
        recommender.recommendedFilterInfos
            .subscribe(onNext: { [weak self] recommendedFilterInfos in
                guard let self = self else { return }
                let recommendFilters = recommendedFilterInfos.map { $0.recommendFilter }
                self.recommendFilters = recommendFilters
                self.currentRecommendedFilterInfos = recommendedFilterInfos
            })
            .disposed(by: disposeBag)
        recommender.recommendedFilterResults
            .subscribe(onNext: { [weak self] recommendedFilterResults in
                guard let self = self else { return }
                self.currentRecommendedFilterInfos = []
                for filter in self.filters {
                    switch filter {
                    case let .commonFilter(.mainFrom(fromIds, _, fromType, isRecommendResultSelected)):
                        let newMainFromFilter = SearchFilter.commonFilter(.mainFrom(fromIds: fromIds,
                                                                                   recommends: recommendedFilterResults,
                                                                                   fromType: fromType,
                                                                                   isRecommendResultSelected: isRecommendResultSelected))
                        self.replaceFilter(newMainFromFilter)
                    case let .docFrom(fromIds, _, fromType, isRecommendResultSelected):
                        let newDocFromFilter = SearchFilter.docFrom(fromIds: fromIds, recommends: recommendedFilterResults, fromType: fromType, isRecommendResultSelected: isRecommendResultSelected)
                        self.replaceFilter(newDocFromFilter)
                    case let .chatter(mode, items, _, fromType, isRecommendResultSelected):
                        let newFromFilter = SearchFilter.chatter(mode: mode,
                                                                    picker: items,
                                                                    recommends: recommendedFilterResults,
                                                                    fromType: fromType,
                                                                    isRecommendResultSelected: isRecommendResultSelected)
                        self.replaceFilter(newFromFilter)
                    default: break
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    func recommendFilterChanged(for changedFilter: SearchFilter) {
        if let recommendedFilterInfo = currentRecommendedFilterInfos.first,
           case let .recommend(recommended) = recommendedFilterInfo.recommendFilter,
           changedFilter.sameType(with: recommended) {
            slotSpanAppliedSubject.onNext(recommendedFilterInfo.slotSpan)
        }
    }

    func replaceFilter(_ filter: SearchFilter?) {
        guard let filter = filter, let replaceIndex = filters.firstIndex(where: { $0.sameType(with: filter) }) else { return }
        filters[replaceIndex] = filter
        for item in commonlyUsedFilters {
            if let targetFilter = SearchFilter.mergeCommonlyUsedResponse(initiativeOne: filter, passivityOne: item) {
                replaceCommonlyUsedFilter(targetFilter)
            }
        }
    }

    //常用筛选器是双向联动，但逻辑上是由filters去更新commonlyUsedFilters
    func updateCommoblyUsedFilters() {
        for filter in filters {
            for item in commonlyUsedFilters {
                if let targetFilter = SearchFilter.mergeCommonlyUsedResponse(initiativeOne: filter, passivityOne: item) {
                    replaceCommonlyUsedFilter(targetFilter)
                }
            }
        }
    }

    func clickCommonlyUsedFilter(_ filter: SearchFilter?) {
        guard let filter = filter else { return }
        for item in filters {
            if let targetFilter = SearchFilter.mergeCommonlyUsedResponse(initiativeOne: filter, passivityOne: item) {
                replaceFilter(targetFilter)
                break
            }
        }
    }

    func replaceCommonlyUsedFilter(_ filter: SearchFilter?) {
        guard let filter = filter, let replaceIndex = commonlyUsedFilters.firstIndex(where: {
            guard $0 == filter else { return false }
            switch($0, filter) {
            case (.specificFilterValue(_, _, let isSelected1), .specificFilterValue(_, _, let isSelected2)):
                return isSelected1 != isSelected2
            default:
                return false
            }
        }) else { return }
        commonlyUsedFilters[replaceIndex] = filter
    }

    func refocusTo(filters: [SearchFilter]) {
        self.filterRefocusSubject.onNext(filters)
    }

    func resetAllFilters() {
        self.filters = self.filters.map({ filter in
            return filter.reset()
        })
    }

    func replaceAllFilters(_ filters: [SearchFilter]) {
        self.filters = filters
    }

    func replaceAllCommonlyUsedFilters(_ filters: [SearchFilter]) {
        self.commonlyUsedFilters = filters
    }

    func removeRecommendFilter(_ filter: SearchFilter) {
        if let filterIndex = recommendFilters.firstIndex(where: { recommendFilter in
            if case let .recommend(recommended) = recommendFilter,
               case let .recommend(removedRecommended) = filter {
                return recommended.sameType(with: removedRecommended)
            }
            return false
        }) {
            recommendFilters.remove(at: filterIndex)
        }
    }

    func remove(_ filter: SearchFilter) {
        if let filterIndex = filters.firstIndex(where: { $0.sameType(with: filter) }) {
            filters.remove(at: filterIndex)
        }
    }

    func removeAllRecommendFilters() {
        recommendFilters = []
    }

    func removeSelectedRecommendFilters(current: SearchFilter) {
        filters = filters.filter({ item in
            if case let .recommend(recommended) = item {
                return !current.sameType(with: recommended)
            }
            return true
        })
    }

    func markAllFilterNotRecommend() {
        filters = filters.map({ item in
            if case let .commonFilter(.mainFrom(fromIds, recommends, _, isRecommendResultSelected)) = item {
                return .commonFilter(.mainFrom(fromIds: fromIds, recommends: recommends, fromType: .user, isRecommendResultSelected: isRecommendResultSelected))
            }
            if case let .chatter(mode, items, recommends, _, isRecommendResultSelected) = item {
                return .chatter(mode: mode, picker: items, recommends: recommends, fromType: .user, isRecommendResultSelected: isRecommendResultSelected)
            }
            if case let .docFrom(fromIds, recommends, _, isRecommendResultSelected) = item {
                return .docFrom(fromIds: fromIds, recommends: recommends, fromType: .user, isRecommendResultSelected: isRecommendResultSelected)
            }
            return item
        })
    }

    func clickCommonlyUsedFilter(filter: SearchFilter) {
        commonlyUsedfilterClickSubject.onNext(filter)
    }
}

extension SearchFilter {
    enum DisplayType {
        case unknown, text, avatars, textAvatar
    }
    var displayType: DisplayType {
        switch self {
        case let .recommend(filter):
            return .textAvatar
        case .commonFilter(.mainFrom), .commonFilter(.mainWith), .commonFilter(.mainIn), .general(.user), .general(.userChat), .general(.mailUser), .chatter, .chat, .docCreator, .wikiCreator,
                .chatMemeber, .withUsers, .docSharer, .docPostIn, .docFrom, .docFolderIn, .docWorkspaceIn:
            return .avatars
        case .commonFilter(.mainDate), .general(.date), .general(.calendar), .general(.inputTextFilter), .general(.single), .general(.multiple), .date, .docFormat,
                .chatKeyWord, .chatType, .threadType, .messageType, .messageAttachmentType, .messageMatch, .docType,
                .docContentType, .docOwnedByMe, .docSortType, .groupSortType, .messageChatType, .specificFilterValue(_, _, _):
            return .text
        @unknown default:
            assertionFailure("unimplemented code!!")
            return .unknown
        }
    }
    var isAvatarsType: Bool { displayType == .avatars }
    var isTextType: Bool { displayType == .text }
    var isTextAvatarType: Bool { displayType == .textAvatar }
}
