//
//  SearchIntentionCapsuleViewModel.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/7/10.
//

import Foundation
import LarkSearchFilter
import RxSwift
import RxCocoa
import RustPB
import ServerPB
import LKCommonsLogging
import LarkContainer
import LarkRustClient
import UniverseDesignActionPanel

final class SearchIntentionCapsuleViewModel {
    static let logger = Logger.log(SearchIntentionCapsuleViewModel.self, category: "SearchIntentionCapsuleViewModel")
    static let capsuleLimitCount: Int = 7 // 额外加【高级搜索】，总数为8，选中筛选器可超过8个，保证所有筛选器展示出来

    var capsulePage: SearchIntentionCapsulePage
    weak var superVC: UIViewController?
    weak var capsuleView: SearchIntentionCapsuleView?
    private let clickAction: SearchFilterClickAction
    var intentionCapsuleUpdateEnd: Bool = false
    var lastFocusIndex: Int?
    let userResolver: UserResolver
    private let disposeBag = DisposeBag()

    //to SearchMainRootViewModel
    private let shouldRouteTabSubject = PublishSubject<SearchTab>()
    var shouldRouteTab: Driver<SearchTab> {
        return shouldRouteTabSubject.asDriver(onErrorJustReturn: SearchTab.main)
    }
    private let shouldChangeFilterToSearchSubject = PublishSubject<[SearchFilter]>()
    var shouldChangeFilterToSearch: Driver<[SearchFilter]> {
        return shouldChangeFilterToSearchSubject.asDriver(onErrorJustReturn: [])
    }
    private let shouldDislikeIntentionCapsuleSubject = PublishSubject<SearchFilter?>()
    var shouldDislikeIntentionCapsule: Driver<SearchFilter?> {
        return shouldDislikeIntentionCapsuleSubject.asDriver(onErrorJustReturn: nil)
    }
    private let shouldResignFirstResponderSubject = PublishSubject<Bool>()
    var shouldResignFirstResponder: Driver<Bool> {
        return shouldResignFirstResponderSubject.asDriver(onErrorJustReturn: false)
    }
    private let shouldTrackAdvancedSearchClickSubject = PublishSubject<Bool>()
    var shouldTrackAdvancedSearchClick: Driver<Bool> {
        return shouldTrackAdvancedSearchClickSubject.asDriver(onErrorJustReturn: false)
    }
    private let shouldTrackCapsuleClickSubject = PublishSubject<(Int, [String: Any])>()
    var shouldTrackCapsuleClick: Driver<(Int, [String: Any])> {
        return shouldTrackCapsuleClickSubject.asDriver(onErrorJustReturn: (0, [:]))
    }
    private let shouldShowMoreTabWithCurrentTabSubject = PublishSubject<SearchTab>()
    var shouldShowMoreTabWithCurrentTab: Driver<SearchTab> {
        return shouldShowMoreTabWithCurrentTabSubject.asDriver(onErrorJustReturn: .main)
    }

    private let filterChangeSubject = PublishSubject<(Bool, SearchFilter?)>()
    var filterChange: Driver<(Bool, SearchFilter?)> {
        return filterChangeSubject.asDriver(onErrorJustReturn: (false, nil))
    }

    private let filterResetSubject = PublishSubject<Void>()
    var filterReset: Driver<Void> {
        return filterResetSubject.asDriver(onErrorJustReturn: ())
    }

    var capsuleModels: [SearchIntentionCapsuleModel] = []

    init(userResolver: UserResolver,
         capsulePage: SearchIntentionCapsulePage) {
        self.userResolver = userResolver
        self.capsulePage = capsulePage
        self.clickAction = SearchFilterClickAction(userResolver: userResolver)
        updateCapsulePage(page: capsulePage)
        setupSubscribe()
    }

    func updateCapsulePage(page: SearchIntentionCapsulePage) {
        capsulePage = page
        capsulePage.filterChange
            .drive(onNext: { [weak self] (isAdd, searchFilter) in
                guard let self = self else { return }
                self.filterChangeSubject.onNext((isAdd, searchFilter))
            })
            .disposed(by: disposeBag)
        lastFocusIndex = nil
        capsuleViewReloadData(onlySelected: true, shouldScrollToFocus: true, showUnselectedAnimated: false)
    }

    func capsuleViewReloadData(onlySelected: Bool, shouldScrollToFocus: Bool = false, showUnselectedAnimated: Bool) {
        func isSameModels(originModels: [SearchIntentionCapsuleModel], newModels: [SearchIntentionCapsuleModel]) -> Bool {
            guard originModels.count == newModels.count, !newModels.isEmpty else { return false }
            for index in 0..<newModels.count {
                if originModels[index] != newModels[index] {
                    return false
                }
            }
            return true
        }
        let originCapsuleModels = capsuleModels
        capsuleModels = createCapsuleModels(onlySelected: onlySelected)
        // 综搜没有默认选中tab, 防闪
        if capsuleModels.isEmpty, onlySelected {
            capsuleModels = createCapsuleModels(onlySelected: false)
        }
        let animated = showUnselectedAnimated && !isSameModels(originModels: originCapsuleModels, newModels: capsuleModels)
        capsuleView?.capsuleCollectionViewReload(shouldScrollToFocus: shouldScrollToFocus,
                                                 focusIndex: lastFocusIndex,
                                                 showUnselectedAnimated: animated)
    }

    func setupSubscribe() {
        clickAction.shouldChangeSearchFilter
            .drive(onNext: { [weak self] changedFilter in
                guard let self = self, let _changedFilter = changedFilter  else { return }
                self.updateFilterToSearch(filter: _changedFilter, fromCapsule: false, pos: -1)
            })
            .disposed(by: disposeBag)

        clickAction.shouldResetSearchFilters
            .drive(onNext: { [weak self] shouldReset in
                guard let self = self, shouldReset else { return }
                self.capsulePage.resetAllFilters()
                self.shouldChangeFilterToSearchSubject.onNext(self.capsulePage.tabConfig?.supportedFilters ?? [])
                self.filterResetSubject.onNext(())
                self.capsuleModels = self.createCapsuleModels(onlySelected: true)
                self.lastFocusIndex = nil
                self.capsuleViewReloadData(onlySelected: false, shouldScrollToFocus: true, showUnselectedAnimated: false)
            })
            .disposed(by: disposeBag)

        clickAction.shouldSelectedTab
            .drive(onNext: { [weak self] selectedTab in
                guard let self = self, let _selectedTab = selectedTab, self.capsulePage.searchTab != _selectedTab else { return }
                self.routeToTab(tab: _selectedTab)
            })
            .disposed(by: disposeBag)
    }

    func updatePullTabs(tabs: [SearchTab]) {
        guard !tabs.isEmpty else { return }
        Self.logger.info("SearchIntentionCapsuleViewModel updatePullTabs: \(tabs.map { $0.shortDescription }.joined(separator: ", "))")
        capsulePage.userLikeTabs = tabs
        capsuleModels = createCapsuleModels()
        capsuleView?.capsuleCollectionViewReload()
    }

    func updatePullAvailableTabs(tabs: [SearchTab]) {
        guard !tabs.isEmpty else { return }
        Self.logger.info("SearchIntentionCapsuleViewModel updatePullAvailableTabs: \(tabs.map { $0.shortDescription }.joined(separator: ", "))")
        capsulePage.availableTabs = tabs
        capsuleModels = createCapsuleModels()
        capsuleView?.capsuleCollectionViewReload()
    }

    //如果胶囊推荐数据比搜索数据回来的晚，走兜底
    func noticeSearchEnd(withRequestInfo info: SearcherState.RequestInfo) {
        let isIntentionTab = (capsulePage.searchTab == .doc || capsulePage.searchTab == .message)
        let isUniversalSearch = (info.spotlightStatus == .notSpotlight || info.spotlightStatus == .spotlightUniversalNetSearchError)
        if let lastInput = capsulePage.lastInput,
           !intentionCapsuleUpdateEnd,
           lastInput == info.input,
           isIntentionTab,
           isUniversalSearch,
           !info.isLoadMore {
            intentionCapsuleUpdateEnd = true
            capsulePage.updateRecommendCapsuleInfos(capsuleInfoPB: nil)
            capsuleModels = createCapsuleModels()
            capsuleViewReloadData(onlySelected: false, shouldScrollToFocus: true, showUnselectedAnimated: true)
        }
    }

    func noticeSearchStart(tab: SearchTab, input: SearcherInput) {
        guard tab == capsulePage.searchTab else { return }
        intentionCapsuleUpdateEnd = false
        let isFilterChange = !isSameContent(left: input.filters, right: capsulePage.lastInput?.filters ?? [], shouldSameSequence: false)
        if !isFilterChange && capsulePage.lastInput != nil {
            intentionCapsuleUpdateEnd = true
            capsulePage.lastInput = input
            return
        }
        if isFilterChange || tab == .doc || tab == .message {
            capsuleViewReloadData(onlySelected: true, shouldScrollToFocus: true, showUnselectedAnimated: false)
        }
        capsulePage.lastInput = input
        switch tab {
        case .doc, .message:
            if let searchTab = tab.cast(), let rustService = try? userResolver.resolve(assert: RustService.self) {
                let api = SearchMainIntentionCapsuleApi(rustService: rustService)
                api.pullRecommendCapsules(withTab: searchTab, withInput: input)
                    .observeOn(MainScheduler.asyncInstance)
                    .subscribe(onNext: { [weak self] response in
                        guard let self = self,
                              let lastInput = self.capsulePage.lastInput,
                              tab == self.capsulePage.searchTab,
                              input == lastInput,
                              !self.intentionCapsuleUpdateEnd
                        else { return }
                        self.intentionCapsuleUpdateEnd = true
                        self.capsulePage.updateRecommendCapsuleInfos(capsuleInfoPB: response.capsuleInfoList)
                        self.capsuleViewReloadData(onlySelected: false, shouldScrollToFocus: true, showUnselectedAnimated: true)
                    }, onError: { [weak self] error in
                        guard let self = self,
                              let lastInput = self.capsulePage.lastInput,
                              tab == self.capsulePage.searchTab,
                              input == lastInput,
                              !self.intentionCapsuleUpdateEnd
                        else { return }
                        self.intentionCapsuleUpdateEnd = true
                        self.capsulePage.updateRecommendCapsuleInfos(capsuleInfoPB: nil)
                        self.capsuleViewReloadData(onlySelected: false, shouldScrollToFocus: true, showUnselectedAnimated: true)
                        let tabName = searchTab.type.rawValue
                        let appId = searchTab.appID
                        Self.logger.error("search pull recommend capsules tabID \(tabName) appId \(appId)", error: error)
                    })
                    .disposed(by: disposeBag)
            } else {
                fallthrough
            }
        default:
            intentionCapsuleUpdateEnd = true
            capsulePage.updateRecommendCapsuleInfos(capsuleInfoPB: nil)
            capsuleViewReloadData(onlySelected: false, shouldScrollToFocus: true, showUnselectedAnimated: true)
        }
    }

    func clickCell(withCapsuleModel capsuleModel: SearchIntentionCapsuleModel, indexPath: IndexPath) {
        guard !capsuleModels.isEmpty, indexPath.row >= 0, indexPath.row < capsuleModels.count else { return }
        func getTrackCapsulePos(indexPath: IndexPath, capsuleModel: SearchIntentionCapsuleModel) -> Int {
            var pos: Int = 0
            // 对激活胶囊均报0
            // 对非激活胶囊的位置排序，被点击的顺序，左边第1个为1
            if !capsuleModel.isSelected {
                let selectedCount = (capsuleModels.firstIndex { model in
                    !model.isSelected
                }) ?? 0
                pos = indexPath.row + 1 - selectedCount
            }
            return pos
        }
        switch capsuleModel.type {
        case .advancedSearch:
            showAdvancedSearchVC()
            shouldTrackAdvancedSearchClickSubject.onNext(true)
        case .tab(let clickedTab, _):
            if capsuleModel.isSelected {
                shouldShowMoreTabWithCurrentTabSubject.onNext(capsulePage.searchTab)
            } else {
                routeToTab(tab: clickedTab)
            }
        case .filter(let clickedFilter, _):
            let pos = getTrackCapsulePos(indexPath: indexPath, capsuleModel: capsuleModel)
            if case .docOwnedByMe(let isSelected, _) = clickedFilter {
                updateFilterToSearch(filter: .docOwnedByMe(!isSelected, userResolver.userID), fromCapsule: true, pos: pos)
            } else if case .specificFilterValue(let filter, _, _) = clickedFilter {
                updateFilterToSearch(filter: filter, fromCapsule: true, pos: pos)
            } else {
                if let fromVC = superVC {
                    clickAction.handle(filter: clickedFilter, from: fromVC) { [weak self] changedFilter in
                        guard let self = self else { return }
                        self.updateFilterToSearch(filter: changedFilter, fromCapsule: true, pos: pos)
                    }
                }
            }
        }
    }

    func clickCellExpandView(withCapsuleModel capsuleModel: SearchIntentionCapsuleModel) {
        switch capsuleModel.type {
        case .filter(let clickedFilter, _):
            let resetFilter = clickedFilter.reset()
            updateFilterToSearch(filter: resetFilter, fromCapsule: true, pos: -1)
        case .tab:
            routeToTab(tab: .main)
        case .advancedSearch:
            assertionFailure("this type should not have expandView")
        }
    }

    //未被选中的推荐的内容可以重置
    func longPressCell(withCapsuleModel capsuleModel: SearchIntentionCapsuleModel, sourceView: UIView) {
        guard !capsuleModel.isSelected,
              let currentVC = self.superVC,
              (capsulePage.searchTab == .doc || capsulePage.searchTab == .message)
        else { return }

        var capsuleInfo: ServerPB_Usearch_CapsuleInfo?
        if case .tab(_, let recommendInfo) = capsuleModel.type {
            capsuleInfo = recommendInfo
        } else if case .filter(_, let recommendInfo) = capsuleModel.type {
            capsuleInfo = recommendInfo
        }

        let actionSheet = UDActionSheet(
            config: UDActionSheetUIConfig(
                isShowTitle: false,
                popSource: UDActionSheetSource(sourceView: sourceView, sourceRect: sourceView.bounds, arrowDirection: .up)))
        actionSheet.addDefaultItem(text: BundleI18n.LarkSearch.Lark_NewSearch_SecondarySearch_RecCapsule_HideForNowButton) { [weak self] in
            guard let self = self else { return }
            if let _capsuleInfo = capsuleInfo {
                self.capsulePage.dislikeRecommendCapsule(dislikeInfo: _capsuleInfo)
                if let rustService = try? self.userResolver.resolve(assert: RustService.self) {
                    let resetApi = SearchMainIntentionCapsuleApi(rustService: rustService)
                    resetApi.resetRecommendCapsule(withCapsuleInfo: _capsuleInfo)
                        .observeOn(MainScheduler.asyncInstance)
                        .subscribe(onNext: { response in
                            if response.resetState != .success {
                                Self.logger.info("search reset recommend capsule failure")
                            }
                        }, onError: { error in
                            Self.logger.error("search reset recommend capsule", error: error)
                        })
                        .disposed(by: self.disposeBag)
                }
            }
            self.capsuleModels.removeAll { model in
                model == capsuleModel
            }
            self.capsuleView?.capsuleCollectionViewReload()
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkSearch.Lark_Legacy_Cancel) {
        }
        currentVC.present(actionSheet, animated: true, completion: nil)
    }

    func showAdvancedSearchVC() {
        if let fromVC = superVC, let config = capsulePage.tabConfig {
            shouldResignFirstResponderSubject.onNext(true)
            let selectedFilters = capsulePage.selectedFilters
            let supportedFilters = config.supportedFilters
            clickAction.showAdvancedSearch(fromVC: fromVC, supportFilters: mergeSelectedAndSupportFilter(selected: selectedFilters, supported: supportedFilters))
        }
    }

    func selectedAdvancedSyntax(filter: SearchFilter) {
        Self.logger.info("【Lark Search】selected advanced syntax")
        guard capsulePage.tabConfig?.supportedFilters.contains(where: { $0.sameType(with: filter) }) ?? false else { return }
        // 高级语法埋点相关的
        // 因为SearchFilter是一个枚举类型，加参数比较困难，所以单开一个属性来记录高级语法选中的筛选器
        // 非常trick, 急需将SearchFilter 由枚举改成类或者结构体
        if let seletcedFilterIndex = capsulePage.selectedTrackAdvancedSyntaxFilters.firstIndex(where: { $0.sameType(with: filter) }) {
            if let selectedFilter = capsulePage.selectedTrackAdvancedSyntaxFilters[safe: seletcedFilterIndex],
               let resultFilter = SearchAdvancedSyntaxViewModel.advancedSyntaxFilterMerge(selected: selectedFilter, advancedSyntax: filter) {
                capsulePage.selectedTrackAdvancedSyntaxFilters[seletcedFilterIndex] = resultFilter
            }
        } else {
            capsulePage.selectedTrackAdvancedSyntaxFilters.append(filter)
        }
        // 搜索相关的
        if let selectedFilter = capsulePage.selectedFilters.first(where: { $0.sameType(with: filter) }) {
            if let resultFilter = SearchAdvancedSyntaxViewModel.advancedSyntaxFilterMerge(selected: selectedFilter, advancedSyntax: filter) {
                updateFilterToSearch(filter: resultFilter, fromCapsule: false, pos: -1)
            }
        } else {
            updateFilterToSearch(filter: filter, fromCapsule: false, pos: -1)
        }
    }

    // 当用户点击胶囊修改筛选器时上报埋点
    private func updateFilterToSearch(filter: SearchFilter, fromCapsule: Bool, pos: Int) {
        // 筛选器没有发生变化，不执行动作
        let sameFilter = capsulePage.selectedFilters.first { selectedFilter in
            selectedFilter == filter
        }
        guard sameFilter == nil else { return }
        if pos >= 0, !filter.isEmpty, fromCapsule {
            var capsuleStatus: [String: Any] = [:]
            capsuleStatus["capsule_type"] = "filter"
            capsuleStatus["capsule_value"] = ["filter_name": filter.trackingRepresentation]
            shouldTrackCapsuleClickSubject.onNext((pos, capsuleStatus))
        }
        // search
        capsulePage.updateSingleFilter(filter: filter)
        let selectedFilters = capsulePage.selectedFilters
        let supportedFilters = capsulePage.tabConfig?.supportedFilters ?? []
        shouldChangeFilterToSearchSubject.onNext(mergeSelectedAndSupportFilter(selected: selectedFilters, supported: supportedFilters))

        // update focusIndex
        lastFocusIndex = nil
        let oldCapsuleModels = capsuleModels
        let newCapsuleModels = createCapsuleModels(onlySelected: true)
        if filter.isEmpty {
            if let originIndex = filterIndexInCapsuleModels(filter: filter, models: oldCapsuleModels) {
                lastFocusIndex = originIndex > 0 ? originIndex - 1 : 0
            }
        } else {
            if let index = filterIndexInCapsuleModels(filter: filter, models: newCapsuleModels) {
                lastFocusIndex = index
            }
        }

        //兜底
        if lastFocusIndex == nil, !newCapsuleModels.isEmpty {
            lastFocusIndex = newCapsuleModels.count - 1
        }
    }

    func mergeSelectedAndSupportFilter(selected: [SearchFilter], supported: [SearchFilter]) -> [SearchFilter] {
        var result = supported
        for filter in selected {
            if let index = result.firstIndex(where: { _filter in
                _filter.sameType(with: filter)
            }) {
                result[index] = filter
            }
        }
        return result
    }

    //计算动画前后的位置
    private func filterIndexInCapsuleModels(filter: SearchFilter, models: [SearchIntentionCapsuleModel]) -> Int? {
        for (index, model) in models.enumerated() {
            if case .filter(let modelFilter, _) = model.type {
                var _filter = filter
                var _modelFilter = modelFilter
                if case .specificFilterValue(let filterValue, _, _) = filter {
                    _filter = filterValue
                }
                if case .specificFilterValue(let filterValue, _, _) = modelFilter {
                    _modelFilter = filterValue
                }
                if _filter.sameType(with: _modelFilter) {
                    return index
                }
            }
        }
        return nil
    }

    private func routeToTab(tab: SearchTab) {
        shouldRouteTabSubject.onNext(tab)
    }

    private func createCapsuleModels(onlySelected: Bool = false) -> [SearchIntentionCapsuleModel] {
        var result: [SearchIntentionCapsuleModel] = capsulePage.selectedCapsuleModels()
        if onlySelected {
            return result
        } else {
            var unSelectedModels = capsulePage.recommendCapsuleInfos == nil ? capsulePage.defaultUnSelectedCapsuleModels() : capsulePage.recommendUnselectedCapsuleModels()
            if capsulePage.searchTab == .main {
                result += unSelectedModels
            } else if result.count < Self.capsuleLimitCount {
                let gap = Self.capsuleLimitCount - result.count
                if gap > 0 && unSelectedModels.count > gap {
                    unSelectedModels = Array(unSelectedModels.prefix(gap))
                }
                result += unSelectedModels
            }
            if let tabConfig = capsulePage.tabConfig, !tabConfig.supportedFilters.isEmpty {
                result.append(SearchIntentionCapsuleModel(type: .advancedSearch(selectedCount: capsulePage.selectedFilters.count),
                                                          isSelected: false))
            }
            return result
        }
    }

    private func isSameContent<E: Equatable>(left: [E], right: [E], shouldSameSequence: Bool) -> Bool {
        guard left.count == right.count else { return false }
        if shouldSameSequence {
            return left.elementsEqual(right)
        } else {
            let leftEqualToRight = left.allSatisfy(right.contains)
            let rightEqualToLeft = right.allSatisfy(left.contains)
            return leftEqualToRight && rightEqualToLeft
        }
    }
}
