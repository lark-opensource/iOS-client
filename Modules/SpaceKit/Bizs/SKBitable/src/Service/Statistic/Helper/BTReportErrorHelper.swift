//
//  BTReportErrorHelper.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/11/7.
//

import Foundation
import SKFoundation

final class BTReportErrorHelper {
    static func reportError(
        reason: String,
        trace: BTStatisticBaseTrace,
        logger: BTStatisticLoggerProvider,
        currentPoint: BTStatisticNormalPoint,
        extra: [String: Any]? = nil) {
            var realParams = extra ?? [:]
            realParams[BTStatisticConstant.reason] = reason
            realParams[BTStatisticConstant.pointName] = currentPoint.name
            realParams[BTStatisticConstant.pointType] = currentPoint.type.rawValue
            logger.send(
                trace: trace,
                eventName: BTStatisticEventName.base_mobile_performance_warning_point.rawValue,
                params: realParams
            )
        }

    static func reportError(traceId: String, reason: String, extra: [String: Any]? = nil) {
        var realParams = extra ?? [:]
        realParams[BTStatisticConstant.reason] = reason
        DocsTracker.newLog(
            event: BTStatisticEventName.base_mobile_performance_warning_point.rawValue,
            parameters: realParams)
    }
}
