//
//  BTNativeRenderConsumer.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/9.
//

import Foundation
import SKFoundation

final class BTNativeRenderConsumer: BTStatisticConsumer, BTStatisticNormalConsumer {
    
    private let tag = "BTNativeRenderConsumer"
    
    func consume(trace: BTStatisticBaseTrace, logger: BTStatisticLoggerProvider, currentPoint: BTStatisticNormalPoint, allPoint: [BTStatisticNormalPoint]) -> [BTStatisticNormalPoint] {
        if currentPoint.name == BTStatisticMainStageName.NATIVE_RENDER_CARD_VIEW.rawValue {
            logger.send(
                trace: trace,
                eventName: BTStatisticEventName.base_mobile_performance_native_grid_card.rawValue,
                params: currentPoint.extra)
        } else if currentPoint.name == BTStatisticMainStageName.NATIVE_RENDER_CARD_FIELD.rawValue {
            logger.send(
                trace: trace,
                eventName: BTStatisticEventName.base_mobile_performance_native_grid_card_field.rawValue,
                params: currentPoint.extra)
        }
        return []
    }
    
    func consumeTempPoint(trace: BTStatisticBaseTrace, currentPoint: BTStatisticNormalPoint, allPoint: [BTStatisticNormalPoint]) -> [BTStatisticNormalPoint] {
        let cardModel = TimeModel()
        var fieldModelMap = [String: TimeModel]()
        if currentPoint.name == BTStatisticMainStageName.NATIVE_RENDER_CARD_VIEW.rawValue {
            allPoint.forEach { point in
                switch point.name {
                case BTStatisticEventName.base_mobile_performance_native_grid_card_set_data.rawValue:
                    guard let costTime = point.extra[BTStatisticConstant.costTime] as? Double else {
                        return
                    }
                    cardModel.setData.add(costTime)
                case BTStatisticEventName.base_mobile_performance_native_grid_card_layout.rawValue:
                    guard let costTime = point.extra[BTStatisticConstant.costTime] as? Double else {
                        return
                    }
                    cardModel.layout.add(costTime)
                case BTStatisticEventName.base_mobile_performance_native_grid_card_draw.rawValue:
                    guard let costTime = point.extra[BTStatisticConstant.costTime] as? Double else {
                        return
                    }
                    cardModel.draw.add(costTime)
                case BTStatisticEventName.base_mobile_performance_native_grid_card_field_set_data.rawValue:
                    guard let fieldUIType = point.extra[BTStatisticConstant.fieldUIType] as? String else {
                        return
                    }
                    guard let costTime = point.extra[BTStatisticConstant.costTime] as? Double else {
                        return
                    }
                    if let model = fieldModelMap[fieldUIType] {
                        model.setData.add(costTime)
                    } else {
                        let newModel = TimeModel()
                        newModel.setData.add(costTime)
                        fieldModelMap[fieldUIType] = newModel
                    }
                case BTStatisticEventName.base_mobile_performance_native_grid_card_field_layout.rawValue:
                    guard let fieldUIType = point.extra[BTStatisticConstant.fieldUIType] as? String else {
                        return
                    }
                    guard let costTime = point.extra[BTStatisticConstant.costTime] as? Double else {
                        return
                    }
                    if let model = fieldModelMap[fieldUIType] {
                        model.layout.add(costTime)
                    } else {
                        let newModel = TimeModel()
                        newModel.layout.add(costTime)
                        fieldModelMap[fieldUIType] = newModel
                    }
                case BTStatisticEventName.base_mobile_performance_native_grid_card_field_draw.rawValue:
                    guard let fieldUIType = point.extra[BTStatisticConstant.fieldUIType] as? String else {
                        return
                    }
                    guard let costTime = point.extra[BTStatisticConstant.costTime] as? Double else {
                        return
                    }
                    if let model = fieldModelMap[fieldUIType] {
                        model.draw.add(costTime)
                    } else {
                        let newModel = TimeModel()
                        newModel.draw.add(costTime)
                        fieldModelMap[fieldUIType] = newModel
                    }
                default:
                    break
                }
            }
            let cardPoint: BTStatisticNormalPoint = BTStatisticNormalPoint(
                name: BTStatisticMainStageName.NATIVE_RENDER_CARD_VIEW.rawValue,
                type: .stage_end,
                extra: [
                    "set_data_avg": cardModel.setData.avarage(),
                    "layout_avg": cardModel.layout.avarage(),
                    "draw_avg": cardModel.draw.avarage()
                ]
            )
            var cellPoints: [BTStatisticNormalPoint] = fieldModelMap.compactMap { (uiType, timeModel) in
                return BTStatisticNormalPoint(
                    name: BTStatisticMainStageName.NATIVE_RENDER_CARD_FIELD.rawValue,
                    type: .stage_end,
                    extra: [
                        "field_ui_type": uiType,
                        "set_data_avg": timeModel.setData.avarage(),
                        "layout_avg": timeModel.layout.avarage(),
                        "draw_avg": timeModel.draw.avarage()
                    ]
                )
            }
            cellPoints.append(cardPoint)
            return cellPoints
        }
        return []
    }
    
}

fileprivate class TimeModel {
    var setData = Caculator()
    var layout = Caculator()
    var draw = Caculator()
}

fileprivate class Caculator {
    
    private var totalCount: Int = 0
    private var totalValue: Double = 0
    
    func add(_ value: Double) {
        guard value > 0 else {
            return
        }
        totalCount += 1
        totalValue += value
    }
    
    func avarage() -> Double {
        guard totalCount > 0, totalValue > 0 else {
            return 0
        }
        return totalValue / Double(totalCount)
    }
}



