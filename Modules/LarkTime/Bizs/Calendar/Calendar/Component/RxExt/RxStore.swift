//
//  RxStore.swift
//  Calendar
//
//  Created by 张威 on 2020/7/28.
//

import RxSwift
import LKCommonsLogging

private enum RxStoreLog { }
private let logger = Logger.log(RxStoreLog.self, category: "calendar.rxStore")

final class RxStore<State: CustomDebugStringConvertible, Action: CustomDebugStringConvertible> {

    let disposeBag = DisposeBag()
    let name: String

    typealias StateReducer<V> = (
        _ previousState: State,
        _ keyPath: WritableKeyPath<State, V>,
        _ value: V
    ) -> State

    private let stateLock = NSRecursiveLock()
    private var latestState: State
    private let stateSubject = ReplaySubject<State>.create(bufferSize: 1)

    private let actionSubject = PublishSubject<(Action, CaVCLoggerModel)>()

    /// Initializer
    ///
    /// - parameter name: used for logging
    /// - parameter state: initial state
    init(name: String, state: State) {
        self.name = name
        self.latestState = state
        self.stateSubject.onNext(state)
        self.stateSubject.disposed(by: self.disposeBag)
        self.actionSubject.disposed(by: self.disposeBag)
    }

    // MARK: State

    var state: State { latestState }

    func rxState() -> Observable<State> {
        return stateSubject.asObservable()
    }

    func rxValue<V>(forKeyPath keyPath: WritableKeyPath<State, V>) -> Observable<V> {
        return stateSubject.map({ $0[keyPath: keyPath] }).asObservable()
    }

    func setState(_ state: State) {
        stateLock.lock()
        defer { stateLock.unlock() }
        latestState = state
        stateSubject.onNext(state)
    }

    func setValue<V>(
        _ value: V,
        forKeyPath keyPath: WritableKeyPath<State, V>,
        reducer: StateReducer<V>? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        stateLock.lock()
        defer { stateLock.unlock() }
        if let reducer = reducer {
            let newState = reducer(latestState, keyPath, value)
            latestState = newState
            stateSubject.onNext(newState)
        } else {
            var newState = latestState
            newState[keyPath: keyPath] = value
            latestState = newState
            stateSubject.onNext(newState)
        }
        logger.info(
            "RxStore.\(name) rxSetValue. value: \(value), keyPath: \(keyPath)",
            file: file,
            function: function,
            line: line
        )
    }

    // MARK: Action

    func responds(handler: @escaping (_ a: Action, _ loggerModel: CaVCLoggerModel) -> Void) -> Disposable {
        let disposable = actionSubject.subscribe(onNext: { handler($0.0, $0.1) })
        disposable.disposed(by: disposeBag)
        return disposable
    }

    func dispatch(
        _ action: Action,
        on scheduler: SchedulerType? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        if let scheduler = scheduler {
            scheduler.schedule((), action: { [weak self] _ in
                // TODO @jack: 后续添加这部分
                self?.actionSubject.onNext((action, .init()))
                return Disposables.create()
            }).disposed(by: disposeBag)
        } else {
            actionSubject.onNext((action, .init()))
        }
        logger.info(
            "RxStore.\(name) dispatchAction. action: \(action.debugDescription)",
            file: file,
            function: function,
            line: line
        )
    }

}
