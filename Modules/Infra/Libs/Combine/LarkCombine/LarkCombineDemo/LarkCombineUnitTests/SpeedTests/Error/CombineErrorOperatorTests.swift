//
//  CombineErrorOperatorTests.swift
//  SpeedTestTests
//
//  Created by bytedance on 2020/8/18.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import Combine
import XCTest

struct DummyError: Error {}

@available(iOS 13.0, *)
class CombineErrorTests: XCTestCase {
    func testMergeWithCreate() {
        measure {
            var sum = 0

            for _ in 1...iterations {
                var subscriptions = Set<AnyCancellable>()
                Just(1)
                    .tryMap { _ in throw DummyError() }
                    .catch { _ in Just(1) }
                    .tryMap { _ in throw DummyError() }
                    .catch { _ in Just(1) }
                    .tryMap { _ in throw DummyError() }
                    .catch { _ in Just(1) }
                    .tryMap { _ in throw DummyError() }
                    .catch { _ in Just(1) }
                    .tryMap { _ in throw DummyError() }
                    .catch { _ in Just(1) }
                    .sink { x in sum += x }
                    .store(in: &subscriptions)
            }

            XCTAssertEqual(sum, iterations)
        }
    }
}
