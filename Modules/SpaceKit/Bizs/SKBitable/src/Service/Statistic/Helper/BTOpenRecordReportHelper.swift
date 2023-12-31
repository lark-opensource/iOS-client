//
//  BTOpenRecordReportHelper.swift
//  SKBrowser
//
//  Created by 刘焱龙 on 2023/8/29.
//

import Foundation
import SKCommon
import SKFoundation

final class BTOpenRecordReportHelper {
    private static var timestamp: Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }

    static func reportStart(
        traceId: String,
        viewMode: BTViewMode,
        isBitableReady: Bool,
        recordId: String
    ) {
        let extra =
        [
            BTStatisticConstant.openType: viewMode.openType.rawValue,
            BTStatisticConstant.isBitableReady: isBitableReady,
            BTStatisticConstant.tableType: viewMode.trackValue,
            BTStatisticConstant.recordId: DocsTracker.encrypt(id: recordId)
        ] as [String : Any]
        BTStatisticManager.shared?.addTraceExtra(traceId: traceId, extra: extra)
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_RECORD_START.rawValue, type: .init_point, timestamp: timestamp, extra: extra)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportSetRecord(traceId: String, end: Bool = false) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_RECORD_SET_RECORD.rawValue, type: end ? .stage_end : .stage_start, timestamp: timestamp, isUnique: false)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportTTVNotifyDataChanged(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_RECORD_TTV_NOTIFY_DATA_CHANGED.rawValue, timestamp: timestamp, isUnique: false)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportTTV(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_RECORD_TTV.rawValue, timestamp: timestamp, isUnique: false)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportTTUNotifyDataChanged(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_RECORD_TTU_NOTIFY_DATA_CHANGED.rawValue, timestamp: timestamp, isUnique: false)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportTTU(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_RECORD_TTU.rawValue, timestamp: timestamp, isUnique: false)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportOpenFail(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_RECORD_FAIL.rawValue, timestamp: timestamp, isUnique: false)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportBitableReady(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_RECORD_BITABLE_READY.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportCellSetData(traceId: String, costTime: Double, uiType: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_RECORD_CELL_SET_DATA.rawValue, type: .temp_point, timestamp: timestamp, isUnique: false)
        point.add(extra: [BTStatisticConstant.costTime: costTime])
        point.add(extra: [BTStatisticConstant.fieldUIType: uiType])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportCellDrawTime(traceId: String, uiType: String, drawTime: [Double], drawCount: [Int], costTime: Double) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_RECORD_CELL_DRAW.rawValue, type: .temp_point, timestamp: timestamp, isUnique: false)
        point.add(extra: [BTStatisticConstant.costTime: costTime])
        point.add(extra: [BTStatisticConstant.fieldUIType: uiType])
        point.add(extra: [BTStatisticConstant.costTimeList: drawTime])
        point.add(extra: [BTStatisticConstant.countList: drawCount])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportCellListGroup(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_RECORD_CELL_LIST.rawValue, type: .temp_point_group, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }
}
