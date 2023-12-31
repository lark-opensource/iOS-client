//
//  Tracer.swift
//  UGRCoreIntegration
//
//  Created by shizhengyu on 2021/3/8.
//

import UIKit
import Foundation
import LKCommonsLogging
import LKCommonsTracker
import ThreadSafeDataStructure

final class Tracer {
    private let prefix = "[UGCoordinator]"
    private let logger = Logger.log(Tracer.self, category: "ug.reach.coordinator")

       var timeDic: SafeDictionary<String, TimeInterval> = [:] + .readWriteLock

    @discardableResult
    func traceLog(msg: String) -> Tracer {
        logger.info(prefix + msg)
        return self
    }

    @discardableResult
    func traceMetric(
        eventKey: String,
        identifier: String,
        metric: [AnyHashable: Any] = [:],
        category: [AnyHashable: Any] = [:],
        extra: [AnyHashable: Any] = [:],
        isEndPoint: Bool
    ) -> Tracer {
        let key = eventKey + identifier
        if isEndPoint {
            guard let startTime = timeDic[key] else { return self }
            timeDic[key] = nil
            let cost = CACurrentMediaTime() - startTime
            var metric = metric
            metric["latency"] = cost
        } else {
            timeDic[key] = CACurrentMediaTime()
        }
        Tracker.post(
            SlardarEvent(
                name: eventKey,
                metric: metric,
                category: category,
                extra: extra
            )
        )
        return self
    }
}

enum UGCoordinatorErrorCode: Int64 {
    // 信息缺失：触达点位必要属性缺失，数据解析错误
    case entity_data_error = 101
    // 信息缺失：触达点位缺失，节点关系计算出错
    case node_missed_error = 102
    // 信息缺失：场景信息缺失，onScenarioExit时发现之前没有enter过
    case scenario_missed_error = 103
    // 信息缺失：消费一个非root节点（只有root节点才能被消费）
    case consume_not_root_node_error = 104
    // 配置错误：触达点位关系配置错误，存在回路循环依赖
    case relation_circle_error = 201
    // 未知错误：其他报错捕获
    case other_unknown_error = 500
}
