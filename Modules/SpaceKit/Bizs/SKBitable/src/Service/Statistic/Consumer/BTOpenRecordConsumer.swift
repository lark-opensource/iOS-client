//
//  BTOpenRecordConsumer.swift
//  SKFoundation
//
//  Created by 刘焱龙 on 2023/9/17.
//

import Foundation
import SKFoundation

final class BTOpenRecordConsumer: BTStatisticConsumer, BTStatisticNormalConsumer {
    private let tag = "OpenRecordConsumer"

    private var setRecordCount = 0
    private var reportEnd = false
    private var mainStageTimestamps = [String: Any]()
    private var mainStageDurationMaps = [String: Any]()

    private var cellSetDataCount = 0
    private var cellDrawCount = 0
    private var consumeCellListDraw = false

    private var mustStages: Set<BTStatisticMainStageName> = []

    override init() {
        mustStages = [
            BTStatisticMainStageName.OPEN_RECORD_TTV,
            BTStatisticMainStageName.OPEN_RECORD_TTU
        ]
    }

    func consume(trace: BTStatisticBaseTrace, logger: BTStatisticLoggerProvider, currentPoint: BTStatisticNormalPoint, allPoint: [BTStatisticNormalPoint]) -> [BTStatisticNormalPoint] {
        if reportEnd {
            return []
        }
        BTStatisticLog.logInfo(tag: tag, message: "consume \(currentPoint.name)")

        let startTimestamp = (mainStageTimestamps[BTStatisticMainStageName.OPEN_RECORD_START.rawValue] as? Int) ?? 0

        switch currentPoint.name {
        case BTStatisticMainStageName.OPEN_RECORD_START.rawValue:
            mainStageTimestamps[BTStatisticMainStageName.OPEN_RECORD_START.rawValue] = currentPoint.timestamp
            var params = currentPoint.extra
            params[BTStatisticConstant.stage] = BTStatisticStageType.start.rawValue
            logger.send(trace: trace, eventName: BTStatisticEventName.base_mobile_performance_open_record.rawValue, params: params)
            return []
        case BTStatisticMainStageName.OPEN_RECORD_SET_RECORD.rawValue:
            if setRecordCount == 0 {
                mainStageTimestamps[BTStatisticMainStageName.OPEN_RECORD_SET_RECORD.rawValue] = currentPoint.timestamp
                mainStageDurationMaps[BTStatisticMainStageName.OPEN_RECORD_SET_RECORD.rawValue] = currentPoint.timestamp - startTimestamp
            }
            if currentPoint.type == .stage_start {
                setRecordCount += 1
            }
            return []
        case BTStatisticMainStageName.OPEN_RECORD_TTV_NOTIFY_DATA_CHANGED.rawValue:
            mainStageTimestamps[BTStatisticMainStageName.OPEN_RECORD_TTV_NOTIFY_DATA_CHANGED.rawValue] = currentPoint.timestamp
            return []
        case BTStatisticMainStageName.OPEN_RECORD_TTU_NOTIFY_DATA_CHANGED.rawValue:
            mainStageTimestamps[BTStatisticMainStageName.OPEN_RECORD_TTU_NOTIFY_DATA_CHANGED.rawValue] = currentPoint.timestamp
            return []
        case BTStatisticMainStageName.OPEN_RECORD_TTV.rawValue:
            mainStageTimestamps[BTStatisticMainStageName.OPEN_RECORD_TTV.rawValue] = currentPoint.timestamp
            mainStageDurationMaps[BTStatisticMainStageName.OPEN_RECORD_TTV.rawValue] = currentPoint.timestamp - startTimestamp

            mustStages.remove(BTStatisticMainStageName.OPEN_RECORD_TTV)
        case BTStatisticMainStageName.OPEN_RECORD_TTU.rawValue:
            mainStageTimestamps[BTStatisticMainStageName.OPEN_RECORD_TTU.rawValue] = currentPoint.timestamp
            mainStageDurationMaps[BTStatisticMainStageName.OPEN_RECORD_TTU.rawValue] = currentPoint.timestamp - startTimestamp

            mustStages.remove(BTStatisticMainStageName.OPEN_RECORD_TTU)
        case BTStatisticMainStageName.OPEN_RECORD_FAIL.rawValue:
            mainStageTimestamps[BTStatisticMainStageName.OPEN_RECORD_FAIL.rawValue] = currentPoint.timestamp
            mainStageDurationMaps[BTStatisticMainStageName.OPEN_RECORD_FAIL.rawValue] = currentPoint.timestamp - startTimestamp
            var params = currentPoint.extra
            params[BTStatisticConstant.stage] = BTStatisticMainStageName.OPEN_RECORD_FAIL.rawValue
            logger.send(trace: trace, eventName: BTStatisticEventName.base_mobile_performance_open_record.rawValue, params: params)
            reportEnd = true

            trace.isStop = true
        default:
            mainStageTimestamps[currentPoint.name] = currentPoint.timestamp
            mainStageDurationMaps[currentPoint.name] = currentPoint.timestamp - startTimestamp
            var params = currentPoint.extra
            params[BTStatisticConstant.stage] = currentPoint.name
            logger.send(trace: trace, eventName: BTStatisticEventName.base_mobile_performance_open_record.rawValue, params: params)
        }

        if mustStages.isEmpty {
            var params = currentPoint.extra
            params[BTStatisticConstant.stage] = BTStatisticStageType.end.rawValue
            params[BTStatisticConstant.result] = BTStatisticEventResult.success.rawValue
            params[BTStatisticConstant.mainStageTimestampKey] = mainStageTimestamps
            params[BTStatisticConstant.mainStageDurationKey] = mainStageDurationMaps
            params["ttv_set_record_count"] = setRecordCount
            params["ttv_cell_set_data_count"] = cellSetDataCount
            params["ttv_cell_draw_count"] = cellDrawCount
            logger.send(trace: trace, eventName: BTStatisticEventName.base_mobile_performance_open_record.rawValue, params: params)
            reportEnd = true

            trace.isStop = true
            return allPoint
        }

        return []
    }

    func consumeTempPoint(trace: BTStatisticBaseTrace, currentPoint: BTStatisticNormalPoint, allPoint: [BTStatisticNormalPoint]) -> [BTStatisticNormalPoint] {
        if consumeCellListDraw {
            return []
        }
        BTStatisticLog.logInfo(tag: tag, message: "consume \(currentPoint.name)")
        if currentPoint.name == BTStatisticMainStageName.OPEN_RECORD_CELL_LIST.rawValue {
            consumeCellListDraw = true
            allPoint.forEach { point in
                switch point.name {
                case BTStatisticMainStageName.OPEN_RECORD_CELL_SET_DATA.rawValue:
                    cellSetDataCount += 1
                case BTStatisticMainStageName.OPEN_RECORD_CELL_DRAW.rawValue:
                    cellDrawCount += 1
                default:
                    break
                }
            }
        }
        return []
    }
}
