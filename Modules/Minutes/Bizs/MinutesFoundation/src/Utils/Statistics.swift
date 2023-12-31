//
//  Statistics.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/4/25.
//

import Foundation
import LKCommonsLogging

public final class Statistics {

    static let logger = Logger.log(Statistics.self, category: "Minutes")

    public private(set) var max: Double = .zero
    public private(set) var min: Double = .infinity
    public private(set) var avg: Double = .zero
    // disable-lint: duplicated_code
    public private(set) var count: UInt = .zero {
        didSet {
            guard count % 20 == 0 else { return }
            queue.async {
                Self.logger.info("Statistics(\(self.label)) max:\(self.max) min:\(self.min) avg:\(self.avg) count:\(self.count)")
            }
        }
    }
    // enable-lint: duplicated_code

    let label: String
    lazy var queue: DispatchQueue = .init(label: "Minutes Statistics(\(label))")
    var currentTime = CACurrentMediaTime()

    public init(_ label: String) {
        self.label = label
    }

    private func _record(_ value: Double) {
        // max
        if value > max {
            max = value
        }
        // min
        if value < min {
            min = value
        }
        // count
        count += 1
        // avg
        let diff = (value - avg) / Double(count)
        avg += diff
    }

    public func record(_ value: Double) {
        queue.sync {
            _record(value)
        }
    }

    public func track(_ block: () -> Void) {
        let start = CACurrentMediaTime()
        block()
        let end = CACurrentMediaTime()
        record(end - start)
    }

    deinit {
        Self.logger.info("Statistics(\(label)) max:\(max) min:\(min) avg:\(avg) count:\(count)")
    }

}
