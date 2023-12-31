//
//  TourMetric.swift
//  LarkTour
//
//  Created by Meng on 2020/1/8.
//

import UIKit
import Foundation
import LKMetric
import LKCommonsTracker

final class TourMetric {
    static func fetchInstallSourceEvent(succeed: Bool,
                                        errorCode: Int,
                                        cost: Int64,
                                        errorMsg: String? = nil) {

        Tracker.post(SlardarEvent(
            name: "ug_get_source_event",
            metric: ["cost": cost],
            category: ["succeed": succeed, "error_code": errorCode],
            extra: ["error_msg": errorMsg ?? ""]
        ))
    }

    static func switchGuidePageEvent(guideKey: String, succeed: Bool) {
        Tracker.post(SlardarEvent(
            name: "ug_switch_guide_page_event",
            metric: [:],
            category: ["guide_key": guideKey, "succeed": succeed],
            extra: [:]
        ))
    }
}

extension TourMetric {
    static func timeCostStart() -> CFTimeInterval {
        return CACurrentMediaTime()
    }

    static func timeCostEnd(for startTime: CFTimeInterval) -> Int64 {
        let endTime = CACurrentMediaTime()
        return Int64((endTime - startTime) * 1000)
    }
}
