//
//  CombineMappingTest.swift
//  SpeedTestTests
//
//  Created by 李晨 on 2020/8/18.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import XCTest
#if canImport(Combine)
import Combine

@available(iOS 13.0, *)
class CombineMappingTests: XCTestCase {

    func testMapPumping() {
        measure {
            var sum = 0
            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for _ in 0 ..< iterations * 10 {
                        _ = subscriber.receive(1)
                    }
                }
                .map { $0 }
                .map { $0 }
                .map { $0 }
                .map { $0 }
                .map { $0 }
                .sink(receiveValue: { x in
                    sum += x
                })

            subscription.cancel()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testMapCreating() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                        for _ in 0 ..< 1 {
                            _ = subscriber.receive(1)
                        }
                    }
                    .map { $0 }
                    .map { $0 }
                    .map { $0 }
                    .map { $0 }
                    .map { $0 }
                    .sink(receiveValue: { x in
                        sum += x
                    })

                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testFlatMapsPumping() {
        measure {
            var sum = 0
            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for _ in 0 ..< iterations * 10 {
                        _ = subscriber.receive(1)
                    }
                }
                .flatMap { x in Just(x) }
                .flatMap { x in Just(x) }
                .flatMap { x in Just(x) }
                .flatMap { x in Just(x) }
                .flatMap { x in Just(x) }
                .sink(receiveValue: { x in
                    sum += x
                })

            subscription.cancel()

            XCTAssertEqual(sum, iterations * 10)
        }
    }


    func testFlatMapsCreating() {
        measure {
            var sum = 0
            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                        for _ in 0 ..< 1 {
                            _ = subscriber.receive(1)
                        }
                    }
                    .flatMap { x in Just(x) }
                    .flatMap { x in Just(x) }
                    .flatMap { x in Just(x) }
                    .flatMap { x in Just(x) }
                    .flatMap { x in Just(x) }
                    .sink(receiveValue: { x in
                        sum += x
                    })

                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testScanPumping() {
        measure {
            var sum = 0
            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for _ in 0 ..< iterations * 10 {
                        _ = subscriber.receive(1)
                    }
                }
                .scan(1, { (a, b) -> Int in
                    return a + b
                })
                .sink(receiveValue: { x in
                    sum += 1
                })

            subscription.cancel()

            XCTAssertEqual(sum, iterations * 10)
        }
    }


    func testScanCreating() {
        measure {
            var sum = 0
            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                        for _ in 0 ..< 1 {
                            _ = subscriber.receive(1)
                        }
                    }
                    .scan(1, { (a, b) -> Int in
                        return a + b
                    })
                    .sink(receiveValue: { x in
                        sum += 1
                    })

                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations)
        }
    }
}
#endif
