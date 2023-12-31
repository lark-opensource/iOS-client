//
//  OpenCombineFilterTests.swift
//  SpeedTestTests
//
//  Created by 李晨 on 2020/8/18.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import XCTest
import OpenCombine

class OpenCombineFilterTests: XCTestCase {

    func testFilterPumping() {
        measure {
            var sum = 0

            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for _ in 0 ..< iterations * 10 {
                        _ = subscriber.receive(1)
                    }
                }
                .filter { _ in true }
                .filter { _ in true }
                .filter { _ in true }
                .filter { _ in true }
                .filter { _ in true }
                .sink(receiveValue: { x in
                    sum += x
                })

            subscription.cancel()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testFilterCreating() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                        for _ in 0 ..< 1 {
                            _ = subscriber.receive(1)
                        }
                    }
                    .filter { _ in true }
                    .filter { _ in true }
                    .filter { _ in true }
                    .filter { _ in true }
                    .filter { _ in true }
                    .sink(receiveValue: { x in
                        sum += x
                    })

                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testCompactMapPumping() {
        measure {
            var sum = 0

            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for _ in 0 ..< iterations * 10 {
                        _ = subscriber.receive(1)
                    }
                }
                .compactMap({ $0 })
                .compactMap({ $0 })
                .compactMap({ $0 })
                .compactMap({ $0 })
                .compactMap({ $0 })
                .sink(receiveValue: { x in
                    sum += x
                })

            subscription.cancel()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testCompactMapCreating() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                        for _ in 0 ..< 1 {
                            _ = subscriber.receive(1)
                        }
                    }
                    .compactMap({ $0 })
                    .compactMap({ $0 })
                    .compactMap({ $0 })
                    .compactMap({ $0 })
                    .compactMap({ $0 })
                    .sink(receiveValue: { x in
                        sum += x
                    })

                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testDuplicatesPumping() {
        measure {
            var sum = 0

            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for i in 0 ..< iterations * 10 {
                        _ = subscriber.receive(i)
                        _ = subscriber.receive(i)
                        _ = subscriber.receive(i)
                        _ = subscriber.receive(i)
                        _ = subscriber.receive(i)
                    }
                }
                .removeDuplicates()
                .removeDuplicates()
                .removeDuplicates()
                .removeDuplicates()
                .removeDuplicates()
                .sink(receiveValue: { x in
                    sum += 1
                })

            subscription.cancel()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testDuplicatesCreating() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                        for _ in 0 ..< 1 {
                            _ = subscriber.receive(1)
                            _ = subscriber.receive(1)
                            _ = subscriber.receive(1)
                            _ = subscriber.receive(1)
                            _ = subscriber.receive(1)
                        }
                    }
                    .removeDuplicates()
                    .removeDuplicates()
                    .removeDuplicates()
                    .removeDuplicates()
                    .removeDuplicates()
                    .sink(receiveValue: { x in
                        sum += x
                    })

                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testReplactEmptyPumping() {
        measure {
            var sum = 0

            let subscription = AnyPublisher<Int?, Never>.create { subscriber in
                    for i in 0 ..< iterations * 10 {
                        _ = subscriber.receive(i)
                        _ = subscriber.receive(nil)
                    }
                }
                .replaceEmpty(with: 1)
                .replaceEmpty(with: 1)
                .replaceEmpty(with: 1)
                .replaceEmpty(with: 1)
                .replaceEmpty(with: 1)
                .sink(receiveValue: { x in
                    sum += 1
                })

            subscription.cancel()

            XCTAssertEqual(sum, iterations * 10 * 2)
        }
    }

    func testReplactEmptyCreating() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int?, Never>.create { subscriber in
                        for _ in 0 ..< 1 {
                            _ = subscriber.receive(1)
                            _ = subscriber.receive(nil)
                        }
                    }
                    .replaceEmpty(with: 1)
                    .replaceEmpty(with: 1)
                    .replaceEmpty(with: 1)
                    .replaceEmpty(with: 1)
                    .replaceEmpty(with: 1)
                    .sink(receiveValue: { x in
                        sum += 1
                    })

                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations * 2)
        }
    }
}
