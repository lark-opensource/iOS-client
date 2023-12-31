//
//  SearchRepo.swift
//  LarkSearch
//
//  Created by Patrick on 2022/5/19.
//

import UIKit
import Foundation
import RxSwift
import LarkSearchFilter
import LarkSDKInterface
import LarkSearchCore
import RustPB
import LarkContainer

protocol SearchRepo: Searcher, SearchFilterRecommmender {
    var sourceMaker: SearchSourceMaker { get set }
    var searchSource: SearchSource? { get set }
    var searchWidthGetter: (() -> CGFloat)? { get set }
    var searchSession: SearchSession { get }
}

enum SearcherState {
    enum ResultType {
        case local([SearchCallBack])
        case remote([SearchCallBack])
    }

    enum SpotlightResultStatus {
        case notSpotlight
        case spotlightResult
        case spotlightResultEmpty
        case spotlightUniversalNetSearchError //spotlight和universal 在综搜弱网下展示有异化
    }

    struct RequestInfo {
        let input: SearcherInput
        let isLoadMore: Bool
        let capturedSession: SearchSession.Captured
        let requestTimeInterval: TimeInterval
        let scene: SearchSceneSection?
        let contextID: String?
        let requestID: UInt
        let searchError: SearchError?
        var spotlightStatus: SpotlightResultStatus = .notSpotlight
    }
    case result(callbacks: [SearchCallBack], requestInfo: RequestInfo, responseTipType: HotAndColdTipType?)
    case error(reason: String, requestInfo: RequestInfo)
}

struct SearcherInput: Equatable {
    let query: String
    let filters: [SearchFilter]
    var advancedSyntaxFilters: [SearchFilter] = [] // 只用做埋点
    let uniqueIdentifier: String

    init(query: String, filters: [SearchFilter] = []) {
        self.query = query
        self.filters = filters
        self.uniqueIdentifier = "\(CACurrentMediaTime())"
    }

    var isEmpty: Bool {
        return query.isEmpty && filters.allSatisfy { $0.isEmpty }
    }

    func isCompleteSame(with other: SearcherInput?, userResolver: UserResolver) -> Bool {
        if !SearchFeatureGatingKey.searchLoadingBugfixProtectFg.isUserEnabled(userResolver: userResolver) {
            return self == other && self.uniqueIdentifier == other?.uniqueIdentifier
        } else {
            return self == other
        }
    }

    static func == (lhs: SearcherInput, rhs: SearcherInput) -> Bool {
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

protocol Searcher {
    var lastInput: SearcherInput? { get set }
    var currentCapturedSession: SearchSession.Captured? { get }
    var state: Observable<SearcherState> { get }
    func search(_ input: SearcherInput)
    func loadMore()
}

protocol SearchFilterRecommmender {
    var recommendedFilterInfos: Observable<[RecommendFilterInfo]> { get }
    var recommendedFilterResults: Observable<[SearchResultType]> { get }
}

struct RecommendFilterInfo {
    let recommendFilter: SearchFilter
    let slotSpan: Search_V2_SuggestionInfo.Span
}
