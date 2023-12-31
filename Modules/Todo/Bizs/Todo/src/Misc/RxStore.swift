//
//  RxStore.swift
//  iOS
//
//  Created by 张威 on 2021/4/25.
//

import RxSwift
import RxCocoa
import LKCommonsLogging

private enum RxStoreLog { }
private let logger = Logger.log(RxStoreLog.self, category: "Lark.Todo.RxStore")

protocol RxStoreAction: LogConvertible { }
protocol RxStoreState { }

class RxStore<State: RxStoreState, Action: RxStoreAction> {

    typealias OnState = (State) -> Void
    typealias ActionCallback = (UserResponse<Void>) -> Void

    /// - Parameters:
    ///   - prevState: 之前的 state
    ///   - action: action
    ///   - callback: 异步的 callback
    /// - Returns: 新的 state
    typealias Reducer = (_ prevState: State, _ action: Action, _ callback: ActionCallback?) -> State

    let name: String
    var state: State { latestState }

    private let stateLock = NSRecursiveLock()
    private let disposeBag = DisposeBag()
    private var latestState: State
    private let stateSubject = ReplaySubject<State>.create(bufferSize: 1)
    private let initializeRelay = BehaviorRelay(value: false)
    private var innerReducer: Reducer?

    /// Initializer
    ///
    /// - parameter name: used for logging
    /// - parameter state: initial state
    init(name: String, state: State) {
        self.name = name
        self.latestState = state
        self.stateSubject.onNext(state)
        self.stateSubject.disposed(by: self.disposeBag)
    }

    func rxInitialized() -> Single<Void> {
        if initializeRelay.value {
            return .just(())
        } else {
            return initializeRelay.filter({ $0 }).take(1).map({ _ in () }).asSingle()
        }
    }

    @discardableResult
    func initialize(_ state: State? = nil) -> Self {
        if let state = state {
            latestState = state
        }
        initializeRelay.accept(true)
        stateSubject.onNext(latestState)
        return self
    }

    @discardableResult
    func registerReducer(_ reducer: @escaping Reducer) -> Self {
        innerReducer = reducer
        return self
    }

    func rxValue<V>(forKeyPath keyPath: WritableKeyPath<State, V>) -> Observable<V> {
        return stateSubject.skipUntil(rxInitialized().asObservable())
            .map({ $0[keyPath: keyPath] })
            .asObservable()
    }

    // MARK: Action

    /// Dispatch Action
    ///
    /// - Parameters:
    ///   - action: 发送 action
    ///   - onState: reduce 产生的新 state，主线程调用
    ///   - onCallback: action 导致的异步回调，主线程调用，并且一定在 onState 后调用
    // nolint: long parameters
    func dispatch(
        _ action: Action,
        onState: OnState? = nil,
        callback: ActionCallback? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        logger.info(
            "RxStore.\(name) dispatchAction: \(action.debugDescription)",
            file: file,
            function: function,
            line: line
        )
        guard initializeRelay.value else {
            logger.assertError(false, "you should not dispatch action before initialized")
            return
        }
        guard let reducer = innerReducer else {
            logger.assertError(false, "reducer is missing")
            return
        }
        stateLock.lock()
        defer { stateLock.unlock() }
        var onStateCalled = false
        var resThatsNeedsCallback: UserResponse<Void>?
        var callbackWrapper: ActionCallback?
        if let callback = callback {
            callbackWrapper = { res in
                self.executeInMain {
                    guard onStateCalled else {
                        resThatsNeedsCallback = res
                        return
                    }
                    callback(res)
                }
            }
        }
        let newState = reducer(latestState, action, callbackWrapper)
        latestState = newState
        stateSubject.onNext(latestState)
        executeInMain {
            onState?(newState)
            onStateCalled = true
            if let res = resThatsNeedsCallback {
                callback?(res)
            }
        }
    }
    // enable-lint: long parameters
    @discardableResult
    func setState(_ state: State) -> Self {
        stateLock.lock()
        defer { stateLock.unlock() }
        latestState = state
        stateSubject.onNext(latestState)
        return self
    }

    private func executeInMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }

}
