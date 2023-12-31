//
//  BTRecordSubmitConsumer.swift
//  SKBitable
//
//  Created by yinyuan on 2023/11/24.
//

import Foundation

final class BTRecordSubmitConsumer: BTStatisticConsumer, BTStatisticNormalConsumer {
    private let tag = "BTRecordSubmitConsumer"
    
    private let eventName = BTStatisticEventName.base_mobile_performance_submit.rawValue
    
    private var mainStageTimestamps = [String: Any]()
    private var mainStageDurationMaps = [String: Any]()
    
    func consume(trace: BTStatisticBaseTrace, logger: BTStatisticLoggerProvider, currentPoint: BTStatisticNormalPoint, allPoint: [BTStatisticNormalPoint]) -> [BTStatisticNormalPoint] {
        if trace.isStop {
            return []
        }
        BTStatisticLog.logInfo(tag: tag, message: "consume \(currentPoint.name)")
        
        let startTimestamp = (mainStageTimestamps[BTStatisticMainStageName.BASE_ADD_RECORD_SUBMIT_START.rawValue] as? Int) ?? 0
        
        var params = currentPoint.extra
        params[BTStatisticConstant.stage] = currentPoint.name
        
        mainStageTimestamps[currentPoint.name] = currentPoint.timestamp
        mainStageDurationMaps[currentPoint.name] = currentPoint.timestamp - startTimestamp
        
        if currentPoint.name == BTStatisticMainStageName.BASE_ADD_RECORD_APPLY_END.rawValue
            || currentPoint.name == BTStatisticMainStageName.BASE_ADD_RECORD_SUBMIT_FAIL.rawValue {
            // 结束点里带上统计数据
            params[BTStatisticConstant.mainStageTimestampKey] = mainStageTimestamps
            params[BTStatisticConstant.mainStageDurationKey] = mainStageDurationMaps
            
            logger.send(trace: trace, eventName: eventName, params: params)
            trace.isStop = true
            return allPoint
        } else {
            logger.send(trace: trace, eventName: eventName, params: params)
        }
        return []
    }
    
    func consumeTempPoint(trace: BTStatisticBaseTrace, currentPoint: BTStatisticNormalPoint, allPoint: [BTStatisticNormalPoint]) -> [BTStatisticNormalPoint] {
        return []
    }
}
