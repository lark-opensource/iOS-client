//
//  Observable+Aggregation.swift
//  UGRCoreIntegration
//
//  Created by shizhengyu on 2021/3/14.
//

import Foundation
import RxSwift

protocol RespValidator {
    associatedtype Response
    func isValid(response: Response) -> Bool
}

private struct EventContext<T> {
    let isRemote: Bool
    let respEvent: Event<T>
}

extension RxSwift.Observable {
    static func smartCombine<T, D>(
        localReq: Observable<T>,
        remoteReq: Observable<T>,
        validator: D
    ) -> RxSwift.Observable<T> where D: RespValidator, D.Response == T {
        let source = RxSwift.Observable<EventContext>.merge(
            localReq.materialize().map { EventContext(isRemote: false, respEvent: $0) },
            remoteReq.materialize().map { EventContext(isRemote: true, respEvent: $0) }
        )

        return RxSwift.Observable<T>.create { (observer) -> Disposable in
            return source.subscribe { (event) in
                func sendRespIfNeeded(_ response: T) {
                    if validator.isValid(response: response) {
                        observer.onNext(response)
                    }
                }

                switch event {
                case .next(let respCtx):
                    switch respCtx.respEvent {
                    case .next(let response):
                        sendRespIfNeeded(response)
                        if respCtx.isRemote {
                            observer.onCompleted()
                        }
                    case .error(let error):
                        if respCtx.isRemote {
                            observer.onError(error)
                        }
                    default: break
                    }
                case .completed:
                    observer.onCompleted()
                default: break
                }
            }
        }
    }
}
