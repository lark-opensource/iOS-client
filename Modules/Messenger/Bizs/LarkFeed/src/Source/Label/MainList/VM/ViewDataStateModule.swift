//
//  LabelMainListViewDataStateModule.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/20.
//

import Foundation
import RxSwift
import RxCocoa

/** LabelMainListViewDataStateModule的设计：将data数据转化为可被ui理解的数据
1. 监听dataSource的数据回调，将数据处理成UI数据
2. 记录跟UI相关的数据状态，比如选中、展开收起
3. 面向UI，提供数据接口
*/

final class LabelMainListViewDataStateModule {
    enum State: Int {
        case loading,
             loaded,
             error
    }

    enum Render {
        case none,
             fullReload,
             reloadSection(Int)
    }

    enum Empty {
        case none,
             main,
             subLevel
    }

    private let dataModule: LabelMainListDataModule
    private let switchModeModule: SwitchModeModule
    private(set) var uiStore: DataStoreInterface
    private var loadingMap: [Int: Bool] = [:]

    private let renderRelay = BehaviorRelay<LabelMainListDataState.ExtraInfo>(value: LabelMainListDataState.ExtraInfo.default())
    var renderObservable: Observable<LabelMainListDataState.ExtraInfo> {
        return renderRelay.asObservable()
    }

    private let stateRelay = BehaviorRelay<LabelMainListViewDataStateModule.State>(value: .loading)
    var stateObservable: Observable<LabelMainListViewDataStateModule.State> {
        return stateRelay.asObservable().distinctUntilChanged()
    }

    var emptyObservable: Observable<LabelMainListViewDataStateModule.Empty> {
        return renderObservable.map({ [weak self] _ -> LabelMainListViewDataStateModule.Empty in
            guard let self = self else { return .none }
            // 一级标签列表数据为空,则展示全局空视图
            if self.sectionCount <= 0 {
                return .main
            }
            // 选中的二级标签数据为空，则展示二级空视图
            if case .threeBarMode(let labelId) = self.switchModeModule.mode,
               self.uiStore.getFeeds(labelId: labelId).isEmpty {
                return .subLevel
            }
            // 其余情况，不展示任何空视图
            return .none
        }).distinctUntilChanged()
    }

    private let disposeBag = DisposeBag()
    init(dataModule: LabelMainListDataModule,
         switchModeModule: SwitchModeModule) {
        self.dataModule = dataModule
        self.switchModeModule = switchModeModule
        self.uiStore = LabelMainListDataStore()
        setup()
    }

    private func setup() {
        dataModule.dataObservable
            .map({ [weak self] storeInfo -> LabelMainListDataState.StoreInfo in
                guard let self = self else { return storeInfo }
                switch self.switchModeModule.mode {
                case .standardMode:
                    return storeInfo
                case .threeBarMode(let labelId):
                    let uiStore = storeInfo.store.filter({ $0.item.id == labelId })
                    let info = LabelMainListDataState.StoreInfo(store: uiStore, extraInfo: storeInfo.extraInfo)
                    return info
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] storeInfo in
                guard let self = self else { return }
                self.uiStore = storeInfo.store
                self.renderRelay.accept(storeInfo.extraInfo)
        }).disposed(by: disposeBag)

        dataModule.fetcher.stateObservable
            .subscribe(onNext: { [weak self] state in
                let viewDataState: LabelMainListViewDataStateModule.State
                switch state {
                case .idle:
                    viewDataState = .loading
                case .loading:
                    viewDataState = .loading
                case .loaded:
                    viewDataState = .loaded
                case .error:
                    viewDataState = .error
                }
                self?.stateRelay.accept(viewDataState)
        }).disposed(by: disposeBag)
    }
}

// MARK: UI刷新完成
extension LabelMainListViewDataStateModule {
    // TODO: loadingMap的读取不在一处；遇到getError时，并不会完成闭环
    func renderFinish(dataFrom: LabelMainListDataState.DataFrom) {
        switch dataFrom {
        case .none: break
        case .loadMoreFeed(let labelId):
            loadingMap[labelId] = false
        }
    }
}

// MARK: 对外提供UI数据
extension LabelMainListViewDataStateModule {
    var sectionCount: Int {
        return uiStore.indexData.childIndexList.count
    }

    func count(in section: Int) -> Int {
        return uiStore.indexData.getChildIndexData(index: section)?.childIndexList.count ?? 0
    }

    func getFeed(indexPath: IndexPath) -> LabelFeedViewModel? {
        return uiStore.getFeed(indexPath: indexPath)
    }

    func getLabel(section: Int) -> LabelViewModel? {
        return uiStore.getLabel(index: section)
    }

    var displayFooter: Bool {
        var display = sectionCount > 0
        switch switchModeModule.mode {
        case .standardMode:
            break
        case .threeBarMode(_):
            display = false
        }
        return display
    }
}

// MARK: 分页触发
extension LabelMainListViewDataStateModule {
    func loadFeeds(labelId: Int, index: Int) {
        // TODO: loadMore机制待优化
        let loading = loadingMap[labelId] ?? false
//        let buffer = 15
//        let ready = index >= (self.uiStore.indexData.count - buffer)
        let ready = true // 这个字段暂时用不到
        guard let labelIndexData = self.uiStore.indexData.getChildIndexData(id: labelId) else { return }
        let _hasMore: Bool
        let _nextCursor: IndexCursor?
        if let hasMore = labelIndexData.hasMore, let nextCursor = labelIndexData.nextCursor {
            _hasMore = hasMore
            _nextCursor = nextCursor
        } else {
            _hasMore = true
            _nextCursor = nil
        }
        let result = ready && (!loading) && _hasMore
        guard result else { return }
        loadingMap[labelId] = true
        self.dataModule.fetcher.loadMoreFeed(labelId: labelId, nextCursor: _nextCursor, orderBy: self.uiStore.getLabelRequestSortRule(labelId))
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
        }, onError: { [weak self] _ in
            self?.loadingMap[labelId] = false
        }).disposed(by: disposeBag)
    }
}
