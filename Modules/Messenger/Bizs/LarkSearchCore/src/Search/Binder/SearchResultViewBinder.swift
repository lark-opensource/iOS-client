//
//  SearchResultViewBinder.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/6/12.
//

import Foundation
import LarkCore
import RxSwift
import LKCommonsLogging
import LKCommonsTracker
import Homeric

enum SearchBinder {
    static let logger = Logger.log(SearchBinder.self, category: "Module.IM.Search")
}

/// delegate method for customize ResultView binding
/// it should according to the listvm state, update results and UI.
/// and most methods have default implement.
public protocol SearchResultViewListBindDelegate: AnyObject {
    /// NOTE: 推荐在VM中compactMap数据到CellVM, 而不是做事后处理
    associatedtype Item
    associatedtype CellVM = Item
    typealias ListVM = SearchListVM<Item>

    var resultView: SearchResultView { get }
    var listvm: ListVM { get }

    var listState: SearchListStateCases? { get set }
    var results: [CellVM] { get set }

    /// optional: entry function for bind event.
    /// can subscribe and pass state change to this event, to convert call back format
    func on(change: SearchListVM<Item>.StateChange)
    /// called by on(change), for results change. eg: may be called when reloading or load success
    func on(state: ListVM.State, results: [Item], event: ListVM.Event)
    func searchReceiveResult(state: ListVM.State, results: [Item], event: ListVM.Event)
    func makeViewModel(item: Item) -> CellVM?

    /// should implement to show a placeholder page. normal called when empty query. default hide result view
    func showPlaceholder(state: ListVM.State)
    /// should implement the reverse, called when reloading, which is the first state enter from empty state
    func hidePlaceholder(state: ListVM.State)

    /// for track search event
    var searchLocation: String { get }
}

public extension SearchResultViewListBindDelegate {
    func searchReceiveResult(state: ListVM.State, results: [Item], event: ListVM.Event) {}
    // TODO: 参数都放到protocol里作为环境透传了，不应该在这里再传
    func bindResultView() -> Disposable {
        return listvm.stateObservableInMain.subscribe(onNext: { [weak self] (element) in
            self?.on(change: element)
        })
    }

    func on(change: SearchListVM<Item>.StateChange) {
        Self.on(self, change: change)
    }
    static func on(_ delegate: Self, change: ListVM.StateChange) {
        // 优先更新results, 因为之后set status，需要判断是否no result. 这个可能会有过滤
        if change.hasChange(keyPath: \ListVM.State.results) {
            delegate.on(state: change.state, results: change.state.results, event: change.event)
        }
        delegate.searchReceiveResult(state: change.state, results: change.state.results, event: change.event)

        listState: if change.hasChange(keyPath: \ListVM.State.state) {
            // state cases变化时一般其它状态也会一起变化，所以一起处理了
            let state = change.state
            let oldValue = delegate.listState
            delegate.listState = state.state
            // 保证调用old相关调用时listState已经切换到新值，对应属性didSet方法
            // SearchChatPickerViewController等混用TableView的依赖listState判断显示默认页
            if let old = oldValue {
                if old == state.state { break listState }

                switch old {
                case .empty:       delegate.hidePlaceholder(state: state)
                case .reloading:   delegate.hideReloading(state: state, req: change.event.requestInfo)
                case .loadingMore: delegate.hideLoadingMore(state: state, req: change.event.requestInfo)
                default: break
                }
            }
            switch state.state {
            case .empty:
                assert(state.results.isEmpty)
                delegate.showPlaceholder(state: state)
            case .reloading:   delegate.showReloading(state: state, req: change.event.requestInfo)
            case .loadingMore: delegate.showLoadingMore(state: state, req: change.event.requestInfo)
            case .normal:      delegate.showNormal(state: state, event: change.event)
            // @unknown default: break
            }
        }
        // hasMore在state变化中直接处理. FIXME: 有可能只有result和hasMore变化而没有state变化？
    }
    func on(state: ListVM.State, results: [Item], event: ListVM.Event) {
        Self.on(self, state: state, results: results, event: event)
    }
    static func on(_ delegate: Self, state: ListVM.State, results: [Item], event: ListVM.Event) {
        let `self` = delegate
        if !self.results.isEmpty, case .success(req: _, appending: let appending?) = event {
            /// 加载更多的场景，仅转换appending的
            self.results.append(contentsOf: self.convert(results: appending))
        } else {
            self.results = self.convert(results: results)
        }
        self.resultView.tableview.reloadData()
    }

    /// 默认隐藏ResultView, 如果Placeholder页在ResultView下面，那就会显示出来
    func showPlaceholder(state: ListVM.State) {
        self.resultView.isHidden = true
    }
    func hidePlaceholder(state: ListVM.State) {
        self.resultView.isHidden = false
        // Picker 埋点
        SearchTrackUtil.trackPickerSelectSearchMemberView()
    }
    func showReloading(state: ListVM.State, req: SRequestInfo?) {
        self.resultView.status = .loading
    }
    func hideReloading(state: ListVM.State, req: SRequestInfo?) {
        if self.results.isEmpty && state.state == .normal {
            self.resultView.status = .noResult(req?.query ?? "")
        } else {
            self.resultView.status = .result
        }
    }
    func showLoadingMore(state: ListVM.State, req: SRequestInfo?) {
        // TODO: 现在的刷新控件不支持主动触发刷新状态，需要找时间换一个。
    }
    func hideLoadingMore(state: ListVM.State, req: SRequestInfo?) {
        self.resultView.tableview.endBottomLoadMore(hasMore: state.hasMore)
    }
    /// list state back to normal, NOTE: results change and reload should in on results change
    func showNormal(state: ListVM.State, event: ListVM.Event) {
        // NOTE: 可能进入loadingMore状态，但是处于reloading状态而被忽略，所以切换回normal时统一清理
        hideLoadingMore(state: state, req: event.requestInfo)
        switch event {
        case .success(req: let req, appending: _):
            if state.hasMore && self.resultView.tableview.bottomLoadMoreView == nil {
                self.resultView.tableview.addBottomLoadMoreView { [weak self] in
                    self?.listvm.loadMore()
                }
            }
            track(requestTimeInterval: -req.startTime.timeIntervalSinceNow,
                  query: req.query, status: results.isEmpty ? "NO" : "YES")
        case .fail(req: let req, error: _):
            // TODO: 可能需要加上toast的featureGating，现在是类似于直接展示之前的结果
            track(requestTimeInterval: -req.startTime.timeIntervalSinceNow,
                  query: req.query, status: "fail")
        default: break // 其它事件只需要处理results, 已经另外处理了
        }
    }
    func convert(results: [Item]) -> [CellVM] {
        results.compactMap {
            if let vm = makeViewModel(item: $0) {
                return vm
            } else {
                SearchBinder.logger.error("\(type(of: $0)) can't convert to SearchCellVMType for \(self)")
                return nil
            }
        }
    }
    func makeViewModel(item: Item) -> CellVM? {
        item as? CellVM
    }

    // MARK: - Track
    func track(requestTimeInterval: TimeInterval, query: String, status: String) {
        SearchTrackUtil.track(requestTimeInterval: requestTimeInterval,
                              query: query,
                              status: status,
                              location: searchLocation)
    }
}
