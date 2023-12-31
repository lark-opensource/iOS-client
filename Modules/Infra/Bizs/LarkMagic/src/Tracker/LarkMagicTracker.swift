//
//  LarkMagicTracker.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/11/12.
//

import UIKit
import Foundation
import LKCommonsTracker

final class LarkMagicTracker {
    static func trackFetchConfig(succeed: Bool,
                                 errorCode: Int32? = nil,
                                 cost: Int64? = nil,
                                 errorMsg: String? = nil) {
        var extra: [AnyHashable: Any] = [:]
        if let errorMsg = errorMsg {
            extra["errorMsg"] = errorMsg
        }
        var metric: [AnyHashable: Any] = [:]
        if let cost = cost {
            metric["cost"] = cost
        }
        Tracker.post(SlardarEvent(
                        name: "ug_magic_fetch_config",
                        metric: metric,
                        category: ["succeed": succeed],
                        extra: extra)
        )

        Tracker.post(TeaEvent("ug_magic_fetch_config", params: ["succeed": succeed]))
    }

    static func trackTriggerEvent(succeed: Bool,
                                  scenario: String?,
                                  cost: Int64,
                                  errorCode: Int? = nil,
                                  errorMsg: String? = nil) {
        var extra: [AnyHashable: Any] = [:]
        if let errorMsg = errorMsg {
            extra["errorMsg"] = errorMsg
        }
        var category: [AnyHashable: Any] = ["succeed": succeed]
        if let scenario = scenario {
            category["scenario"] = scenario
        }
        if let errorCode = errorCode {
            category["errorCode"] = errorCode
        }

        Tracker.post(SlardarEvent(
                        name: "ug_magic_trigger_event",
                        metric: ["cost": cost],
                        category: category,
                        extra: extra)
        )
    }

    static func trackWillOpen(taskID: String, scenario: String) {
        Tracker.post(SlardarEvent(
                        name: "ug_magic_will_open",
                        metric: [:],
                        category: ["taskID": taskID, "scenario": scenario],
                        extra: [:])
        )
    }

    static func trackDidOpen(succeed: Bool,
                             taskId: String,
                             scenario: String,
                             cost: Int64? = nil,
                             errorCode: Int? = nil,
                             errorMsg: String? = nil) {
        var metric: [AnyHashable: Any] = [:]
        if let cost = cost {
            metric["cost"] = cost
        }
        var extra: [AnyHashable: Any] = [:]
        if let errorMsg = errorMsg {
            extra["errorMsg"] = errorMsg
        }
        var category: [AnyHashable: Any] = ["succeed": succeed, "scenario": scenario, "taskId": taskId]
        if let errorCode = errorCode {
            category["errorCode"] = errorCode
        }

        Tracker.post(SlardarEvent(
                        name: "ug_magic_did_open",
                        metric: metric,
                        category: category,
                        extra: extra)
        )
    }

    static func trackDidClosed(submitSuccess: Bool, taskId: String) {
        Tracker.post(SlardarEvent(
                        name: "ug_magic_did_closed",
                        metric: [:],
                        category: ["submitSuccess": submitSuccess, "taskId": taskId],
                        extra: [:])
        )
    }

    static func trackInterceptEvent(reason: String, _ extra: [AnyHashable: Any] = [:]) {
        Tracker.post(SlardarEvent(
                        name: "ug_magic_intercept",
                        metric: [:],
                        category: ["reason": reason],
                        extra: extra)
        )

    }

    static func trackTotalCost(cost: Int64) {
        Tracker.post(SlardarEvent(
                        name: "ug_magic_open_total_cost",
                        metric: ["cost": cost],
                        category: [:],
                        extra: [:])
        )
    }
}

extension LarkMagicTracker {
    static func timeCostStart() -> CFTimeInterval {
        return CACurrentMediaTime()
    }

    static func timeCostEnd(for startTime: CFTimeInterval) -> Int64 {
        let endTime = CACurrentMediaTime()
        return Int64((endTime - startTime) * 1000)
    }
}
