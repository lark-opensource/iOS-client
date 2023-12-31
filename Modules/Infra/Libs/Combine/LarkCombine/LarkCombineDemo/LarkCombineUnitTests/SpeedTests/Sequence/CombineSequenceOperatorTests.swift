//
//  CombineSequenceOperatorTests.swift
//  SpeedTest
//
//  Created by bytedance on 2020/8/18.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import Combine
import XCTest

@available(iOS 13.0, *)
class CombineSequenceOperatorTests: XCTestCase {
    func testDropFirstWithEvent() {
        measure {
            var sum = 0

            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                for _ in 0 ..< iterations {
                    _ = subscriber.receive(1)
                }
                subscriber.receive(completion: .finished)
            }
            .dropFirst()
            .sink(receiveValue: { x in
                sum += x
            })

            subscription.cancel()

            XCTAssertEqual(sum, iterations-1)
        }
    }

    func testDropFirstWithCreate() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for _ in 0 ..< 1 {
                        _ = subscriber.receive(1)
                    }
                    subscriber.receive(completion: .finished)
                }
                .dropFirst()
                .sink(receiveValue: { x in
                    sum += x
                })
                subscription.cancel()
            }

            XCTAssertEqual(sum, 0)
        }
    }

    func testAppendWithEvent() {
        measure {
            var sum = 0

            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                for _ in 0 ..< iterations {
                    _ = subscriber.receive(1)
                }
                subscriber.receive(completion: .finished)
            }
            .append(1)
            .sink(receiveValue: { x in
                sum += x
            })

            subscription.cancel()

            XCTAssertEqual(sum, iterations+1)
        }
    }

    func testAppendWithCreate() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for _ in 0 ..< 1 {
                        _ = subscriber.receive(1)
                    }
                    subscriber.receive(completion: .finished)
                }
                .append(1)
                .sink(receiveValue: { x in
                    sum += x
                })
                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations<<1)
        }
    }

    func testPrependWithEvent() {
        measure {
            var sum = 0

            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                for _ in 0 ..< iterations {
                    _ = subscriber.receive(1)
                }
                subscriber.receive(completion: .finished)
            }
            .prepend(1)
            .sink(receiveValue: { x in
                sum += x
            })

            subscription.cancel()

            XCTAssertEqual(sum, iterations+1)
        }
    }

    func testPrependWithCreate() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for _ in 0 ..< 1 {
                        _ = subscriber.receive(1)
                    }
                    subscriber.receive(completion: .finished)
                }
                .prepend(1)
                .sink(receiveValue: { x in
                    sum += x
                })
                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations<<1)
        }
    }

    func testPrefixWithEvent() {
        measure {
            var sum = 0
            let stop = PassthroughSubject<Void, Never>()
            let pub = PassthroughSubject<Int, Never>()

            let subscription = pub
            .prefix(untilOutputFrom: stop)
                .sink(receiveValue: { x in
                    sum += x
                })
            for i in 0 ..< iterations {
                pub.send(i)
                if i == 1 {
                    stop.send()
                }
            }
            subscription.cancel()

            XCTAssertEqual(sum, 1)
        }
    }

    func testPrefixWithCreate() {
        measure {
            var sum = 0
            for _ in 0 ..< iterations {
                let stop = PassthroughSubject<Void, Never>()
                let pub = PassthroughSubject<Int, Never>()

                let subscription = pub
                    .prefix(untilOutputFrom: stop)
                    .sink(receiveValue: { x in
                        sum += x
                    })
                pub.send(1)
                stop.send()
                pub.send(2)
                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations)
        }
    }
}
