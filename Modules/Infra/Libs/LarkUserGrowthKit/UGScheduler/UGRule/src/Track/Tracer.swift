//
//  Tracer.swift
//  UGRCoreIntegration
//
//  Created by shizhengyu on 2021/3/8.
//

import Foundation
import LKCommonsLogging
import LKCommonsTracker

final class Tracer {
    private let prefix = "[UGRule]"
    private let logger = Logger.log(Tracer.self, category: "ug.reach.rule")

    @discardableResult
    func traceLog(msg: String) -> Tracer {
        logger.info(prefix + msg)
        return self
    }

    @discardableResult
    func traceMetric(
        eventKey: String,
        metric: [AnyHashable: Any] = [:],
        category: [AnyHashable: Any] = [:],
        extra: [AnyHashable: Any] = [:]
    ) -> Tracer {
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

enum UGRuleErrorCode: Int64 {
    // 本地规则控制异常
    case exp_tree_invalid_error = 101
    // 信息缺失：下发的规则无法解析，缺少metaRule
    case no_meta_rule_error = 102
    // 信息缺失：下发的规则无法解析，缺少表达式操作符
    case no_exp_operator_error = 103
    // 信息缺失：下发的规则无法解析，阈值不合法（缺少或格式错误）
    case invalid_threshold_value_error = 104
    // 信息缺失：下发的规则无法解析，叶子节点缺少ruleAction
    case leaf_no_rule_action_error = 105
    // 信息缺失：本地规则currentValue获取异常
    case rule_current_value_error = 106
}
