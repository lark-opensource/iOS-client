//
//  NSDate+Metrics.swift
//  TestLongPic
//
//  Created by 吴珂 on 2020/8/23.
//  Copyright © 2020 bytedance. All rights reserved.


import Foundation

extension Date {
    @discardableResult
    public static func measure(prefix: String, _ block: () -> Void) -> TimeInterval {
        let startDate = Date()
        block()
        let endDate = Date()
        let elaspedTime = (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) * 1000
        DocsLogger.info("\(prefix) elapsed time: \(elaspedTime)")
        return elaspedTime
    }
}
