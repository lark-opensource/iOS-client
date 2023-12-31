//
//  OpenCombine+create.swift
//  LarkCombine
//
//  Created by 王元洵 on 2020/12/20.
//

import Foundation
import OpenCombine

extension Publishers {

    struct Anonymous<Output, Failure: Error>: Publisher {
        private var closure: (AnySubscriber<Output, Failure>) -> Cancellable

        init(closure: @escaping (AnySubscriber<Output, Failure>) -> Cancellable) {
            self.closure = closure
        }

        func receive<S>(subscriber: S) where S : Subscriber, Anonymous.Failure == S.Failure, Anonymous.Output == S.Input {
            let subscription = Subscriptions.OneSideSubscription()
            subscriber.receive(subscription: subscription)
            let cancellable = closure(AnySubscriber(subscriber))
            subscription.setCancellable(cancellable: cancellable)
        }
    }

}

extension Subscriptions {

    ///A Subscription that ignores request
    final class OneSideSubscription: Subscription {
        public func request(_ demand: Subscribers.Demand) {
            //ignore
        }


        private var cancelAction: (() -> Void)?
        private let lock = __UnfairLock.allocate()
        private var hasCancel = false

        init(cancelAction: @escaping () -> Void) {
            self.cancelAction = cancelAction
        }

        init(cancellable: Cancellable) {
            self.cancelAction = cancellable.cancel
        }

        init() {}

        public func cancel() {
            lock.lock()
            guard self.hasCancel else {
                lock.unlock()
                return
            }
            hasCancel = true
            lock.unlock()

            cancelAction?()
        }

        func setCancellable(cancellable: Cancellable) {
            self.cancelAction = cancellable.cancel
        }
    }
}

extension AnyPublisher {

    public static func create(_ closure: @escaping (AnySubscriber<Output, Failure>) -> Cancellable) -> AnyPublisher<Output, Failure> {
        return Publishers.Anonymous<Output, Failure>(closure: closure)
            .eraseToAnyPublisher()
    }

}
