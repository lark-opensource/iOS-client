//
//  LKTestExpectation.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/3/9.
//

import XCTest
import Foundation

/// 如果触发超时，则不算是单测运行失败
final class LKTestExpectation: XCTestExpectation {
    /// 是不是因为超时触发的wait
    private(set) var autoFulfill: Bool = false

    /// 过N秒后如果没有执行fulfill，则主动执行一次
    func setupAutoFulfill(after: Double) {
        // 为了保证block先于wait执行，我们这里减少1s
        DispatchQueue.global().asyncAfter(deadline: .now() + after - 1) { [weak self] in
            guard let `self` = self else { return }
            self.autoFulfill = true
            // 触发多次fulfill，直到触发wait
            for _ in 0..<self.expectedFulfillmentCount { self.fulfill() }
        }
    }
}
