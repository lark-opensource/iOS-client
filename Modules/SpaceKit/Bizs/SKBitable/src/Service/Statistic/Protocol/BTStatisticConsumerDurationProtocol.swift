//
//  BTStatisticConsumerDurationProtocol.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/11/26.
//

import Foundation

protocol BTStatisticConsumerDurationProtocol {
    var eventName: BTStatisticEventName { get }
    var mainStageTimestamps: [String: Any] { get }
    var mainStageDurationMaps: [String: Any] { get }

    func updateDuration(currentPoint: BTStatisticNormalPoint)
}

extension BTStatisticConsumerDurationProtocol {
    func defaultLog(
        trace: BTStatisticBaseTrace,
        logger: BTStatisticLoggerProvider,
        currentPoint: BTStatisticNormalPoint
    ) {
        updateDuration(currentPoint: currentPoint)
        var params = currentPoint.extra
        params[BTStatisticConstant.stage] = currentPoint.name
        logger.send(trace: trace, eventName: eventName.rawValue, params: params)
    }

    func logEnd(
        type: BTStatisticEventResult,
        trace: BTStatisticBaseTrace,
        logger: BTStatisticLoggerProvider,
        currentPoint: BTStatisticNormalPoint
    ) {
        updateDuration(currentPoint: currentPoint)
        var params = currentPoint.extra
        params[BTStatisticConstant.stage] = BTStatisticStageType.end.rawValue
        params[BTStatisticConstant.result] = type.rawValue
        params[BTStatisticConstant.mainStageTimestampKey] = mainStageTimestamps
        params[BTStatisticConstant.mainStageDurationKey] = mainStageDurationMaps
        logger.send(
            trace: trace,
            eventName: eventName.rawValue,
            params: params
        )

        trace.isStop = true
    }
}
