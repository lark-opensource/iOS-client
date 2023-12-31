//
//  DiffDataSource.swift
//  AnimatedTabBar
//
//  Created by huangshun on 2019/10/26.
//

import Foundation
import RxSwift
import Action
import ByteViewCommon

struct DiffDataSourceDebug {
    static let logger = Logger.tab
}

protocol DiffDataProtocol {
    associatedtype Match: Equatable
    associatedtype Sort: Comparable

    var matchKey: Match { get }
    var sortKey: Sort { get }
}

extension Array where Element: DiffDataProtocol {

    var ids: String {
        if isEmpty { return "null" }
        return map { "\($0.matchKey)" }.joined(separator: ", ")
    }

    var keys: String {
        if isEmpty { return "null" }
        return map { "\($0.sortKey)" }.joined(separator: ", ")
    }

    func filterDuplicates() -> [Element] {
        var result: [Element] = []
        for value in self {
            let key = value.matchKey
            let matchs = result.map { $0.matchKey }
            if !matchs.contains(key) {
                result.append(value)
            }
        }
        return result
    }
}

class DiffDataSource<T: DiffDataProtocol> {

    enum UpdateEvent {
        case add([T])
        case update([T])
        case remove([T.Match])
    }

    enum LoadType {
        case first
        case refresh
        case more
    }

    enum DataResult {
        case loadResults([T], Bool)
        case loadError([T], Error)
        case eventResults([T])
        case loadingResults([T])
    }

    enum Order {
        case desc
        case asc
    }

    private enum Source {
        case push(UpdateEvent, Bool)
        case pull(UpdateEvent, Bool)
        case prePull(UpdateEvent)
        case error(Error)
    }

    private let output: PublishSubject<DataResult> = PublishSubject()

    private let trigger: PublishSubject<LoadType> = PublishSubject()

    @RwAtomic
    private var data: [T] = []

    @RwAtomic
    private var preData: [T] = []

    private var dispose = DisposeBag()

    private var increasingOrder: (T, T) -> Bool = { $0.sortKey >= $1.sortKey }

    init(eventObservable: Observable<UpdateEvent>,
         loader: Action<T?, ([T], Bool)>,
         preLoader: Action<T?, ([T], Bool)>? = nil,
         sort: Order = .desc) {
        self.bindObservable(eventObservable, loader: loader, preLoader: preLoader)
        if sort == .asc { self.increasingOrder = { $0.sortKey <= $1.sortKey } }
    }

    func reset(eventObservable: Observable<UpdateEvent>,
               loader: Action<T?, ([T], Bool)>,
               preLoader: Action<T?, ([T], Bool)>? = nil) {
        DiffDataSourceDebug.logger.debug("\(T.self): reset")
        bindObservable(eventObservable, loader: loader, preLoader: preLoader)
    }

    func force(isPreLoad: Bool = false) {
        DiffDataSourceDebug.logger.debug("\(T.self): force")
        if isPreLoad {
            loadNext.onNext(.first)
        } else {
            loadNext.onNext(.refresh)
        }
    }

    func loadMore() {
        DiffDataSourceDebug.logger.debug("\(T.self): load more")
        loadNext.onNext(.more)
    }

    private func bindObservable(_ eventObservable: Observable<UpdateEvent>,
                                loader: Action<T?, ([T], Bool)>,
                                preLoader: Action<T?, ([T], Bool)>?) {
        DiffDataSourceDebug.logger.debug("\(T.self): bind observer")
        // 接触上一次绑定
        let updatePublish: PublishSubject<Source> = PublishSubject()
        var force: Bool = false
        dispose = DisposeBag()
        data.removeAll()

        // 绑定动态更新
        eventObservable.map { Source.push($0, force) }
            .bind(onNext: updatePublish.onNext)
            .disposed(by: self.dispose)

        // 下一页逻辑
        trigger.observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .flatMapLatest { [weak self] loadType -> Observable<Source> in
                guard let self = self else {
                    return .empty()
                }
                if loadType == .first {
                    if let preLoader = preLoader {
                        return Observable.concat(
                            preLoader.workFactory(nil)
                                .map { .prePull(.add($0.0)) },
                            loader.workFactory(nil)
                                .do(onNext: {
                                    force = !$0.1
                                    self.data.removeAll()
                                }, onError: { _ in force = false })
                                .map {
                                    .pull(.add($0.0), $0.1)
                                }
                        ).catchError { .just(.error($0)) }
                    } else {
                        return loader.workFactory(nil)
                            .do(onNext: {
                                force = !$0.1
                                self.data.removeAll()
                            }, onError: { _ in force = false })
                            .map {
                                .pull(.add($0.0), $0.1)
                            }
                            .catchError { .just(.error($0)) }
                    }
                } else if loadType == .refresh {
                    return loader.workFactory(nil)
                        .do(onNext: {
                            force = !$0.1
                            self.data.removeAll()
                        }, onError: { _ in force = false })
                        .map {
                            .pull(.add($0.0), $0.1)
                        }
                        .catchError { .just(.error($0)) }
                } else {
                    return loader.workFactory(self.data.last)
                        .do(onNext: { force = !$0.1 }, onError: { _ in force = false })
                        .map {
                            .pull(.add($0.0), $0.1)
                        }
                        .catchError { .just(.error($0)) }
                }
            }
            .bind(onNext: updatePublish.onNext)
            .disposed(by: self.dispose)

        // 同步操作数组
        updatePublish.concatMap { [weak self] source -> Observable<DataResult> in
            guard let self = self else { return .empty() }
            return self.catchDatas(source)
        }
        .bind(onNext: output.onNext)
        .disposed(by: dispose)
    }

    private func catchDatas(_ source: Source) -> Observable<DataResult> {
        return Observable<DataResult>.create { [weak self] observer -> Disposable in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            switch source {
            case let .push(event, force):
                DiffDataSourceDebug.logger.debug("\(T.self): source push")
                observer.onNext(.eventResults(self.mergeDatas(event, force: force)))
            case let .prePull(event):
                DiffDataSourceDebug.logger.debug("\(T.self): source prePull")
                observer.onNext(.loadingResults(self.preDatas(event)))
            case let .pull(event, hasMore):
                DiffDataSourceDebug.logger.debug("\(T.self): source pull")
                observer.onNext(.loadResults(self.mergeDatas(event, force: true), hasMore))
            case let .error(error):
                DiffDataSourceDebug.logger.debug("\(T.self): source error: \(self.data.ids)")
                observer.onNext(.loadError(self.data, error))
            }

            observer.onCompleted()
            return Disposables.create()
        }
    }

    func preDatas(_ event: UpdateEvent) -> [T] {
        preData.removeAll()
        if case let .add(elements) = event {
            preData = elements
        } else {
            assert(false, "preLoad action should not have any non-adding event!")
        }
        return preData
    }

    func mergeDatas(_ event: UpdateEvent, force: Bool) -> [T] {
        switch event {
        case let .add(elements): return addElements(elements, force: force)
        case let .remove(elements): return removeElements(elements)
        case let .update(elements): return updateElements(elements)
        }
    }

    func addElements(_ elements: [T], force: Bool) -> [T] {
        let elements = elements.filterDuplicates()
        DiffDataSourceDebug.logger.debug(
            """
            \(T.self):
            add elements ids: \(elements.ids)
            keys: \(elements.keys)
            current elemnts ids: \(data.ids)
            keys: \(data.keys)
            force: \(force)
            """
        )
        defer {
            DiffDataSourceDebug.logger.debug(
                """
                \(T.self):
                end data ids: \(data.ids)
                keys: \(data.keys)
                """
            )
        }
        if force {
            return mergeElements(elements)
        } else {
            return mergeIncreasingElements(elements)
        }
    }

    // 删除元素
    func removeElements(_ elementKeys: [T.Match]) -> [T] {
        DiffDataSourceDebug.logger.debug(
            """
            \(T.self):
            remove elementKeys ids: \(elementKeys)
            current elemnts ids: \(data.ids)
            keys: \(data.keys)
            """)
        defer {
            DiffDataSourceDebug.logger.debug(
                """
                \(T.self):
                end data ids: \(data.ids)
                keys: \(data.keys)
                """
            )
        }
        var curret = data
        curret = curret.filter { !elementKeys.contains($0.matchKey) }
        curret.sort(by: increasingOrder)
        data = curret
        return data
    }

    func updateElements(_ elements: [T]) -> [T] {
        DiffDataSourceDebug.logger.debug(
            """
            \(T.self):
            update elements ids: \(elements.ids)
            keys: \(elements.keys)
            current elemnts ids: \(data.ids)
            keys: \(data.keys)
            """)
        defer {
            DiffDataSourceDebug.logger.debug(
                """
                \(T.self):
                end data ids: \(data.ids)
                keys: \(data.keys)
                """
            )
        }
        return mergeIncreasingElements(elements)
    }

    // 增加元素, 删除重叠元素然后增加新元素
    func mergeElements(_ elements: [T]) -> [T] {
        if elements.isEmpty { return data }
        let elementKeys = elements.map { $0.matchKey }
        var current = data
        current = current.filter { !elementKeys.contains($0.matchKey) }
        current.append(contentsOf: elements)
        current.sort(by: increasingOrder)
        data = current
        return data
    }

    // 更新元素,
    // 1. 更新: 找到交集并且删除然后增加交集
    // 2. 增加: 如果补集中的元素sort比当前数组中最后一个元素大则插入
    func mergeIncreasingElements(_ elements: [T]) -> [T] {
        var current = data

        let elementKeys = elements.map { $0.matchKey }
        let currentKeys = current.map { $0.matchKey }

        // 交集
        let intersectionKeys = elementKeys.filter(currentKeys.contains)
        let intersectionElements = elements.filter { intersectionKeys.contains($0.matchKey) }
        current = current.filter { !intersectionKeys.contains($0.matchKey) }
        current.append(contentsOf: intersectionElements)

        // 补集
        let complementaryKeys = elementKeys.filter { !intersectionKeys.contains($0) }
        let complementaryElements = elements.filter { complementaryKeys.contains($0.matchKey) }
        if let lastElement = current.last {
            for element in complementaryElements where increasingOrder(element, lastElement) {
                current.append(element)
            }
        }
        current.sort(by: increasingOrder)
        data = current
        return data
    }

    var loadNext: AnyObserver<LoadType> {
        return trigger.asObserver()
    }

    var result: Observable<DataResult> {
        return output.asObservable()
    }

    var current: [T] {
        return data
    }
}
