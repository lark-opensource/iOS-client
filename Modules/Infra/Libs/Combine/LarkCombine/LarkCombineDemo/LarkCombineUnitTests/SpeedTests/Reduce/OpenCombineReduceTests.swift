//
//  OpenCombineReduceTests.swift
//  SpeedTestTests
//
//  Created by 李晨 on 2020/8/18.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import XCTest
import OpenCombine

class OpenCombineReduceTests: XCTestCase {

    func testReducePumping() {
        measure {
            var sum = 0

            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                for _ in 0 ..< iterations * 10 {
                    _ = subscriber.receive(1)
                }
                subscriber.receive(completion: .finished)
            }
            .reduce(0, { (a, b) -> Int in return a + b })
            .reduce(0, { (a, b) -> Int in return a + b })
            .reduce(0, { (a, b) -> Int in return a + b })
            .reduce(0, { (a, b) -> Int in return a + b })
            .reduce(0, { (a, b) -> Int in return a + b })
            .sink(receiveValue: { x in
                sum += x
            })

            subscription.cancel()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testReduceCreating() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for _ in 0 ..< 1 {
                        _ = subscriber.receive(1)
                    }
                    subscriber.receive(completion: .finished)
                }
                .reduce(0, { (a, b) -> Int in return a + b })
                .reduce(0, { (a, b) -> Int in return a + b })
                .reduce(0, { (a, b) -> Int in return a + b })
                .reduce(0, { (a, b) -> Int in return a + b })
                .reduce(0, { (a, b) -> Int in return a + b })
                .sink(receiveValue: { x in
                    sum += x
                })
                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testCollectPumping() {
        measure {
            var sum = 0

            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                for _ in 0 ..< iterations * 10 {
                    _ = subscriber.receive(1)
                }
                subscriber.receive(completion: .finished)
            }
            .collect()
            .sink(receiveValue: { x in
                sum += x.count
            })

            subscription.cancel()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testCollectCreating() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    for _ in 0 ..< 1 {
                        _ = subscriber.receive(1)
                    }
                    subscriber.receive(completion: .finished)
                }
                .collect()
                .sink(receiveValue: { x in
                    sum += x.count
                })
                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

}
