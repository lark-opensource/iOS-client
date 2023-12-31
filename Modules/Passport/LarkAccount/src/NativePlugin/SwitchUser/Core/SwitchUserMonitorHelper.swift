//
//  SwitchUserMonitorHelper.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/5/16.
//

import Foundation
import ECOProbeMeta

class SwitchUserMonitorHelper {

    static func flush(_ code: OPMonitorCodeProtocol,
                      categoryValueMap: [String: Any]? = nil,
                      timerStart: SwitchUserMonitorDurationFlow? = nil, //值为流程标识
                      timerStop: SwitchUserMonitorDurationFlow? = nil, //值为流程标识
                      isSuccessResult: Bool = false,
                      isFailResult: Bool = false,
                      context: SwitchUserMonitorContext,
                      error: Error? = nil) {

        var category: [String: Any]
        if let map = categoryValueMap {
            category = map
        } else {
            //初始化一个
            category = [:]
        }

        //追加公参
        category["switch_type"] = context.type.rawValue
        category["switch_reason"] = context.reason.rawValue

        //追加duration
        if let flow = timerStart {
            ProbeDurationHelper.startDuration(flow.rawValue)
        }

        if let flow = timerStop {
            category[ProbeConst.duration] = ProbeDurationHelper.stopDuration(flow.rawValue)
        }

        let monitor = PassportMonitor.monitor(code,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: category,
                                              context: UniContextCreator.create(.switchUser),
                                              error: error)

        if let error = error {
            monitor.setPassportErrorParams(error: error)
        }


        if isFailResult {
            monitor.setResultTypeFail()
        }

        if isSuccessResult {
            monitor.setResultTypeSuccess()
        }

        //flush
        monitor.flush()
    }
}
