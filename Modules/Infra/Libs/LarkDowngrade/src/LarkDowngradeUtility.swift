//
//  LarkDowngradeUtility.swift
//  LarkDowngrade
//
//  Created by ByteDance on 2023/9/4.
//

import Foundation
import LKCommonsLogging
import LKCommonsTracker

class LarkDowngradeUtility {

    static var logger = Logger.log(LarkDowngradeUtility.self)

    static func recordRulesMach(eventParam: Dictionary<String, Any>) {
        let startEvent = TeaEvent("perf_downgrade_rules", params: eventParam)
        Tracker.post(startEvent)
    }

    static func recordDowngradeDo(key: String,
                                  status: LarkDowngradeStatus,
                                  result: LarkDowngradeRuleResult) {
        var eventParams = status.toRecordDict()
        eventParams["key"] = key
        eventParams["type"] = result.rawValue
        if result == .upgrade {
            eventParams["ext"] = downgradedTasks.joined(separator: "&")
        }
        let startEvent = TeaEvent("perf_downgrade_info_dev", params: eventParams)
        Tracker.post(startEvent)
        LarkDowngradeUtility.logger.info("LarkDowngrade_Downgrade: \(String(describing: eventParams))")
    }
}
