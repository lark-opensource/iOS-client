//
//  CommentThrottle.swift
//  SKCommon
//
//  Created by huayufan on 2022/3/23.
//  Included OSS: RxSwift
//  Copyright (c) 2015 Krunoslav Zaher, Shai Mishali
//  spdx license identifier: MIT


import Foundation


class CommentThrottle {
    
    let dueTime: DispatchTimeInterval
    
    var lastSentTime: Date?
    
    init(dueTime: DispatchTimeInterval) {
        self.dueTime = dueTime
    }
    
    func throttle(block: () -> Void) {
        let now = Date()
        let reducedScheduledTime: DispatchTimeInterval
        
        if let lastSendingTime = self.lastSentTime {
            reducedScheduledTime = dueTime.reduceWithSpanBetween(earlierDate: lastSendingTime, laterDate: now)
        } else {
            reducedScheduledTime = .nanoseconds(0)
        }

        if reducedScheduledTime.isNow {
            block()
            self.lastSentTime = Date()
        }
    }
}

extension DispatchTimeInterval {
    
    var convertToSecondsFactor: Double {
        switch self {
        case .nanoseconds: return 1_000_000_000.0
        case .microseconds: return 1_000_000.0
        case .milliseconds: return 1_000.0
        case .seconds: return 1.0
        case .never: return 1.0
        @unknown default: return 1.0
        }
    }
 
    func map(_ transform: (Int, Double) -> Int) -> DispatchTimeInterval {
        switch self {
        case .nanoseconds(let value): return .nanoseconds(transform(value, 1_000_000_000.0))
        case .microseconds(let value): return .microseconds(transform(value, 1_000_000.0))
        case .milliseconds(let value): return .milliseconds(transform(value, 1_000.0))
        case .seconds(let value): return .seconds(transform(value, 1.0))
        case .never: return .never
        @unknown default: return .never
        }
    }
    
    var isNow: Bool {
        switch self {
        case .nanoseconds(let value), .microseconds(let value), .milliseconds(let value), .seconds(let value): return value == 0
        case .never: return false
        @unknown default: return false
        }
    }
    
    internal func reduceWithSpanBetween(earlierDate: Date, laterDate: Date) -> DispatchTimeInterval {
        return self.map { value, factor in
            let interval = laterDate.timeIntervalSince(earlierDate)
            let remainder = Double(value) - interval * factor
            guard remainder > 0 else { return 0 }
            return Int(remainder.rounded(.toNearestOrAwayFromZero))
        }
    }
}
