//
//  SearchAdvancedSyntaxViewModel.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/12/8.
//

import Foundation
import LarkContainer
import LKCommonsLogging
import LarkSearchCore
import LarkSearchFilter
import LarkSDKInterface
import Reachability
import RxSwift
import RxCocoa
import RustPB
import ServerPB
import LarkMessengerInterface
import LarkRustClient

class SearchAdvancedSyntaxViewModel: UserResolverWrapper {
    static let logger = Logger.log(SearchAdvancedSyntaxViewModel.self, category: "Module.Search")
    static let advanceSyntaxRegex: String = "(^|[ ])(from|in|with)[:|：]"
    let userResolver: UserResolver
    private var searcher: SearchAdvancedSyntaxSearchService
    var resultCellViewModels: [SearchAdvancedSyntaxCellViewModel] = []
    private var currentTab: SearchTab?
    private var currentTabConfig: SearchTabConfigurable?
    private var lastAdvancedSyntaxInput: SearchAdvancedSyntaxInput?
    private let disposeBag = DisposeBag()

    private let shouldReloadDataSubject = PublishSubject<Bool>()
    var shouldReloadData: Driver<Bool> {
        return shouldReloadDataSubject.asDriver(onErrorJustReturn: false)
    }

    private let shouldShowSubject = PublishSubject<Bool>()
    var shouldShow: Driver<Bool> {
        return shouldShowSubject.asDriver(onErrorJustReturn: false)
    }

    private let didSelectedAdvancedSyntaxSubject = PublishSubject<SearchAdvancedSyntaxCellViewModel?>()
    var didSelectedAdvancedSyntax: Driver<SearchAdvancedSyntaxCellViewModel?> {
        return didSelectedAdvancedSyntaxSubject.asDriver(onErrorJustReturn: nil)
    }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.searcher = SearchAdvancedSyntaxSearchService(userResolver: userResolver)
        setupSubscribe()
    }

    func searchAdvancedSyntax(input: SearcherInput, tab: SearchTab, tabConfig: SearchTabConfigurable?) {
        currentTab = tab
        currentTabConfig = tabConfig
        resultCellViewModels = []
        shouldReloadDataSubject.onNext(true)
        shouldShowSubject.onNext(false)

        guard SearchFeatureGatingKey.enableAdvancedSyntax.isUserEnabled(userResolver: userResolver), let tab = currentTab else { return }
        guard let (advancedSyntaxType, query, match) = findLastAdvancedSyntax(query: input.query) else { return }
        let advancedSyntaxInput = SearchAdvancedSyntaxInput(query: query, originSearcherInput: input, match: match)
        lastAdvancedSyntaxInput = advancedSyntaxInput
        searcher.search(advancedSyntaxInput, searchType: advancedSyntaxType, tab: tab)
    }

    private func setupSubscribe() {
        searcher.searchState
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }
                self.updateState(withState: state)
            })
            .disposed(by: disposeBag)
    }

    private func updateState(withState state: AdvancedSyntaxSearchState) {
        switch state {
        case let .success(requestInfo, results):
            let resultViewModels = transformResultsToViewModels(requestInfo: requestInfo, results: results)
            if !resultViewModels.isEmpty {
                resultCellViewModels = resultViewModels
                shouldReloadDataSubject.onNext(true)
                shouldShowSubject.onNext(true)
            } else {
                shouldShowSubject.onNext(false)
            }
        case .error:
            shouldShowSubject.onNext(false)
        }
    }

    // 将搜索结果转化为cellViewModels
    private func transformResultsToViewModels(requestInfo: RequestInfo, results: [SearchAdvancedSyntaxItem]) -> [SearchAdvancedSyntaxCellViewModel] {
        var resultViewModels: [SearchAdvancedSyntaxCellViewModel] = []
        resultViewModels = results.compactMap { result -> SearchAdvancedSyntaxCellViewModel? in
            if let filter = self.advancedSyntaxFilter(tabConfig: self.currentTabConfig, advancedSyntaxType: requestInfo.searchType, result: result) {
                return SearchAdvancedSyntaxCellViewModel(filter: filter, requestInfo: requestInfo)
            }
            return nil
        }
        return resultViewModels
    }

    func didSelect(at indexPath: IndexPath) {
        if let cellViewModel = resultCellViewModels[safe: indexPath.row] {
            didSelectedAdvancedSyntaxSubject.onNext(cellViewModel)
        }
    }

    private func findLastAdvancedSyntax(query: String) -> (SearchFilter.AdvancedSyntaxFilterType, String, NSTextCheckingResult)? {
        guard !query.isEmpty else { return nil }
        guard !query.isEmpty, let regularExpression = try? NSRegularExpression(pattern: Self.advanceSyntaxRegex) else { return nil}

        let matches = regularExpression.matches(in: query, range: NSRange(location: 0, length: query.count))
        if let lastMatch = matches.last, lastMatch.range.location != NSNotFound, lastMatch.range.length > 0 {
            let advancedSyntaxStr = NSString(string: query).substring(with: lastMatch.range)
            let advancedSyntaxType: SearchFilter.AdvancedSyntaxFilterType?
            if advancedSyntaxStr.contains("in") {
                advancedSyntaxType = .inFilter
            } else if advancedSyntaxStr.contains("from") {
                advancedSyntaxType = .fromFilter
            } else if advancedSyntaxStr.contains("with") {
                advancedSyntaxType = .withFilter
            } else {
                return nil
            }
            if let _advancedSyntaxType = advancedSyntaxType,
               advancedSyntaxFilter(tabConfig: currentTabConfig, advancedSyntaxType: _advancedSyntaxType, result: nil) != nil {
                let queryStart = lastMatch.range.location + lastMatch.range.length
                let searchQueryStr = query.count > queryStart ? query.substring(from: queryStart) : ""
                return (_advancedSyntaxType, searchQueryStr, lastMatch)
            }
        }
        return nil
    }

    private func advancedSyntaxFilter(tabConfig: SearchTabConfigurable?, advancedSyntaxType: SearchFilter.AdvancedSyntaxFilterType, result: SearchAdvancedSyntaxItem?) -> SearchFilter? {
        guard SearchFeatureGatingKey.enableAdvancedSyntax.isUserEnabled(userResolver: userResolver) else { return nil }
        guard let _tabConfig = tabConfig else { return nil }
        var chatItems: [ForwardItem] = []
        var chatterItems: [SearchChatterPickerItem] = []
        if let forwardItem = result as? ForwardItem {
            chatItems.append(forwardItem)
        }
        if let chatterPickerItem = result as? SearchChatterPickerItem {
            chatterItems.append(chatterPickerItem)
        }
        var filter: SearchFilter?
        switch advancedSyntaxType {
        case .fromFilter:
            switch _tabConfig.tab {
            case .main:
                filter = SearchFilter.commonFilter(.mainFrom(fromIds: chatterItems, recommends: [], fromType: .user, isRecommendResultSelected: false))
            case .message:
                if let messageTabConfig = _tabConfig as? SearchMainMessageTabConfig {
                    filter = SearchFilter.chatter(mode: messageTabConfig.chatMode, picker: chatterItems, recommends: [], fromType: .user, isRecommendResultSelected: false)
                }
            case .doc:
                filter = SearchFilter.docFrom(fromIds: chatterItems, recommends: [], fromType: .user, isRecommendResultSelected: false)
            case .open:
                for openFilter in _tabConfig.supportedFilters {
                    if case let SearchFilter.general(.user(customFilterInfo, _)) = openFilter,
                       customFilterInfo.associatedSmartFilter == .smartUser {
                        filter = SearchFilter.general(.user(customFilterInfo, chatterItems))
                        break
                    }
                }
            default:
                break
            }
        case .withFilter:
            switch _tabConfig.tab {
            case .main:
                filter = SearchFilter.commonFilter(.mainWith(chatterItems))
            case .message:
                filter = SearchFilter.withUsers(chatterItems)
            case .chat:
                if let chatTabConfig = _tabConfig as? SearchMainChatTabConfig {
                    filter = SearchFilter.chatMemeber(mode: chatTabConfig.chatMode, picker: chatterItems)
                }
            default:
                break
            }
        case .inFilter:
            switch _tabConfig.tab {
            case .main:
                filter = SearchFilter.commonFilter(.mainIn(inIds: chatItems))
            case .doc:
                filter = SearchFilter.docPostIn(chatItems)
            case .message:
                if let messageTabConfig = _tabConfig as? SearchMainMessageTabConfig {
                    filter = SearchFilter.chat(mode: messageTabConfig.chatMode, picker: chatItems)
                }
            default:
                break
            }
        @unknown default:
            break
        }
        return filter
    }

    // 选中高级语法
    static func advancedSyntaxFilterMerge(selected: SearchFilter, advancedSyntax: SearchFilter) -> SearchFilter? {
        func mergeForwardItems(itemsL: [ForwardItem], itemsR: [ForwardItem]) -> [ForwardItem] {
            var result: [ForwardItem] = itemsL
            for itemR in itemsR {
                if !result.contains(where: { $0.id == itemR.id }) {
                    result.append(itemR)
                }
            }
            return result
        }
        func mergeChatterItems(itemsL: [SearchChatterPickerItem], itemsR: [SearchChatterPickerItem]) -> [SearchChatterPickerItem] {
            var result: [SearchChatterPickerItem] = itemsL
            for itemR in itemsR {
                if !result.contains(where: { $0.chatterID == itemR.chatterID }) {
                    result.append(itemR)
                }
            }
            return result
        }

        guard selected.sameType(with: advancedSyntax) else { return nil }
        var resultFilter: SearchFilter?
        switch (selected, advancedSyntax) {
        case (.commonFilter(.mainFrom(let fromIdsL, let fromRecommendsL, let fromTypeL, let isRecommendResultSelectedL)),
              .commonFilter(.mainFrom(let fromIdsR, _, _, _))):
            resultFilter = .commonFilter(.mainFrom(fromIds: mergeChatterItems(itemsL: fromIdsL, itemsR: fromIdsR),
                                                   recommends: fromRecommendsL,
                                                   fromType: fromTypeL,
                                                   isRecommendResultSelected: isRecommendResultSelectedL))
        case (.commonFilter(.mainWith(let itemsL)), .commonFilter(.mainWith(let itemsR))):
            resultFilter = .commonFilter(.mainWith(mergeChatterItems(itemsL: itemsL, itemsR: itemsR)))
        case (.commonFilter(.mainIn(let idsL)), .commonFilter(.mainIn(let idsR))):
            resultFilter = .commonFilter(.mainIn(inIds: mergeForwardItems(itemsL: idsL, itemsR: idsR)))
        case (.chatter(let modeL, let chatterItemsL, let recommendsL, let fromTypeL, let isRecommendResultSelectedL),
              .chatter(_, let chatterItemsR, _, _, _)):
            resultFilter = .chatter(mode: modeL,
                                    picker: mergeChatterItems(itemsL: chatterItemsL, itemsR: chatterItemsR),
                                    recommends: recommendsL,
                                    fromType: fromTypeL,
                                    isRecommendResultSelected: isRecommendResultSelectedL)
        case (.docFrom(let chatterItemsL, let recommendsL, let fromTypeL, let isRecommendResultSelectedL),
              .docFrom(let chatterItemsR, _, _, _)):
            resultFilter = .docFrom(fromIds: mergeChatterItems(itemsL: chatterItemsL, itemsR: chatterItemsR),
                                    recommends: recommendsL,
                                    fromType: fromTypeL,
                                    isRecommendResultSelected: isRecommendResultSelectedL)
        case (.withUsers(let chatterItemsL), .withUsers(let chatterItemsR)):
            resultFilter = .withUsers(mergeChatterItems(itemsL: chatterItemsL, itemsR: chatterItemsR))
        case (.chatMemeber(let modeL, let chatterItemsL), .chatMemeber(_, let chatterItemsR)):
            resultFilter = .chatMemeber(mode: modeL, picker: mergeChatterItems(itemsL: chatterItemsL, itemsR: chatterItemsR))
        case (.docPostIn(let chatItemsL), .docPostIn(let chatItemsR)):
            resultFilter = .docPostIn(mergeForwardItems(itemsL: chatItemsL, itemsR: chatItemsR))
        case (.chat(let modeL, let chatItemsL), .chat(_, let chatItemsR)):
            resultFilter = .chat(mode: modeL, picker: mergeForwardItems(itemsL: chatItemsL, itemsR: chatItemsR))
        case (.general(.user(let customFilterInfoL, let chatterItemsL)), .general(.user(_, let chatterItemsR))):
            resultFilter = .general(.user(customFilterInfoL, mergeChatterItems(itemsL: chatterItemsL, itemsR: chatterItemsR)))
        default:
            break
        }
        return resultFilter
    }

    // 用户手动更改筛选器时，将不再使用的高级语法筛选器去除
    static func advancedSyntaxFilterDeduplicate(selected: SearchFilter, advancedSyntax: SearchFilter) -> SearchFilter? {
        func selectedDeduplicateChatItems(selectedItems: [ForwardItem], advancedSyntaxItems: [ForwardItem]) -> [ForwardItem] {
            var result: [ForwardItem] = []
            for advancedSyntaxItem in advancedSyntaxItems {
                if selectedItems.contains(where: { $0.id == advancedSyntaxItem.id }) {
                    result.append(advancedSyntaxItem)
                }
            }
            return result
        }
        func selectedDeduplicateChatterItems(selected: [SearchChatterPickerItem], advancedSyntax: [SearchChatterPickerItem]) -> [SearchChatterPickerItem] {
            var result: [SearchChatterPickerItem] = []
            for advancedSyntaxItem in advancedSyntax {
                if selected.contains(where: { $0.chatterID == advancedSyntaxItem.chatterID }) {
                    result.append(advancedSyntaxItem)
                }
            }
            return result
        }

        guard selected.sameType(with: advancedSyntax) else { return nil }
        var resultFilter: SearchFilter?
        switch (selected, advancedSyntax) {
        case (.commonFilter(.mainFrom(let fromIdsL, let fromRecommendsL, let fromTypeL, let isRecommendResultSelectedL)),
              .commonFilter(.mainFrom(let fromIdsR, _, _, _))):
            resultFilter = .commonFilter(.mainFrom(fromIds: selectedDeduplicateChatterItems(selected: fromIdsL, advancedSyntax: fromIdsR),
                                                   recommends: fromRecommendsL,
                                                   fromType: fromTypeL,
                                                   isRecommendResultSelected: isRecommendResultSelectedL))
        case (.commonFilter(.mainWith(let itemsL)), .commonFilter(.mainWith(let itemsR))):
            resultFilter = .commonFilter(.mainWith(selectedDeduplicateChatterItems(selected: itemsL, advancedSyntax: itemsR)))
        case (.commonFilter(.mainIn(let idsL)), .commonFilter(.mainIn(let idsR))):
            resultFilter = .commonFilter(.mainIn(inIds: selectedDeduplicateChatItems(selectedItems: idsL, advancedSyntaxItems: idsR)))
        case (.chatter(let modeL, let chatterItemsL, let recommendsL, let fromTypeL, let isRecommendResultSelectedL),
              .chatter(_, let chatterItemsR, _, _, _)):
            resultFilter = .chatter(mode: modeL,
                                    picker: selectedDeduplicateChatterItems(selected: chatterItemsL, advancedSyntax: chatterItemsR),
                                    recommends: recommendsL,
                                    fromType: fromTypeL,
                                    isRecommendResultSelected: isRecommendResultSelectedL)
        case (.docFrom(let chatterItemsL, let recommendsL, let fromTypeL, let isRecommendResultSelectedL),
              .docFrom(let chatterItemsR, _, _, _)):
            resultFilter = .docFrom(fromIds: selectedDeduplicateChatterItems(selected: chatterItemsL, advancedSyntax: chatterItemsR),
                                    recommends: recommendsL,
                                    fromType: fromTypeL,
                                    isRecommendResultSelected: isRecommendResultSelectedL)
        case (.withUsers(let chatterItemsL), .withUsers(let chatterItemsR)):
            resultFilter = .withUsers(selectedDeduplicateChatterItems(selected: chatterItemsL, advancedSyntax: chatterItemsR))
        case (.chatMemeber(let modeL, let chatterItemsL), .chatMemeber(_, let chatterItemsR)):
            resultFilter = .chatMemeber(mode: modeL,
                                        picker: selectedDeduplicateChatterItems(selected: chatterItemsL, advancedSyntax: chatterItemsR))
        case (.docPostIn(let chatItemsL), .docPostIn(let chatItemsR)):
            resultFilter = .docPostIn(selectedDeduplicateChatItems(selectedItems: chatItemsL, advancedSyntaxItems: chatItemsR))
        case (.chat(let modeL, let chatItemsL), .chat(_, let chatItemsR)):
            resultFilter = .chat(mode: modeL, picker: selectedDeduplicateChatItems(selectedItems: chatItemsL, advancedSyntaxItems: chatItemsR))
        case (.general(.user(let customFilterInfoL, let chatterItemsL)), .general(.user(_, let chatterItemsR))):
            resultFilter = .general(.user(customFilterInfoL, selectedDeduplicateChatterItems(selected: chatterItemsL, advancedSyntax: chatterItemsR)))
        default:
            break
        }
        if resultFilter?.isEmpty ?? true {
            return nil
        }
        return resultFilter
    }
}
