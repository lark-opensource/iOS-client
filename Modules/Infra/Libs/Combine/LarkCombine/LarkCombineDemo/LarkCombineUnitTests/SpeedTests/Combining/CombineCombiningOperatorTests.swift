//
//  CombineCombiningOperatorTests.swift
//  SpeedTestTests
//
//  Created by bytedance on 2020/8/18.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import Combine
import XCTest

@available(iOS 13.0, *)
class CombineCombiningOperatorTests: XCTestCase {
    func testMergeWithEvent() {
        measure {
            var sum = 0

            let publisher1 = PassthroughSubject<Int, Never>()
            let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    _ = subscriber.receive(1)
            }.merge(with: publisher1)
            .sink(receiveValue: { x in sum += x })

            for _ in 0..<iterations {
                publisher1.send(1)
            }

            publisher1.send(completion: .finished)
            subscription.cancel()

            XCTAssertEqual(sum, iterations+1)
        }
    }

    func testMergeWithCreate() {
        measure {
            var sum = 0

            for _ in 0..<iterations {
                let publisher1 = PassthroughSubject<Int, Never>()
                let subscription = AnyPublisher<Int, Never>.create { subscriber in
                    _ = subscriber.receive(1)
                }.merge(with: publisher1)
                .sink(receiveValue: { x in sum += x })

                publisher1.send(1)
                publisher1.send(completion: .finished)
                subscription.cancel()
            }

            XCTAssertEqual(sum, iterations<<1)
        }
    }
}
