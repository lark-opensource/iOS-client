//
//  BTRecordCellConsumer.swift
//  SKFoundation
//
//  Created by 刘焱龙 on 2023/9/17.
//

import Foundation
import SKFoundation

final class BTRecordCellConsumer: BTStatisticConsumer, BTStatisticNormalConsumer {
    private let tag = "RecordCellConsumer"

    func consume(trace: BTStatisticBaseTrace, logger: BTStatisticLoggerProvider, currentPoint: BTStatisticNormalPoint, allPoint: [BTStatisticNormalPoint]) -> [BTStatisticNormalPoint] {
        if currentPoint.name == BTStatisticMainStageName.OPEN_RECORD_CELL_LIST.rawValue {
            logger.send(
                trace: trace,
                eventName: BTStatisticEventName.base_mobile_performance_record_cell.rawValue, params: currentPoint.extra)
        }
        return []
    }

    func consumeTempPoint(trace: BTStatisticBaseTrace, currentPoint: BTStatisticNormalPoint, allPoint: [BTStatisticNormalPoint]) -> [BTStatisticNormalPoint] {
        if currentPoint.name == BTStatisticMainStageName.OPEN_RECORD_CELL_LIST.rawValue {
            var fieldTypeCellTimeMap = [String: CellTimeModel]()
            allPoint.forEach { point in
                switch point.name {
                case BTStatisticMainStageName.OPEN_RECORD_CELL_SET_DATA.rawValue:
                    guard let fieldUIType = point.extra[BTStatisticConstant.fieldUIType] as? String else {
                        return
                    }
                    guard let costTime = point.extra[BTStatisticConstant.costTime] as? Double else {
                        return
                    }
                    var timeModel = CellTimeModel()
                    if let current = fieldTypeCellTimeMap[fieldUIType] {
                        timeModel = current
                    }
                    timeModel.updateTime(type: .setData, time: Float(costTime))
                    fieldTypeCellTimeMap[fieldUIType] = timeModel
                case BTStatisticMainStageName.OPEN_RECORD_CELL_DRAW.rawValue:
                    guard let fieldUIType = point.extra[BTStatisticConstant.fieldUIType] as? String else {
                        return
                    }
                    guard let costTime = point.extra[BTStatisticConstant.costTime] as? Double else {
                        return
                    }
                    var timeModel = CellTimeModel()
                    if let current = fieldTypeCellTimeMap[fieldUIType] {
                        timeModel = current
                    }
                    timeModel.updateTime(type: .draw, time: Float(costTime))
                    fieldTypeCellTimeMap[fieldUIType] = timeModel
                default:
                    break
                }
            }

            if fieldTypeCellTimeMap.isEmpty {
                return []
            }
            var cancelConsume = false
            let timeMap = CellTimeMap()
            for (key, value) in fieldTypeCellTimeMap {
                if value.count.setData == 0 || value.count.draw == 0 {
                    cancelConsume = true
                    break
                }
                timeMap.avg.setData[key] = value.getAvg(type: .setData)
                timeMap.max.setData[key] = value.getMax(type: .setData)
                timeMap.avg10ms.setData[key] = value.getAvg10ms(type: .setData)
                timeMap.avg.draw[key] = value.getAvg(type: .draw)
                timeMap.max.draw[key] = value.getMax(type: .draw)
                timeMap.avg10ms.draw[key] = value.getAvg10ms(type: .draw)
            }
            if cancelConsume {
                return []
            }
            let point = BTStatisticNormalPoint(
                name: BTStatisticMainStageName.OPEN_RECORD_CELL_LIST.rawValue,
                type: .stage_end,
                extra: [
                    "set_data_avg": timeMap.avg.setData,
                    "draw_avg": timeMap.avg.draw,
                    "set_data_max": timeMap.max.setData,
                    "draw_max": timeMap.max.draw,
                    "set_data_10ms_avg": timeMap.avg10ms.setData,
                    "draw_10ms_avg": timeMap.avg10ms.draw
                ]
            )
            return [point]
        }
        return []
    }
}

final class CellTimeMap {
    // 平均耗时, key 是 FieldUIType, value 是 mills
    var avg: (setData: [String: Float], draw: [String: Float]) = ([String: Float](), [String: Float]())
    // 最大耗时, key 是 FieldUIType, value 是 mills
    var max: (setData: [String: Float], draw: [String: Float]) = ([String: Float](), [String: Float]())
    // 大于 10ms 的平均耗时, key 是 FieldUIType, value 是 mills
    var avg10ms: (setData: [String: Float], draw: [String: Float]) = ([String: Float](), [String: Float]())
}

final class CellTimeModel {
    enum TimeType {
        case setData
        case draw
    }
    private let mills10: Float = 10.0

    // 总耗时
    private var sum: (setData: Float, draw: Float) = (0, 0)
    // 次数
    var count: (setData: Int, draw: Int) = (0, 0)
    // 最大的单次耗时
    private var max: (setData: Float, draw: Float) = (0, 0)
    // 单次大于 10ms 的总耗时
    private var sum10: (setData: Float, draw: Float) = (0, 0)
    // 单于 10ms 的次数
    private var count10: (setData: Int, draw: Int) = (0, 0)

    func updateTime(type: TimeType, time: Float) {
        switch type {
        case .setData:
            sum.setData += time
            count.setData += 1
            max.setData = Swift.max(max.setData, time)
            if time >= mills10 {
                sum10.setData += time
                count10.setData += 1
            }
        case .draw:
            sum.draw += time
            count.draw += 1
            max.draw = Swift.max(max.setData, time)
            if time >= mills10 {
                sum10.draw += time
                count10.draw += 1
            }
        }
    }

    func getAvg(type: TimeType) -> Float? {
        switch type {
        case .setData:
            if count.setData == 0 {
                return nil
            }
            return sum.setData / Float(count.setData)
        case .draw:
            if count.draw == 0 {
                return nil
            }
            return sum.draw / Float(count.draw)
        }
    }

    func getMax(type: TimeType) -> Float? {
        switch type {
        case .setData:
            return max.setData
        case .draw:
            return max.draw
        }
    }

    func getAvg10ms(type: TimeType) -> Float? {
        switch type {
        case .setData:
            if count10.setData == 0 {
                return nil
            }
            return sum10.setData / Float(count10.setData)
        case .draw:
            if count10.draw == 0 {
                return nil
            }
            return sum10.draw / Float(count10.draw)
        }
    }
}
