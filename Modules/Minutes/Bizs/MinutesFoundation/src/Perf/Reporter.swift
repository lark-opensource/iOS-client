//
//  Reporter.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/7/15.
//

import Foundation

/// A Protocol for reporting the performance data
protocol Reporter {
    /// report the performance data immediately
    /// - Parameters:
    ///   - keepAlive: Whether to continuously report performance data, if `true`,  the reporter need to report data periodically until the reporter deinit or call `fire` with keepAlive `false`
    ///   - category: the category data that needs to be carried to report performance data
    func fire(keepAlive: Bool, category: [String: Any])

    /// update the extended data , effective for subsequent reports
    /// - Parameter extra: the extended data that needs to be carried to report performance data
    func update(extra: [String: Any])
}
