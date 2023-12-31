//
//  Tracer.swift
//  UGRCoreIntegration
//
//  Created by shizhengyu on 2021/3/8.
//

import UIKit
import Foundation
import LKCommonsLogging
import LKCommonsTracker
import ThreadSafeDataStructure
import LarkRustClient

final class Tracer {
    enum ErrorField {
        static let errorCode = "error_code"
        static let errorMsg = "error_msg"
    }
    private let prefix = "[UGReachSDK]"
    private let logger = Logger.log(Tracer.self, category: "ug.reach.coreDispatcher")
    var timeDic: SafeDictionary<String, TimeInterval> = [:] + .readWriteLock

    @discardableResult
    func traceLog(msg: String) -> Tracer {
        logger.info(prefix + msg)
        return self
    }

    @discardableResult
    func traceMetric(
        eventKey: String,
        identifier: String,
        metric: [AnyHashable: Any] = [:],
        category: [AnyHashable: Any] = [:],
        extra: [AnyHashable: Any] = [:],
        isEndPoint: Bool
    ) -> Tracer {
        let key = eventKey + identifier
        if isEndPoint {
            guard let startTime = timeDic[key] else { return self }
            timeDic[key] = nil
            let cost = CACurrentMediaTime() - startTime
            var metric = metric
            metric["latency"] = cost
        } else {
            timeDic[key] = CACurrentMediaTime()
        }
        Tracker.post(
            SlardarEvent(
                name: eventKey,
                metric: metric,
                category: category,
                extra: extra
            )
        )
        return self
    }
}

extension Error {
    public func reachErrorCode() -> Int64 {
        guard let err = self as? RCError else {
            return Int64(NSNotFound)
        }
        switch err {
        case .businessFailure(let errorInfo):
            return Int64(errorInfo.code)
        default:
            return Int64(NSNotFound)
        }
    }
}
