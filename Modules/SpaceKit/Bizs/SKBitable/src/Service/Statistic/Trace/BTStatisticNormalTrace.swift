//
//  BTStatisticNormalTrace.swift
//  SKFoundation
//
//  Created by 刘焱龙 on 2023/9/9.
//

import Foundation
import SKFoundation

final class BTStatisticNormalTrace: BTStatisticBaseTrace {
    private static let tag = "NormalTrace"
    private static let max_retry_count = 3
    private static let warning_count = 3

    private var points = [BTStatisticNormalPoint]()
    private var tempPoints = [BTStatisticNormalPoint]()

    init(parentTraceId: String?, traceProvider: BTStatisticTraceInnerProvider?) {
        super.init(type: .normal, parentTraceId: parentTraceId, traceProvider: traceProvider)
    }

    func add(point: BTStatisticNormalPoint, retry: Int = 0) {
        BTStatisticManager.serialQueue.async { [weak self] in
            self?.internalAdd(point: point)
        }
    }

    private func internalAdd(point: BTStatisticNormalPoint, retry: Int = 0) {
        if BTStatisticDebug.logTempPoint {
            BTStatisticLog.logInfo(tag: Self.tag, message: "[BTStatisticNormalTrace] addPoint \(point.name) \(point.type) \(point.timestamp) \(point.extra)")
        }
        if retry >= Self.max_retry_count {
            BTStatisticLog.logError(tag: Self.tag, message: "warning: circular call??")
            return
        }
        if point.isUnique {
            let targetPoints = point.isTempPoint ? tempPoints : Array(points)
            let otherPoint = targetPoints.first(where: { $0.name == point.name && $0.type == point.type })
            if otherPoint != nil {
                if BTStatisticDebug.debug {
                    BTStatisticLog.logError(tag: Self.tag, message: "point not unique")
                }
                return
            }
        }

        switch point.type {
        case .temp_point:
            tempPoints.append(point)
        case .temp_point_group:
            tempPoints.append(point)
            var addPoints = [BTStatisticNormalPoint]()
            consumers.forEach { consumer in
                if let consumer = consumer as? BTStatisticNormalConsumer {
                    let points = consumer.consumeTempPoint(trace: self, currentPoint: point, allPoint: tempPoints)
                    addPoints.append(contentsOf: points)
                }
            }
            tempPoints.removeAll()
            addPoints.forEach { point in
                internalAdd(point: point, retry: retry + 1)
            }
        default:
            points.append(point)

            var consumedPoints = [BTStatisticNormalPoint]()
            consumers.forEach { consumer in
                if let consumer = consumer as? BTStatisticNormalConsumer, let provider = traceProvider {
                    let points = consumer.consume(trace: self, logger: provider.getLogger(), currentPoint: point, allPoint: Array(points))
                    consumedPoints.append(contentsOf: points)
                }
            }
            points = points.filter({ item in
                !consumedPoints.contains(item)
            })
            checkClear()
        }
    }
}
