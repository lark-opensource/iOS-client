//
//  RxStage.swift
//  Calendar
//
//  Created by 张威 on 2020/5/8.
//

import RxSwift
import RxCocoa

/// **RxStage**
///
/// Stage 旨在抽象流程任务的各个阶段，有些类似于 Fastlane 中的 lane，或者 GitHub CI 中的 action。
/// 譬如「保存日程」，可划分为多个阶段：判断日程是否变了、check 参与人数上限、选择 span、填写会议室审批等。
/// 这些阶段任务中，可能涉及网络请求，可能需要用户参与交互，每个阶段可能成功、失败，后者产生互相影响的数据。
/// 就经验而言，如果没有好好抽象，容易生产一些可读性非常差的代码，包括不限于：
///   - 回调地狱
///   - 在 Model 嵌入弹窗逻辑
///
/// 抽象 Stage 的目的是为了让逻辑更清晰简单，将一个繁杂的流程任务细粒度成一个个可以串联在一起的 stage。
///
/// 针对日历的需求场景，每个 stage 可以 forward 两种 item：
///   - state: 描述 stage 的产物，表示 stage 已结束（携带 state 往下走）
///   - message: 描述 stage 抛出的消息
///
/// 每个 stage 可以 deliver 多个 `message`，但只能 complete 一个 state。
///
/// 除了这两种 item，还可以通过 `terminate` 结束整个流程。
///
/// 所谓 stage 抽象，实际上只是对 Rx `flatMap` 的简单包装，逻辑并不复杂。
///

enum ForwardItem<State, Message> {
    /// Stage completed successfully. A state is produced.
    case state(State)

    /// A message is produced.
    case message(Message)
}

final class StageForwarder<State, Message> {

    typealias Element = ForwardItem<State, Message>

    let observer: AnyObserver<Element>
    private let _lock = NSRecursiveLock()
    private var _isStopped = false

    fileprivate init(observer: AnyObserver<Element>) {
        self.observer = observer
    }

    func deliver(_ msg: Message) {
        _lock.lock()
        defer { _lock.unlock() }
        assert(!_isStopped)
        observer.onNext(.message(msg))
    }

    func complete(_ sta: State) {
        _lock.lock()
        defer { _lock.unlock() }
        assert(!_isStopped)
        _isStopped = true
        observer.onNext(.state(sta))
        observer.onCompleted()
    }

    func terminate(_ err: Swift.Error) {
        _lock.lock()
        defer { _lock.unlock() }
        assert(!_isStopped)
        _isStopped = true
        observer.onError(err)
    }

}

extension StageForwarder where State == Void {
    func complete() {
        complete(())
    }
}

final class RxStage<State, Message>: ObservableConvertibleType {

    typealias Element = ForwardItem<State, Message>
    typealias ErrorHandler<NewState> = (Error, StageForwarder<NewState, Message>) -> Disposable

    private typealias Source = Observable<Element>
    private let source: Source

    init(source: Observable<Element>) {
        self.source = source
    }

    func asObservable() -> Observable<Element> {
        return source
    }

    static func create(with builder: @escaping (StageForwarder<State, Message>) -> Disposable) -> Self {
        let source = Source.create { subscriber -> Disposable in
            return builder(StageForwarder(observer: subscriber))
        }
        return Self(source: source)
    }

    static func terminate(_ error: Error) -> Self {
        return Self(source: .error(error))
    }

    static func complete(_ state: State) -> Self {
        return Self(source: .just(.state(state)))
    }

    static func empty() -> Self {
        return Self(source: .empty())
    }

    func joinStage<NewState>(_ mapForwarder: @escaping (State, StageForwarder<NewState, Message>) -> Void)
        -> RxStage<NewState, Message> {
        let newSource = source.flatMap { ele -> RxStage<NewState, Message> in
            let mapSource: Observable<ForwardItem<NewState, Message>>
            switch ele {
            case .message(let msg):
                mapSource = .just(.message(msg))
            case .state(let sta):
                mapSource = .create { subscriber -> Disposable in
                    mapForwarder(sta, StageForwarder(observer: subscriber))
                    return Disposables.create()
                }
            }
            return .init(source: mapSource)
        }
        return .init(source: newSource)
    }

    func joinStage<NewState>(transform: @escaping (State) -> RxStage<NewState, Message>) -> RxStage<NewState, Message> {
        let newSource = source.flatMap { ele -> RxStage<NewState, Message> in
            switch ele {
            case .message(let msg):
                return .init(source: .just(.message(msg)))
            case .state(let sta):
                return transform(sta)
            }
        }
        return .init(source: newSource)
    }

    func catchError(_ handler: @escaping ErrorHandler<State>) -> RxStage<State, Message> {
        let newSource: Observable<Element> = source.catchError { error in
            return .create { subscriber -> Disposable in
                let forwarder = StageForwarder(observer: subscriber)
                return handler(error, forwarder)
            }
        }
        return .init(source: newSource)
    }

    func subscribe(
        onState: ((State) -> Void)? = nil,
        onMessage: ((Message) -> Void)? = nil,
        onCompleted: (() -> Void)? = nil,
        onTerminate: ((Error) -> Void)? = nil,
        scheduler: ImmediateSchedulerType = MainScheduler.instance
    ) -> Disposable {
        return source
            .observeOn(scheduler)
            .subscribe(
                onNext: { item in
                    switch item {
                    case .message(let msg): onMessage?(msg)
                    case .state(let sta): onState?(sta)
                    }
                },
                onError: onTerminate,
                onCompleted: onCompleted,
                onDisposed: nil
            )
    }

}

extension RxStage {
    static func complete() -> Self where State == Void {
        return Self(source: Observable<Element>.just(.state(())))
    }
}

extension ObservableType {
    func asStage<State, Message>(transform: @escaping (Self.Element) -> ForwardItem<State, Message>)
        -> RxStage<State, Message> {
        return .init(source: map(transform))
    }

    func asStage<State, Message>() -> RxStage<State, Message>
        where Self.Element == ForwardItem<State, Message> {
        return .init(source: asObservable())
    }

    func subscribe<State, Message>(_ forwarder: StageForwarder<State, Message>) -> Disposable
        where Element == ForwardItem<State, Message> {
        return self.subscribe(forwarder.observer)
    }
}
