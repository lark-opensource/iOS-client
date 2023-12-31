//
//  CombineSelectingOperatorTests.swift
//  SpeedTestTests
//
//  Created by bytedance on 2020/8/18.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import Combine
import XCTest

@available(iOS 13.0, *)
class CombineSelectingOperatorTests: XCTestCase {
    func testFirstWithEvent() {
        measure {

            var sum = 0

            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                for _ in 0 ..< iterations {
                    _ = subscriber.receive(1)
                }
                subscriber.receive(completion: .finished)
            }
            .first()
            .sink(receiveValue: { x in
                sum += x
            })

            subscription.cancel()

            XCTAssertEqual(sum, 1)

        }
    }

    func testFirstWithCreate() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for _ in 0 ..< 1 {
                        _ = subscriber.receive(1)
                    }
                    subscriber.receive(completion: .finished)
                }
                .first()
                .sink(receiveValue: { x in
                    sum += x
                })
                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testLastWithEvent() {
        measure {
            var sum = 0

            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                for _ in 0 ..< iterations {
                    _ = subscriber.receive(1)
                }
                subscriber.receive(completion: .finished)
            }
            .last()
            .sink(receiveValue: { x in
                sum += x
            })

            subscription.cancel()

            XCTAssertEqual(sum, 1)
        }
    }

    func testLastWithCreate() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for _ in 0 ..< 1 {
                        _ = subscriber.receive(1)
                    }
                    subscriber.receive(completion: .finished)
                }
                .last()
                .sink(receiveValue: { x in
                    sum += x
                })
                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testOutputWithEvent() {
        measure {
            var sum = 0

            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                for _ in 0 ..< iterations {
                    _ = subscriber.receive(1)
                }
                subscriber.receive(completion: .finished)
            }
            .output(at: 0)
            .sink(receiveValue: { x in
                sum += x
            })

            subscription.cancel()

            XCTAssertEqual(sum, 1)
        }
    }

    func testOutputWithCreate() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for _ in 0 ..< 1 {
                        _ = subscriber.receive(1)
                    }
                    subscriber.receive(completion: .finished)
                }
            .output(at: 0)
                .sink(receiveValue: { x in
                    sum += x
                })
                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations)
        }
    }
}
