//
//  BTOpenHomeReportMonitor.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/11/26.
//

import Foundation
import SKCommon

extension BaseHomeContext {
    static let openHomeTraceId = "OPEN_HOME_TRACE_ID"

    mutating func addExtra(key: String?, value: String?, overwrite: Bool = false) {
        guard let key = key, let value = value else {
            return
        }
        if extraInfos == nil {
            extraInfos = [key: value]
        } else {
            if extraInfos?[key] == nil || overwrite {
                extraInfos?[key] = value
            }
        }
    }

    var traceId: String? {
        return extraInfos?[Self.openHomeTraceId]
    }
}

final class BTOpenHomeReportMonitor {
    private static var timestamp: Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }

    static func reportStart(context: BaseHomeContext) -> String? {
        guard let traceId = BTStatisticManager.shared?.createNormalTrace(parentTrace: nil) else {
            return nil
        }

        let consumer = BTStatisticOpenHomeConsumer()
        BTStatisticManager.shared?.addNormalConsumer(traceId: traceId, consumer: consumer)

        BTStatisticManager.shared?.addTraceExtra(traceId: traceId, extra: [
            "from": context.containerEnv.rawValue
        ])

        let point = BTStatisticNormalPoint(name:  BTStatisticMainStageName.OPEN_HOME_START.rawValue, type: .init_point)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)

        return traceId
    }

    static func reportXYZStart(context: BaseHomeContext) {
        guard let traceId = context.traceId else {
            return
        }
        let point = BTStatisticNormalPoint(name:  BTStatisticMainStageName.OPEN_HOME_XYZ_START.rawValue)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportXYZEnd(context: BaseHomeContext, from: TabLoadFrom, scene: BitableHomeScene) {
        guard let traceId = context.traceId else {
            return
        }

        let extra = ["tab_load_from": from.rawValue, "scene": scene.rawValue]
        BTStatisticManager.shared?.addTraceExtra(
            traceId: traceId,
            extra: extra
        )

        let point = BTStatisticNormalPoint(name:  BTStatisticMainStageName.OPEN_HOME_XYZ_END.rawValue, extra: extra)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportRecommendLoadDataEnd(context: BaseHomeContext, isCache: Bool) {
        guard let traceId = context.traceId else {
            return
        }
        BTStatisticManager.shared?.addTraceExtra(traceId: traceId, extra: ["is_recommend_cache": isCache ? "true" : "false"])
        let point = BTStatisticNormalPoint(name: BTStatisticOpenHomeLoadType.recommend.loadStage)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportDashboardLoadDataEnd(context: BaseHomeContext, isCache: Bool) {
        guard let traceId = context.traceId else {
            return
        }
        BTStatisticManager.shared?.addTraceExtra(traceId: traceId, extra: ["is_dashboard_cache": isCache ? "true" : "false"])
        let point = BTStatisticNormalPoint(name: BTStatisticOpenHomeLoadType.dashboard.loadStage)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportFileListLoadDataEnd(context: BaseHomeContext) {
        guard let traceId = context.traceId else {
            return
        }
        let point = BTStatisticNormalPoint(name: BTStatisticOpenHomeLoadType.file.loadStage)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportTTV(context: BaseHomeContext, type: BTStatisticOpenHomeLoadType) {
        guard let traceId = context.traceId else {
            return
        }
        let point = BTStatisticNormalPoint(name: type.ttvStage)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportCancel(context: BaseHomeContext, type: BTStatisticOpenHomeCancelType) {
        guard let traceId = context.traceId else {
            return
        }
        let point = BTStatisticNormalPoint(
            name: BTStatisticMainStageName.OPEN_HOME_CANCEL.rawValue,
            extra: [BTStatisticConstant.reason: type.rawValue]
        )
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportFail(context: BaseHomeContext, type: BTStatisticOpenHomeFailType, detail: String, extra: [String: Any] = [:]) {
        guard let traceId = context.traceId else {
            return
        }
        var realExtra = extra
        realExtra.merge(other: [BTStatisticConstant.reason: type.rawValue, "detail": detail])
        let point = BTStatisticNormalPoint(
            name: BTStatisticMainStageName.OPEN_HOME_FAIL.rawValue,
            extra: realExtra
        )
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }
}
