//
//  SearchIntentionCapsuleViewModel.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/15.
//

import Foundation
//import LarkSearchFilter
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
    static let capsuleLimitCount: Int = 10 // 额外加【高级搜索】，总数为8，选中筛选器可超过8个，保证所有筛选器展示出来

    var capsulePage: SearchIntentionCapsulePage
    weak var superVC: UIViewController?
    weak var capsuleView: SearchIntentionCapsuleView?
    private let clickAction: SearchFilterClickAction
    var intentionCapsuleUpdateEnd: Bool = false
    var lastFocusIndex: Int?
    let accountContext: MailAccountContext
    private let disposeBag = DisposeBag()

    //to SearchMainRootViewModel
//    private let shouldRouteTabSubject = PublishSubject<SearchTab>()
//    var shouldRouteTab: Driver<SearchTab> {
//        return shouldRouteTabSubject.asDriver(onErrorJustReturn: SearchTab.main)
//    }
    private let shouldChangeFilterToSearchSubject = PublishSubject<[MailSearchFilter]>()
    var shouldChangeFilterToSearch: Driver<[MailSearchFilter]> {
        return shouldChangeFilterToSearchSubject.asDriver(onErrorJustReturn: [])
    }
    private let shouldDislikeIntentionCapsuleSubject = PublishSubject<MailSearchFilter?>()
    var shouldDislikeIntentionCapsule: Driver<MailSearchFilter?> {
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
//    private let shouldShowMoreTabWithCurrentTabSubject = PublishSubject<SearchTab>()
//    var shouldShowMoreTabWithCurrentTab: Driver<SearchTab> {
//        return shouldShowMoreTabWithCurrentTabSubject.asDriver(onErrorJustReturn: .main)
//    }

    private let filterChangeSubject = PublishSubject<(Bool, MailSearchFilter?)>()
    var filterChange: Driver<(Bool, MailSearchFilter?)> {
        return filterChangeSubject.asDriver(onErrorJustReturn: (false, nil))
    }

    private let filterResetSubject = PublishSubject<Void>()
    var filterReset: Driver<Void> {
        return filterResetSubject.asDriver(onErrorJustReturn: ())
    }

    var capsuleModels: [SearchIntentionCapsuleModel] = []

    init(accountContext: MailAccountContext,
         capsulePage: SearchIntentionCapsulePage) {
        self.accountContext = accountContext
        self.capsulePage = capsulePage
        self.clickAction = SearchFilterClickAction(accountContext: accountContext)
        self.updateCapsulePage(page: capsulePage)
        self.setupSubscribe()
    }

    func updateCapsulePage(page: SearchIntentionCapsulePage) {
        capsulePage = page
        capsulePage.filterChange
            .drive(onNext: { [weak self] (isAdd, searchFilter) in
                guard let self = self else { return }
                self.filterChangeSubject.onNext((isAdd, searchFilter))
                self.capsuleViewReloadData(onlySelected: false, shouldScrollToFocus: false, showUnselectedAnimated: false)
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
//        if capsuleModels.isEmpty, onlySelected {
//            capsuleModels = createCapsuleModels(onlySelected: false)
//        }
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
                self.shouldChangeFilterToSearchSubject.onNext([]) //SearchFilter.supportFilters())
                self.filterResetSubject.onNext(())
                self.capsuleModels = self.createCapsuleModels(onlySelected: true)
                self.lastFocusIndex = nil
                self.capsuleViewReloadData(onlySelected: false, shouldScrollToFocus: true, showUnselectedAnimated: false)
            })
            .disposed(by: disposeBag)
    }

    func updatePullTabs() {
//        guard !tabs.isEmpty else { return }
//        capsulePage.userLikeTabs = tabs
        capsuleModels = createCapsuleModels()
        capsuleView?.capsuleCollectionViewReload()
    }

    func updatePullAvailableTabs() {
//        guard !tabs.isEmpty else { return }
//        capsulePage.availableTabs = tabs
        capsuleModels = createCapsuleModels()
        capsuleView?.capsuleCollectionViewReload()
    }

    func noticeSearchStart(input: SearcherInput) {
        intentionCapsuleUpdateEnd = false
        let isFilterChange = !isSameContent(left: input.filters, right: capsulePage.lastInput?.filters ?? [], shouldSameSequence: false)
        if !isFilterChange && capsulePage.lastInput != nil {
            intentionCapsuleUpdateEnd = true
            capsulePage.lastInput = input
            return
        }
        if isFilterChange {
            capsuleViewReloadData(onlySelected: true, shouldScrollToFocus: true, showUnselectedAnimated: false)
        }
        capsulePage.lastInput = input
        intentionCapsuleUpdateEnd = true
        capsulePage.updateRecommendCapsuleInfos(capsuleInfoPB: nil)
        capsuleViewReloadData(onlySelected: false, shouldScrollToFocus: true, showUnselectedAnimated: true)
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
//        case .tab(let clickedTab, _):
//            if capsuleModel.isSelected {
//                shouldShowMoreTabWithCurrentTabSubject.onNext(capsulePage.searchTab)
//            } else {
//                routeToTab(tab: clickedTab)
//            }
//            break
        case .filter(let clickedFilter, _):
            let pos = getTrackCapsulePos(indexPath: indexPath, capsuleModel: capsuleModel)
//            if case .specificFilterValue(let filter, _, _) = clickedFilter {
//                updateFilterToSearch(filter: filter, fromCapsule: true, pos: pos)
//            } else {
                if let fromVC = superVC {
                    clickAction.handle(filter: clickedFilter, from: fromVC) { [weak self] changedFilter in
                        guard let self = self else { return }
                        var reset = false
                        if case .general(.single(.hasAttach(let hasAttach), _)) = changedFilter {
                            reset = !hasAttach
                        } else if changedFilter.isEmpty {
                            reset = true
                        }
                        self.updateFilterToSearch(filter: changedFilter, fromCapsule: true, pos: pos, reset: reset)
                    }
                }
//            }
        }
    }

    func clickCellExpandView(withCapsuleModel capsuleModel: SearchIntentionCapsuleModel) {
        switch capsuleModel.type {
        case .filter(let clickedFilter, _):
            let selectedFilters = capsulePage.selectedFilters
            if !capsuleModel.isSelected, let resetFilter = selectedFilters.first(where: { $0.sameType(with: clickedFilter) }) {
                MailLogger.info("[mail_search_debug] -- clickCellExpandView resetFilter: \(resetFilter)")
                updateFilterToSearch(filter: resetFilter, fromCapsule: true, pos: -1, reset: true)
            }
        case .advancedSearch:
            assertionFailure("this type should not have expandView")
        }
    }

    func showAdvancedSearchVC() {
        if let fromVC = superVC { //let config = capsulePage.tabConfig
            shouldResignFirstResponderSubject.onNext(true)
            let selectedFilters = capsulePage.selectedFilters
            clickAction.showAdvancedSearch(fromVC: fromVC, supportFilters: mergeSelectedAndSupportFilter(selected: selectedFilters, supported: MailSearchFilter.supportFilters()))
        }
    }

    // 当用户点击胶囊修改筛选器时上报埋点
    private func updateFilterToSearch(filter: MailSearchFilter, fromCapsule: Bool, pos: Int, reset: Bool = false) {
        // 筛选器没有发生变化，不执行动作
        let sameFilter = capsulePage.selectedFilters.first { selectedFilter in
            selectedFilter == filter
        }
        //MailLogger.info("[mail_search_debug] sameFilter: \(sameFilter) selectedFilters: \(capsulePage.selectedFilters) filter: \(filter) reset: \(reset)")
        if sameFilter != nil && !reset {
            return
        }
        //guard sameFilter == nil && !reset else { return }
        if pos >= 0, !filter.isEmpty, fromCapsule {
            var capsuleStatus: [String: Any] = [:]
            capsuleStatus["capsule_type"] = "filter"
            //capsuleStatus["capsule_value"] = ["filter_name": filter.trackingRepresentation]
            shouldTrackCapsuleClickSubject.onNext((pos, capsuleStatus))
        }
        // search
        capsulePage.updateSingleFilter(filter: filter, reset: reset)
        let selectedFilters = capsulePage.selectedFilters
//        let supportedFilters = [] //capsulePage.tabConfig?.supportedFilters ?? []
//        shouldChangeFilterToSearchSubject.onNext(mergeSelectedAndSupportFilter(selected: selectedFilters, supported: SearchFilter.supportFilters()))
        shouldChangeFilterToSearchSubject.onNext(selectedFilters)
        //MailLogger.info("[mail_search_debug] selectedFilters: \(selectedFilters) filter: \(filter)")

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

    func mergeSelectedAndSupportFilter(selected: [MailSearchFilter], supported: [MailSearchFilter]) -> [MailSearchFilter] {
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
    private func filterIndexInCapsuleModels(filter: MailSearchFilter, models: [SearchIntentionCapsuleModel]) -> Int? {
        for (index, model) in models.enumerated() {
            if case .filter(let modelFilter, _) = model.type {
                var _filter = filter
                var _modelFilter = modelFilter
//                if case .specificFilterValue(let filterValue, _, _) = filter {
//                    _filter = filterValue
//                }
//                if case .specificFilterValue(let filterValue, _, _) = modelFilter {
//                    _modelFilter = filterValue
//                }
                if _filter.sameType(with: _modelFilter) {
                    return index
                }
            }
        }
        return nil
    }

//    private func routeToTab(tab: SearchTab) {
//        shouldRouteTabSubject.onNext(tab)
//    }

    private func createCapsuleModels(onlySelected: Bool = false) -> [SearchIntentionCapsuleModel] {
        var result: [SearchIntentionCapsuleModel] = capsulePage.selectedCapsuleModels()
        if onlySelected {
            return result
        } else {
            var unSelectedModels = capsulePage.defaultUnSelectedCapsuleModels() //capsulePage.recommendCapsuleInfos == nil ?  : capsulePage.recommendUnselectedCapsuleModels()
            if result.count < Self.capsuleLimitCount {
                let gap = Self.capsuleLimitCount - result.count
                if gap > 0 && unSelectedModels.count > gap {
                    unSelectedModels = Array(unSelectedModels.prefix(gap))
                }
                result += unSelectedModels
            }
//            if let tabConfig = capsulePage.tabConfig, !tabConfig.supportedFilters.isEmpty {
                result.append(SearchIntentionCapsuleModel(type: .advancedSearch(selectedCount: capsulePage.selectedFilters.count),
                                                          isSelected: false))
//            }
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
