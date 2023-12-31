//
//  BTStatisticOpenHomeConsumer.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/11/26.
//

import Foundation

final class BTStatisticOpenHomeConsumer: BTStatisticConsumer, BTStatisticNormalConsumer, BTStatisticConsumerDurationProtocol {
    private static let tag = "BTStatisticOpenHomeConsumer"
    private static let startStageKey = BTStatisticMainStageName.OPEN_HOME_START

    private var mustStages: Set<BTStatisticMainStageName> = []
    var eventName = BTStatisticEventName.base_mobile_performance_enter_homepage
    var mainStageTimestamps = [String: Any]()
    var mainStageDurationMaps = [String: Any]()

    private func updateMustStages(scene: BitableHomeScene) {
        if scene == .homepage {
            mustStages = [
                .OPEN_HOME_TTV_FILE,
                .OPEN_HOME_TTV_DASHBOARD
            ]
        } else if scene == .recommend {
            mustStages = [
                .OPEN_HOME_TTV_RECOMMEND
            ]
        }
    }

    func consume(trace: BTStatisticBaseTrace, logger: BTStatisticLoggerProvider, currentPoint: BTStatisticNormalPoint, allPoint: [BTStatisticNormalPoint]) -> [BTStatisticNormalPoint] {
        if trace.isStop {
            BTStatisticLog.logInfo(tag: Self.tag, message: "consume end, \(currentPoint.name)")
            return []
        }
        BTStatisticLog.logInfo(tag: Self.tag, message: "consume \(currentPoint.name)")
        
        switch currentPoint.name {
        case BTStatisticMainStageName.OPEN_HOME_END.rawValue:
            logEnd(type: .success, trace: trace, logger: logger, currentPoint: currentPoint)
            return []
        case BTStatisticMainStageName.OPEN_HOME_CANCEL.rawValue:
            logEnd(type: .cancel, trace: trace, logger: logger, currentPoint: currentPoint)
            return []
        case BTStatisticMainStageName.OPEN_HOME_FAIL.rawValue:
            logEnd(type: .fail, trace: trace, logger: logger, currentPoint: currentPoint)
            return []
        case BTStatisticMainStageName.OPEN_HOME_XYZ_END.rawValue:
            guard let sceneString = currentPoint.extra["scene"] as? String, let scene = BitableHomeScene(rawValue: sceneString) else {
                return allPoint
            }
            updateMustStages(scene: scene)

            defaultLog(trace: trace, logger: logger, currentPoint: currentPoint)
        case BTStatisticMainStageName.OPEN_HOME_TTV_FILE.rawValue:
            mustStages.remove(.OPEN_HOME_TTV_FILE)
            defaultLog(trace: trace, logger: logger, currentPoint: currentPoint)
        case BTStatisticMainStageName.OPEN_HOME_TTV_DASHBOARD.rawValue:
            mustStages.remove(.OPEN_HOME_TTV_DASHBOARD)
            defaultLog(trace: trace, logger: logger, currentPoint: currentPoint)
        case BTStatisticMainStageName.OPEN_HOME_TTV_RECOMMEND.rawValue:
            mustStages.remove(.OPEN_HOME_TTV_RECOMMEND)
            defaultLog(trace: trace, logger: logger, currentPoint: currentPoint)
        default:
            defaultLog(trace: trace, logger: logger, currentPoint: currentPoint)
            return []
        }

        if mustStages.isEmpty {
            logEnd(type: .success, trace: trace, logger: logger, currentPoint: currentPoint)
            return allPoint
        }

        return []
    }

    func updateDuration(currentPoint: BTStatisticNormalPoint) {
        let startTimestamp = (mainStageTimestamps[Self.startStageKey.rawValue] as? Int) ?? 0

        mainStageTimestamps[currentPoint.name] = currentPoint.timestamp
        mainStageDurationMaps[currentPoint.name] = currentPoint.timestamp - startTimestamp
    }
}
