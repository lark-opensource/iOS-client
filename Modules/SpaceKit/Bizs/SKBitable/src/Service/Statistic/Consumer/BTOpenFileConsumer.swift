//
//  BTOpenFileConsumer.swift
//  SKFoundation
//
//  Created by 刘焱龙 on 2023/9/17.
//

import Foundation
import SKFoundation

final class BTOpenFileConsumer: BTStatisticConsumer, BTStatisticNormalConsumer {
    private static let tag = "OpenFileConsumer"

    private var hasTTV = false
    private var hasTTU = false
    private var mainStageTimestamps = [String: Any]()
    private var mainStageDurationMaps = [String: Any]()

    private var mustStages: Set<BTStatisticMainStageName> = []

    init(type: BTStatisticOpenFileType) {
        switch type {
        case .share_record:
            mustStages = [
                .OPEN_FILE_TTV,
                .OPEN_FILE_TTU
            ]
            break
        case .base_add:
            mustStages = [
                .OPEN_FILE_TTV,
                .OPEN_FILE_TTU
            ]
        case .main:
            mustStages = [
                .OPEN_FILE_SDK_FIRST_PAINT,
                .OPEN_FILE_TTV,
                .OPEN_FILE_TTU
            ]
        }
    }

    func consume(trace: BTStatisticBaseTrace, logger: BTStatisticLoggerProvider, currentPoint: BTStatisticNormalPoint, allPoint: [BTStatisticNormalPoint]) -> [BTStatisticNormalPoint] {
        if trace.isStop {
            BTStatisticLog.logInfo(tag: Self.tag, message: "consume end, \(currentPoint.name)")
            return []
        }
        BTStatisticLog.logInfo(tag: Self.tag, message: "consume \(currentPoint.name)")

        let startTimestamp = (mainStageTimestamps[BTStatisticMainStageName.OPEN_FILE_START.rawValue] as? Int) ?? 0
        let extra = trace.getExtra(includeParent: false)
        let isBaseAdd = (extra[BTStatisticConstant.openType] as? String) == BTStatisticOpenFileType.base_add.rawValue
        
        switch currentPoint.name {
        case BTStatisticMainStageName.OPEN_FILE_START.rawValue:
            mainStageTimestamps[BTStatisticMainStageName.OPEN_FILE_START.rawValue] = currentPoint.timestamp
            var params = currentPoint.extra
            params[BTStatisticConstant.stage] = BTStatisticStageType.start.rawValue
            logger.send(trace: trace, eventName: BTStatisticEventName.base_mobile_performance_open_file.rawValue, params: params)
            return []
        case BTStatisticMainStageName.OPEN_FILE_SDK_FIRST_PAINT.rawValue:
            mainStageTimestamps[BTStatisticMainStageName.OPEN_FILE_SDK_FIRST_PAINT.rawValue] = currentPoint.timestamp
            mainStageDurationMaps[BTStatisticMainStageName.OPEN_FILE_SDK_FIRST_PAINT.rawValue] = currentPoint.timestamp - startTimestamp
            var params = currentPoint.extra
            params[BTStatisticConstant.stage] = BTStatisticMainStageName.OPEN_FILE_SDK_FIRST_PAINT.rawValue
            logger.send(trace: trace, eventName: BTStatisticEventName.base_mobile_performance_open_file.rawValue, params: params)

            mustStages.remove(.OPEN_FILE_SDK_FIRST_PAINT)
        case BTStatisticMainStageName.POINT_VIEW_OR_BLOCK_SWITCH.rawValue:
            mainStageTimestamps[BTStatisticMainStageName.OPEN_FILE_CANCEL.rawValue] = currentPoint.timestamp
            mainStageDurationMaps[BTStatisticMainStageName.OPEN_FILE_CANCEL.rawValue] = currentPoint.timestamp - startTimestamp
            var params = currentPoint.extra
            params[BTStatisticConstant.stage] = BTStatisticStageType.end.rawValue
            params[BTStatisticConstant.result] = BTStatisticEventResult.cancel.rawValue
            params[BTStatisticConstant.reason] = "switchView"
            params[BTStatisticConstant.mainStageTimestampKey] = mainStageTimestamps
            params[BTStatisticConstant.mainStageDurationKey] = mainStageDurationMaps
            logger.send(trace: trace, eventName: BTStatisticEventName.base_mobile_performance_open_file.rawValue, params: params)

            trace.isStop = true
            return allPoint
        case BTStatisticMainStageName.OPEN_FILE_CANCEL.rawValue:
            mainStageTimestamps[BTStatisticMainStageName.OPEN_FILE_CANCEL.rawValue] = currentPoint.timestamp
            mainStageDurationMaps[BTStatisticMainStageName.OPEN_FILE_CANCEL.rawValue] = currentPoint.timestamp - startTimestamp
            var params = currentPoint.extra
            params[BTStatisticConstant.stage] = BTStatisticStageType.end.rawValue
            params[BTStatisticConstant.result] = BTStatisticEventResult.cancel.rawValue
            if params[BTStatisticConstant.reason] == nil {
                params[BTStatisticConstant.reason] = "cancel"
            }
            params[BTStatisticConstant.mainStageTimestampKey] = mainStageTimestamps
            params[BTStatisticConstant.mainStageDurationKey] = mainStageDurationMaps
            logger.send(trace: trace, eventName: BTStatisticEventName.base_mobile_performance_open_file.rawValue, params: params)

            trace.isStop = true
            return allPoint
        case BTStatisticMainStageName.OPEN_FILE_FAIL.rawValue:
            mainStageTimestamps[BTStatisticMainStageName.OPEN_FILE_FAIL.rawValue] = currentPoint.timestamp
            mainStageDurationMaps[BTStatisticMainStageName.OPEN_FILE_FAIL.rawValue] = currentPoint.timestamp - startTimestamp

            var params = currentPoint.extra
            params[BTStatisticConstant.stage] = BTStatisticStageType.end.rawValue
            params[BTStatisticConstant.result] = BTStatisticEventResult.fail.rawValue
            params[BTStatisticConstant.mainStageTimestampKey] = mainStageTimestamps
            params[BTStatisticConstant.mainStageDurationKey] = mainStageDurationMaps
            logger.send(trace: trace, eventName: BTStatisticEventName.base_mobile_performance_open_file.rawValue, params: params)

            trace.isStop = true
            return allPoint
        case BTStatisticMainStageName.OPEN_FILE_TTV.rawValue:
            mainStageTimestamps[BTStatisticMainStageName.OPEN_FILE_TTV.rawValue] = currentPoint.timestamp
            mainStageDurationMaps[BTStatisticMainStageName.OPEN_FILE_TTV.rawValue] = currentPoint.timestamp - startTimestamp
			if isBaseAdd {
                var params = currentPoint.extra
                params[BTStatisticConstant.stage] = currentPoint.name
                logger.send(trace: trace, eventName: BTStatisticEventName.base_mobile_performance_open_file.rawValue, params: params)
            }
            mustStages.remove(BTStatisticMainStageName.OPEN_FILE_TTV)
        case BTStatisticMainStageName.OPEN_FILE_TTU.rawValue:
            mainStageTimestamps[BTStatisticMainStageName.OPEN_FILE_TTU.rawValue] = currentPoint.timestamp
            mainStageDurationMaps[BTStatisticMainStageName.OPEN_FILE_TTU.rawValue] = currentPoint.timestamp - startTimestamp
			if isBaseAdd {
                var params = currentPoint.extra
                params[BTStatisticConstant.stage] = currentPoint.name
                logger.send(trace: trace, eventName: BTStatisticEventName.base_mobile_performance_open_file.rawValue, params: params)
            }
            mustStages.remove(BTStatisticMainStageName.OPEN_FILE_TTU)
        case BTStatisticMainStageName.BITABLE_SDK_LOAD_COST.rawValue:
            let sdkCost = (currentPoint.extra[BTStatisticConstant.sdkCost] as? [String: Any]) ?? [:]
            mainStageTimestamps[BTStatisticConstant.sdkCost] = sdkCost

            if (currentPoint.extra["sdk_cost_source"] as? String) == "show_card" {
                var params = currentPoint.extra
                params[BTStatisticConstant.stage] = currentPoint.name
                logger.send(trace: trace, eventName: BTStatisticEventName.base_mobile_performance_open_file.rawValue, params: params)

                mustStages.remove(BTStatisticMainStageName.BITABLE_SDK_LOAD_COST)
            } else {
                return []
            }
        default:
            mainStageTimestamps[currentPoint.name] = currentPoint.timestamp
            mainStageDurationMaps[currentPoint.name] = currentPoint.timestamp - startTimestamp
            var params = currentPoint.extra
            params[BTStatisticConstant.stage] = currentPoint.name
            logger.send(trace: trace, eventName: BTStatisticEventName.base_mobile_performance_open_file.rawValue, params: params)
        }

        if mustStages.isEmpty {
            adjustStageTTUBeforeReport()

            var params = currentPoint.extra
            params[BTStatisticConstant.stage] = BTStatisticStageType.end.rawValue
            params[BTStatisticConstant.result] = BTStatisticEventResult.success.rawValue
            params[BTStatisticConstant.mainStageTimestampKey] = mainStageTimestamps
            params[BTStatisticConstant.mainStageDurationKey] = mainStageDurationMaps
            logger.send(
                trace: trace,
                eventName: BTStatisticEventName.base_mobile_performance_open_file.rawValue,
                params: params
            )

            trace.isStop = true
            return allPoint
        }
        return []
    }

    func consumeTempPoint(trace: BTStatisticBaseTrace, currentPoint: BTStatisticNormalPoint, allPoint: [BTStatisticNormalPoint]) -> [BTStatisticNormalPoint] {
        return []
    }

    private func adjustStageTTUBeforeReport() {
        guard let ttuTimestamp = mainStageTimestamps[BTStatisticMainStageName.OPEN_FILE_TTU.rawValue] as? Int,
              let ttuDuration = mainStageDurationMaps[BTStatisticMainStageName.OPEN_FILE_TTU.rawValue] as? Int,
              let ttvTimestamp = mainStageTimestamps[BTStatisticMainStageName.OPEN_FILE_TTV.rawValue] as? Int,
              let ttvDuration = mainStageDurationMaps[BTStatisticMainStageName.OPEN_FILE_TTV.rawValue] as? Int else {
            return
        }
        // 视图未渲染结束的 ttu 无意义，所以这里取 sdk bitableIsReady 和 ttv 视图渲染结束两个时间的最大值
        mainStageTimestamps[BTStatisticMainStageName.OPEN_FILE_TTU.rawValue] = max(ttuTimestamp, ttvTimestamp)
        mainStageDurationMaps[BTStatisticMainStageName.OPEN_FILE_TTU.rawValue] = max(ttuDuration, ttvDuration)
    }
}
