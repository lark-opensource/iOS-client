//
//  RxBus.swift
//  iOS
//
//  Created by 张威 on 2021/4/25.
//

import RxSwift
import RxCocoa
import LKCommonsLogging

private enum RxBusLog { }
private let logger = Logger.log(RxBusLog.self, category: "Lark.Todo.RxBus")
public protocol RxBusEvent { }

public final class RxBus<Event: RxBusEvent> {

    public let name: String
    public let queue: DispatchQueue

    private let disposeBag = DisposeBag()
    private let eventSubject = PublishSubject<Event>()
    private let observeOnScheduler: SerialDispatchQueueScheduler

    /// Initializer
    ///
    /// - parameter name: used for logging
    /// - parameter state: initial state
    public init(name: String, queue: DispatchQueue = .main) {
        self.name = name
        self.queue = queue
        self.observeOnScheduler = .init(queue: queue, internalSerialQueueName: "Lark.Todo.RxBus.\(name)")
        self.eventSubject.disposed(by: self.disposeBag)
    }

    public func subscribe(onEvent: @escaping (_ e: Event) -> Void) -> Disposable {
        let disposable = eventSubject.observeOn(observeOnScheduler).subscribe(onNext: { onEvent($0) })
        disposable.disposed(by: disposeBag)
        return disposable
    }

    public func post(
        _ event: Event,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        eventSubject.onNext(event)
        let eventDesc = (event as? CustomDebugStringConvertible).debugDescription ?? ""
        logger.info(
            "RxStore.\(name) post: \(eventDesc)",
            file: file,
            function: function,
            line: line
        )
    }

}
