//
//  BTGridCardReportHelper.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/8.
//

import Foundation

final class BTNativeRenderReportMonitor {
    
    private static let viewSubType = "native_card"
    
    private static var timestamp: Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }
    
    static func reportStart(traceId: String) {
        
    }
    
    static func reportOpenCardViewTTV(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_TTV.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }
    
    static func reportCardViewCellSetData(traceId: String, costTime: Double) {
        let point = BTStatisticNormalPoint(name: BTStatisticEventName.base_mobile_performance_native_grid_card_set_data.rawValue, type: .temp_point, timestamp: timestamp, isUnique: false)
        point.add(extra: [BTStatisticConstant.costTime: costTime])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }
    
    static func reportCardViewCellLayout(traceId: String, costTime: Double) {
        let point = BTStatisticNormalPoint(name: BTStatisticEventName.base_mobile_performance_native_grid_card_layout.rawValue, type: .temp_point, timestamp: timestamp, isUnique: false)
        point.add(extra: [BTStatisticConstant.costTime: costTime])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }
    
    static func reportCardViewCellDraw(traceId: String, costTime: Double) {
        let point = BTStatisticNormalPoint(name: BTStatisticEventName.base_mobile_performance_native_grid_card_draw.rawValue, type: .temp_point, timestamp: timestamp, isUnique: false)
        point.add(extra: [BTStatisticConstant.costTime: costTime])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }
    
    static func reportCardViewGroup(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.NATIVE_RENDER_CARD_VIEW.rawValue, type: .temp_point_group, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }
    
    static func reportCardViewFieldSetData(traceId: String, costTime: Double, fieldUIType: BTFieldUIType) {
        let point = BTStatisticNormalPoint(name: BTStatisticEventName.base_mobile_performance_native_grid_card_field_set_data.rawValue, type: .temp_point, timestamp: timestamp, isUnique: false)
        point.add(extra: [BTStatisticConstant.costTime: costTime])
        point.add(extra: [BTStatisticConstant.fieldUIType: fieldUIType.rawValue])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }
    
    static func reportCardViewFieldLayout(traceId: String, costTime: Double, fieldUIType: BTFieldUIType) {
        let point = BTStatisticNormalPoint(name: BTStatisticEventName.base_mobile_performance_native_grid_card_field_layout.rawValue, type: .temp_point, timestamp: timestamp, isUnique: false)
        point.add(extra: [BTStatisticConstant.costTime: costTime])
        point.add(extra: [BTStatisticConstant.fieldUIType: fieldUIType.rawValue])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }
    
    static func reportCardViewFieldDraw(traceId: String, costTime: Double, fieldUIType: BTFieldUIType) {
        let point = BTStatisticNormalPoint(name: BTStatisticEventName.base_mobile_performance_native_grid_card_field_draw.rawValue, type: .temp_point, timestamp: timestamp, isUnique: false)
        point.add(extra: [BTStatisticConstant.costTime: costTime])
        point.add(extra: [BTStatisticConstant.fieldUIType: fieldUIType.rawValue])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }
    
}
