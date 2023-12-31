//
//  OpenCombineTests.swift
//  SpeedTestTests
//
//  Created by 李晨 on 2020/8/17.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import XCTest
import OpenCombine

class OpenCombineTests: XCTestCase {

    func testPublishSubjectPumping() {
        measure {
            var sum = 0
            let subject = PassthroughSubject<Int, Never>()

            let subscription = subject
                .sink(receiveValue: { x in
                    sum += x
                })

            for _ in 0 ..< iterations * 100 {
                subject.send(1)
            }

            subscription.cancel()

            XCTAssertEqual(sum, iterations * 100)
        }
    }

    func testPublishSubjectPumpingTwoSubscriptions() {
        measure {
            var sum = 0
            let subject = PassthroughSubject<Int, Never>()

            let subscription1 = subject
                .sink(receiveValue: { x in
                    sum += x
                })

            let subscription2 = subject
                .sink(receiveValue: { x in
                    sum += x
                })

            for _ in 0 ..< iterations * 100 {
                subject.send(1)
            }

            subscription1.cancel()
            subscription2.cancel()

            XCTAssertEqual(sum, iterations * 100 * 2)
        }
    }

    func testPublishSubjectCreating() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations * 10 {
                let subject = PassthroughSubject<Int, Never>()

                let subscription = subject
                    .sink(receiveValue: { x in
                        sum += x
                    })

                for _ in 0 ..< 1 {
                    subject.send(1)
                }

                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testMapFilterPumping() {
        measure {
            var sum = 0

            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for _ in 0 ..< iterations * 10 {
                        _ = subscriber.receive(1)
                    }
                }
                .map { $0 }.filter { _ in true }
                .map { $0 }.filter { _ in true }
                .map { $0 }.filter { _ in true }
                .map { $0 }.filter { _ in true }
                .map { $0 }.filter { _ in true }
                .map { $0 }.filter { _ in true }
                .sink(receiveValue: { x in
                    sum += x
                })

            subscription.cancel()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testMapFilterCreating() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                        for _ in 0 ..< 1 {
                            _ = subscriber.receive(1)
                        }
                    }
                    .map { $0 }.filter { _ in true }
                    .map { $0 }.filter { _ in true }
                    .map { $0 }.filter { _ in true }
                    .map { $0 }.filter { _ in true }
                    .map { $0 }.filter { _ in true }
                    .map { $0 }.filter { _ in true }
                    .sink(receiveValue: { x in
                        sum += x
                    })

                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testFlatMapLatestPumping() {
        measure {
            var sum = 0
            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for _ in 0 ..< iterations * 10 {
                        _ = subscriber.receive(1)
                    }
                }
                .map { x in Just(x) }
                .switchToLatest()
                .map { x in Just(x) }
                .switchToLatest()
                .map { x in Just(x) }
                .switchToLatest()
                .map { x in Just(x) }
                .switchToLatest()
                .map { x in Just(x) }
                .switchToLatest()
                .sink(receiveValue: { x in
                    sum += x
                })

            subscription.cancel()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testFlatMapLatestCreating() {
        measure {
            var sum = 0
            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                        for _ in 0 ..< 1 {
                            _ = subscriber.receive(1)
                        }
                    }
                    .map { x in Just(x) }
                    .switchToLatest()
                    .map { x in Just(x) }
                    .switchToLatest()
                    .map { x in Just(x) }
                    .switchToLatest()
                    .map { x in Just(x) }
                    .switchToLatest()
                    .map { x in Just(x) }
                    .switchToLatest()
                    .sink(receiveValue: { x in
                        sum += x
                    })

                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testCombineLatestPumping() {
        measure {
            var sum = 0

            let publisher = (0 ..< iterations * 10)
                .map { _ in 1 }
                .publisher

            var last = Just(1).combineLatest(Just(1), Just(1), publisher) { x, _, _ ,_ in x }.eraseToAnyPublisher()

            for _ in 0 ..< 6 {
                last = Just(1).combineLatest(Just(1), Just(1), last) { x, _, _ ,_ in x }.eraseToAnyPublisher()
            }

            let subscription = last
                .sink(receiveValue: { x in
                    sum += x
                })

            subscription.cancel()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testCombineLatestCreating() {
        measure {
            var sum = 0
            for _ in 0 ..< iterations {
                var last = AnyPublisher<Int, Never>.create { subscriber in
                        for _ in 0 ..< 1 {
                            _ = subscriber.receive(1)
                        }
                    }
                    .combineLatest(Just(1), Just(1), Just(1)) { x, _, _ ,_ in x }.eraseToAnyPublisher()

                for _ in 0 ..< 6 {
                    last = Just(1).combineLatest(Just(1), Just(1), last) { x, _, _ ,_ in x }.eraseToAnyPublisher()
                }

                let subscription = last
                    .sink(receiveValue: { x in
                        sum += x
                    })

                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations)
        }
    }
}

extension Publishers {

    public struct Anonymous<Output, Failure: Swift.Error>: Publisher {
        private var closure: (AnySubscriber<Output, Failure>) -> Void

        public init(closure: @escaping (AnySubscriber<Output, Failure>) -> Void) {
            self.closure = closure
        }

        public func receive<S>(subscriber: S) where S : Subscriber, Anonymous.Failure == S.Failure, Anonymous.Output == S.Input {
            let subscription = Subscriptions.Anonymous(subscriber: subscriber)
            subscriber.receive(subscription: subscription)
            subscription.start(closure)
        }
    }

}

extension Subscriptions {

    final class Anonymous<SubscriberType: Subscriber, Output, Failure>: Subscription where SubscriberType.Input == Output, Failure == SubscriberType.Failure {

        private var subscriber: SubscriberType?

        init(subscriber: SubscriberType) {
            self.subscriber = subscriber
        }

        func start(_ closure: @escaping (AnySubscriber<Output, Failure>) -> Void) {
            if let subscriber = subscriber {
                closure(AnySubscriber(subscriber))
            }
        }

        func request(_ demand: Subscribers.Demand) {
            // Irgnore demand
        }

        func cancel() {
            self.subscriber = nil
        }

    }

}

extension AnyPublisher {

    static func create(_ closure: @escaping (AnySubscriber<Output, Failure>) -> Void) -> AnyPublisher<Output, Failure> {
        return Publishers.Anonymous<Output, Failure>(closure: closure)
            .eraseToAnyPublisher()
    }

}
