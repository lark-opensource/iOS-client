//
//  MentionStore.swift
//  LarkIMMention
//
//  Created by Yuri on 2022/12/21.
//

import Foundation
import RxSwift

struct IMMentionReuslt: CustomStringConvertible {
    struct Section {
        var title: String?
        var items: [IMMentionOptionType] = []
        var isShowFooter: Bool = false
        var isInitialSection: Bool = false // 是首字母分组
    }
    
    var sections = [Section]()
    var description: String {
        let counts = sections.map { $0.items.count }
        return "counts=\(counts)"
    }
    
    mutating func setTrackInfo(pageType: PageType, chooseType: ChooseType) {
        sections = sections.map {
            var section = $0
            section.items = section.items.map {
                var i = $0
                i.trackerInfo.pageType = pageType
                i.trackerInfo.chooseType = chooseType
                return i
            }
            return section
        }
    }
    
    mutating func selectItems(with cache: [String: Int]) {
        sections = sections.map {
            var section = $0
            section.items = section.items.map {
                var i = $0
                if let id = i.id {
                    i.isMultipleSelected = cache[id] == nil ? false : true
                } else {
                    i.isMultipleSelected = false
                }
                return i
            }
            return section
        }
    }
}

class MentionStore {
    typealias I18N = BundleI18n.LarkIMMention
    
    var selectedCache: [String: Int] = [:]
 
    var state = PublishSubject<IMMentionState>()
    
    var currentState = IMMentionState()
    var currentItems = IMMentionReuslt()
    
    var didReloadDataHandler: ((IMMentionReuslt, IMMentionState) -> Void)?
    var didRefreshDataHandler: ((IMMentionReuslt, IMMentionState) -> Void)?
    var didReloadItemAtIndexHandler: ((IMMentionReuslt, [IndexPath]) -> Void)?
    
    var currentRes: ProviderEvent.Response?
    var context: IMMentionContext
    init(context: IMMentionContext) {
        self.context = context
    }
    
    func dispatch(event: ProviderEvent) {
        switch event {
        case .startSearch(let string):
            handleStartSearch(query: string)
            didReloadDataHandler?(currentItems, currentState)
        case .loading(let string):
            handleLoading(string: string)
        case .success(let res):
            currentRes = res
            currentState.isShowPrivacy = res.isShowPrivacy
            if let string = res.query, !string.isEmpty {
                handleSearchReuslt(res.res)
            } else {
                handleRecommendReuslt(res.res)
            }
            currentItems.selectItems(with: selectedCache)
            didReloadDataHandler?(currentItems, currentState)
        case .complete:
            handleComplete()
        case .fail(let providerError):
            handleFail(error: providerError)
        }
        state.onNext(currentState)
    }
    
    func switchMultiSelect(isOn: Bool) {
        currentState.isMultiSelected = isOn
        state.onNext(currentState)
        didRefreshDataHandler?(currentItems, currentState)
    }
    
    func toggleItemSelected(item: IMMentionOptionType) {
        guard let id = item.id else { return }
        var indexPaths: [IndexPath] = []
        for (sec, section) in currentItems.sections.enumerated() {
            let row = section.items.firstIndex { $0.id == id }
            if let row = row {
                currentItems.sections[sec].items[row].isMultipleSelected.toggle()
                let indexPath = IndexPath(row: row, section: sec)
                indexPaths.append(indexPath)
            }
        }
        didReloadItemAtIndexHandler?(currentItems, indexPaths)
    }
    
    func handleStartSearch(query: String?) {
        currentState.isShowSkeleton = false
    }
    
    func handleFail(error: ProviderError) {
        currentState.isShowSkeleton = false
        switch error {
        case .request(let err):
            currentState.error = IMMentionState.VMError.network(err)
        case .noRecommendResult:
            currentState.error = IMMentionState.VMError.noRecommendResult
        case .noSearchResult:
            currentState.error = IMMentionState.VMError.noResult
        case .none:
            currentState.error = nil
        }
        didReloadDataHandler?(currentItems, currentState)
    }
    
    func handleComplete() {}
    
    func handleLoading(string: String?) {
        currentItems = generateSkeletonItems()
        currentState.searchText = string ?? ""
        currentState.isLoading = true
        didReloadDataHandler?(currentItems, currentState)
    }
    
    func handleRecommendReuslt(_ res: ProviderResult) {
        currentState.error = res.isEmpty ? .noResult: nil
        currentState.isShowSkeleton = false
        currentState.isLoading = false
        currentState.hasMore = res.hasMore
        let items = res.result.flatMap { $0 }
        currentItems = .init(sections: [.init(items: items)])
    }
    
    func handleSearchReuslt(_ res: ProviderResult) {
        currentState.error = res.isEmpty ? .noResult: nil
        currentState.isShowSkeleton = false
        currentState.isLoading = false
        currentState.hasMore = res.hasMore
        let items = res.result.flatMap { $0 }
        currentItems = .init(sections: [.init(items: items)])
    }
    
    private let skeletonItems = Array(repeating: IMPickerOption(), count: 20)
    func generateSkeletonItems() -> IMMentionReuslt {
        currentState.isShowSkeleton = true
        return .init(sections: [.init(items: skeletonItems)])
    }
    
    private func reselectItems() {
        
    }
}
