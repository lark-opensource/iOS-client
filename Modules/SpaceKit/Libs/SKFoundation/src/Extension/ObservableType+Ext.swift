//
//  ObservableType+Ext.swift
//  SKFoundation
//
//  Created by huayufan on 2022/10/10.
//  


import Foundation
import RxSwift
import RxCocoa

extension ObservableType {

    /// trigger 发送true信号之前，先缓存信号。等trigger发送true之后发送缓存中的信号，后续不会再阻塞和缓存信号
    /// 除非trigger再关掉
    ///- parameter trigger: The BehaviorRelay sequence used to signal the emission of the buffered items.
    ///- returns: The buffered observable from elements of the source sequence.
    public func bufferBeforTrigger<Trigger: BehaviorRelay<Bool>>(_ trigger: Trigger) -> Observable<Element> {
        return Observable.create { observer in
            var buffer: [Element] = []
            let lock = NSRecursiveLock()
            let triggerDisposable = trigger.subscribe { event in
                lock.lock(); defer { lock.unlock() }
                switch event {
                case .next:
                    for signal in buffer {
                        observer.onNext(signal)
                    }
                    buffer = []
                default:
                    break
                }
            }
            let disposable = self.subscribe { [weak trigger] event in
                lock.lock(); defer { lock.unlock() }
                switch event {
                case .next(let element):
                    if trigger?.value == false {
                        buffer.append(element)
                    } else {
                        for signal in buffer {
                            observer.onNext(signal)
                        }
                        buffer.removeAll()
                        observer.onNext(element)
                    }
                case .completed:
                    for signal in buffer {
                        observer.onNext(signal)
                    }
                    buffer.removeAll()
                    observer.onCompleted()
                case .error(let error):
                    observer.onError(error)
                    buffer = []
                @unknown default:
                    break
                }
            }
            return Disposables.create([disposable, triggerDisposable])
        }
    }
}
