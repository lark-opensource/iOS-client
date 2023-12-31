//
//  SearchListVM.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/6/4.
//

import Foundation
import LKCommonsLogging
import LarkModel
import RxSwift
import LarkSDKInterface
import LarkSearchFilter

public struct SearchArgs {
    public var query: String
    public var filters: [SearchFilter]
    public var context: SearchRequestContext
}
private let logger = Logger.log(SearchListVM<SearchItem>.self, category: "Search")
/// represent a single list of SearchViewModel
public final class SearchListVM<Item> {
    public typealias State = SearchListState<Item>
    public typealias Event = SearchListEvent<Item>
    // 所有可变状态应该在这个专有queue上使用
    private let queue: DispatchQueue = DispatchQueue(label: "SearchListVM", target: DispatchQueue.global())

    private var _state = State()
    public var state: State { queue.sync { _state } }
    /// replace this to cancel previous request
    private var requestToken: Disposable? {
        didSet {
            oldValue?.dispose()
        }
    }
    /// 用于串行异步请求，判断请求结果和当前request一致
    private var currentRequestID: UInt16 = 0

    // 所有不可变属性读取
    public let source: SearchSource
    public let pageCount: Int
    /// return true means query should treat as a clear request, and reset all state to init
    public var shouldClear: (SRequestInfo) -> Bool
    /// transform SearchItem to the required CellVM. or return nil to filter it.
    public let compactMap: (SearchItem) -> Item?

    public static func defaultCompactMap(item: SearchItem) -> Item? {
        if let item = item as? Item {
            return item
        }
        assertionFailure("Source result should be the specified type!")
        return nil
    }
    // https://slardar.bytedance.net/node/app_detail/?aid=1378&os=iOS&region=cn&lang=zh-Hans#/abnormal/detail/crash/1378_5ce0bc1a6a7464bea1fe7125c4f105fe?params=%7B%22start_time%22%3A1597564020%2C%22end_time%22%3A1597650420%2C%22granularity%22%3A3600%2C%22order_by%22%3A%22user_descend%22%2C%22pgno%22%3A1%2C%22pgsz%22%3A10%2C%22crash_time_type%22%3A%22insert_time%22%2C%22anls_dim%22%3A%5B%22device_model%22%2C%22channel%22%2C%22last_scene%22%2C%22os_version%22%2C%22update_version_code%22%5D%2C%22event_index%22%3A1%2C%22filters_conditions%22%3A%7B%22type%22%3A%22and%22%2C%22sub_conditions%22%3A%5B%7B%22dimension%22%3A%22app_version%22%2C%22op%22%3A%22in%22%2C%22values%22%3A%5B%223.29.2%22%5D%7D%5D%7D%7D
    // 和齐鸿叶讨论后，有可能是因为范型初始化线程不安全，所以提前init一下
    // 简单这样访问一下不行。每个具体类型都访问一下试试？
    @inline(never)
    static private var fixGenericInitBug: AnyKeyPath { \State.results }
    /// - Parameters:
    ///   - source: the search source to get search results
    ///   - shouldClear: the function to decide if query should clear the search. default return true for empty request
    ///   - compactMap: transform SearchItem to the required CellVM. or return nil to filter it. default is force cast.
    ///     NOTE: compactMap called in private Queue.
    public init(source: SearchSource, pageCount: Int = 15,
                shouldClear: @escaping (SRequestInfo) -> Bool = { $0.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
                compactMap: @escaping (SearchItem) -> Item? = defaultCompactMap(item:)
                ) {
        _ = Self.fixGenericInitBug
        self.source = source
        self.pageCount = pageCount
        self.shouldClear = shouldClear
        self.compactMap = compactMap
    }
    /// this version. force cast source item to model type, and then call the compactMap
    /// see also desiganate init
    public convenience init<Model: SearchItem>(source: SearchSource, pageCount: Int = 15,
                shouldClear: @escaping (SRequestInfo) -> Bool = { $0.query.isEmpty },
                compactMap: @escaping (Model) -> Item?
                ) {
        self.init(source: source, pageCount: pageCount, shouldClear: shouldClear) { (item: SearchItem) -> Item? in
            guard let item = item as? Model else {
                assertionFailure("Source result should be the specified type!")
                return nil
            }
            return compactMap(item)
        }
    }
    deinit {
        requestToken = nil
    }

    // NOTE: 基于事件的处理耦合太严重，一个事件可能改变多个状态。不利于兼容性。
    // 所以监听端还是应该以状态为主做相应的绑定处理，事件里只有事件相关的一次性信息
    public struct StateChange {
        /// current state for this change event
        public var state: State
        /// changed state key for this event
        /// when nil, should refresh all state, like a init binding.
        var changes: Set<PartialKeyPath<State>>?
        /// event tip for this state change
        public var event: Event
        /// return true if this keyPath has changes, when changes nil(first set), return true
        public func hasChange(keyPath: PartialKeyPath<State>) -> Bool {
            changes?.contains(keyPath) != false
        }
        /// return new value if this KeyPath has changes, else nil
        public func newValue<V>(keyPath: KeyPath<State, V>) -> V? {
            return hasChange(keyPath: keyPath) ? state[keyPath: keyPath] : nil
        }
    }

    /// 封装State更新并标记修改的属性
    private struct Changer {
        var base: SearchListVM
        var changes: Set<PartialKeyPath<State>> = []
        var fullChange = false

        mutating func update<V>(keyPath: WritableKeyPath<State, V>, value: V) {
            base._state[keyPath: keyPath] = value
            changes.update(with: keyPath)
        }
        mutating func update(moreToken: Any?) {
            base._state.moreToken = moreToken
            changes.update(with: \State.moreToken)
            changes.update(with: \State.hasMore)
        }
        var publishChanges: Set<PartialKeyPath<State>>? {
            if fullChange { return nil }
            return changes
        }
    }
    /// State变化后都应该通过这个发出Patch
    private let statePublisher = PublishSubject<StateChange>()
    /// modifier state, and auto publish change event. use this function to modify state and to avoid forget publish
    private func modifyState(action: (inout Changer) -> Event?) {
        #if DEBUG
        dispatchPrecondition(condition: DispatchPredicate.onQueue(queue))
        #endif
        var changer = Changer(base: self)
        if let event = action(&changer) {
            statePublisher.on(.next(StateChange(
                state: _state, changes: changer.publishChanges, event: event)))
        }
    }

    /// subscribe时通知当前状态(full), 之后通知新状态和相应导致变化的原因
    public var stateObservable: Observable<StateChange> {
        return Observable.create { [weak self](observer) in
            guard let self = self else {
                observer.on(.completed)
                return Disposables.create()
            }
            let disposables = SingleAssignmentDisposable()
            self.queue.async {
                /// NOTE: 需要保证初始状态和Publiser的patch事件的原子性，避免遗漏patch事件.
                observer.on(.next(StateChange(
                    state: self._state, changes: nil, event: .full)))
                disposables.setDisposable( self.statePublisher.subscribe(observer) )
            }
            return disposables
        }
    }
    public var resultsObservable: Observable<[Item]> {
        stateObservable.compactMap { change in
            if !change.hasChange(keyPath: \State.results) {
                return nil
            } else { // nil, true, 包含results变化
                return change.state.results
            }
        }
    }
    public var stateCaseObservable: Observable<SearchListStateCases> {
        stateObservable.compactMap { change in
            if !change.hasChange(keyPath: \State.state) {
                return nil
            } else { // nil, true, 包含results变化
                return change.state.state
            }
        }
    }
    public var hasMoreObservable: Observable<Bool> {
        stateObservable.compactMap { change in
            if !change.hasChange(keyPath: \State.hasMore) {
                return nil
            } else { // nil, true, 包含results变化
                return change.state.hasMore
            }
        }.distinctUntilChanged()
    }

    public var stateObservableInMain: Observable<StateChange> { stateObservable.observeOn(MainScheduler.asyncInstance) }
    public var resultsObservableInMain: Observable<[Item]> { resultsObservable.observeOn(MainScheduler.asyncInstance) }
    public var stateCaseObservableInMain: Observable<SearchListStateCases> { stateCaseObservable.observeOn(MainScheduler.asyncInstance) }
    public var hasMoreObservableInMain: Observable<Bool> { hasMoreObservable.observeOn(MainScheduler.asyncInstance) }

    // MARK: - Action API
    // TODO: 打点相关集成

    /// 执行search操作, 并更新状态
    public func search(query: String, filters: [SearchFilter] = [], context: SearchRequestContext = SearchRequestContext()) {
        /// 请求策略：
        /// 所有请求为异步串行.
        /// reload可以cancel之前的请求
        /// loadmore时已有请求会忽略

        let req = SRequestInfo(query: query, filters: filters, context: context, isLoadMore: false)
        let shouldClear = self.shouldClear(req)
        queue.async {
            if shouldClear {
                self.currentRequestID &+= 1
                self.requestToken = nil
                self.modifyState {
                    self._state.reset()
                    $0.fullChange = true
                    return .full
                }
                return
            }
            self._request(req)
        }
    }

    /// 执行加载更多
    public func loadMore() {
        let start = Date()
        queue.async {
            // loading时不加载更多
            guard self._state.state == .normal, let last = self._state.lastestRequest else { return }
            let req = SRequestInfo(query: last.query, filters: last.filters, context: last.context, isLoadMore: true, startTime: start)
            self._request(req)
        }
    }

    private func _request(_ req: SRequestInfo) {
        self.currentRequestID &+= 1
        let requestID = self.currentRequestID
        let request = BaseSearchRequest(query: req.query, filters: req.filters, count: pageCount,
                                        moreToken: req.isLoadMore ? _state.moreToken : nil,
                                        context: req.context)
        modifyState {
            if req.isLoadMore {
                $0.update(keyPath: \.state, value: .loadingMore)
            } else {
                $0.update(keyPath: \.state, value: .reloading)
                // reload时清空results数据。可能需要配置开关
                $0.update(moreToken: nil)
                $0.update(keyPath: \.results, value: [])
                _state.rawResults = []
                $0.update(keyPath: \.lastestRequest, value: SearchArgs(query: req.query, filters: req.filters, context: req.context))
            }
            return .loading(req: req)
        }

        var hasResponse = false
        requestToken = source.search(request: request).subscribe { [weak self] (event) in
            self?.queue.async {
                guard let self = self, requestID == self.currentRequestID else {
                    return
                }
                func additionalData(contextID: String? = nil) -> [String: String] {
                    var v = [ "query": req.query.lf.dataMasking, "source": "\(self.source)" ]
                    if let contextID = contextID {
                        v["contextID"] = contextID
                    }
                    return v
                }
                func handle(error: Error) {
                    logger.warn("[LarkSearch] search result failed", additionalData: additionalData(), error: error)
                    self.modifyState {
                        $0.update(keyPath: \.state, value: .normal)
                        return .fail(req: req, error: error)
                    }
                }

                switch event {
                case .next(let response):
                    if hasResponse {
                        // TODO: 多次回调支持
                        assertionFailure("not support multiple response")
                        return
                    }
                    hasResponse = true
                    self.modifyState { changer in
                        changer.update(moreToken: response.moreToken)
                        changer.update(keyPath: \.hasMore, value: response.hasMore)
                        changer.update(keyPath: \.state, value: .normal)

                        // 根据identifier去重
                        var saw = Set<String>(minimumCapacity: response.results.count + self._state.rawResults.count)
                        saw.formUnion(self._state.rawResults.compactMap { $0.identifier })

                        let rawResults = response.results.filter {
                            if let identifier = $0.identifier {
                                return saw.insert(identifier).inserted
                            }
                            return true // 没有identifier的保留
                        }
                        let results = rawResults.compactMap(self.compactMap)
                        if (response.results.count - results.count) > 0 {
                            logger.info("[LarkSearch] results filtered from \(response.results.count) to \(rawResults.count) to \(results.count)",
                                        additionalData: additionalData(contextID: response.context[SearchResponseContextID.self]))
                        } else {
                            logger.info("[LarkSearch] results: \(results.count) isMore: \(req.isLoadMore)",
                                        additionalData: additionalData(contextID: response.context[SearchResponseContextID.self]))
                        }

                        if req.isLoadMore {
                            self._state.results.append(contentsOf: results)
                            changer.changes.update(with: \State.results)
                            self._state.rawResults.append(contentsOf: rawResults)
                            return .success(req: req, appending: results)
                        } else {
                            changer.update(keyPath: \.lastestRequest, value: SearchArgs(query: req.query, filters: req.filters, context: req.context))
                            changer.update(keyPath: \.results, value: results)
                            self._state.rawResults = rawResults
                            return .success(req: req, appending: nil)
                        }
                    }
                case .completed:
                    // completed before next is a error..
                    if !hasResponse {
                        assertionFailure("should return response before complete!")
                        handle(error: NoResponse())
                    }
                case .error(let error):
                    handle(error: error)
                @unknown default:
                    fatalError("unknown RxSwift cases")
                }
            }
        }
    }
}

public enum SearchListStateCases { // swiftlint:disable:this all
    /// 初始状态，无请求无数据. reset后也会进入这个状态。一般用于显示placeholder页面
    case empty
    /// 正常状态, 可以获取results. 加载结束时返回该状态。搜索无结果是normal而不是empty
    case normal
    /// 加载状态, 可从任意状态进入, 包括取消loadingMore
    case reloading
    /// 加载更多, 可从normal状态进入
    case loadingMore
}
/// public State need to observe by UI, should immutatble for UI
/// this struct keep all list items and loading state
public struct SearchListState<Item> {
    var rawResults: [SearchItem] = []
    public var results: [Item] = []
    public var state: SearchListStateCases = .empty

    var moreToken: Any?
    public var hasMore: Bool = true
    // state may pass other VM to restore search.. so save the lastestRequest
    /// lastestRequest args for get the results
    public fileprivate(set) var lastestRequest: SearchArgs?

    mutating func reset() {
        rawResults = []
        results = []
        moreToken = nil
        state = .empty
        lastestRequest = nil
    }
}
/// the event make the state change. used as state change tips
public enum SearchListEvent<Item> {
    /// 完全刷新, 初始化, 其它未知事件。需要根据状态完全刷新UI
    case full
    /// 切换loading状态，不影响数据. 是否加载更多可以从SearchListState.state里取到
    case loading(req: SRequestInfo)
    /// 加载成功. State返回Normal状态
    /// 当有appending时，表示该次修改，appending的内容可以直接拼在旧state.results后面
    case success(req: SRequestInfo, appending: [Item]?)
    /// 加载失败，State返回Normal状态
    case fail(req: SRequestInfo, error: Error)

    var requestInfo: SRequestInfo? {
        switch self {
        case let .loading(req), let .success(req: req, appending: _), let .fail(req: req, error: _):
            return req
        default:
            return nil
        }
    }
}
public struct SRequestInfo {
    public var query: String
    public var filters: [SearchFilter]
    public var context: SearchRequestContext
    public var isLoadMore: Bool
    public var startTime = Date()
}

private struct NoResponse: Error {}
