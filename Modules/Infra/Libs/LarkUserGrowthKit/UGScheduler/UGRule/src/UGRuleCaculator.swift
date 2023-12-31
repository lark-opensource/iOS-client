//
//  UGRuleCaculator.swift
//  UGRule
//
//  Created by zhenning on 2021/1/21.
//

import Foundation
import LKCommonsLogging
import Homeric

// 计算表达式，得到结果
final class UGRuleCalulator {
    private static let log = Logger.log(UGRuleCalulator.self, category: "UGScheduler")
    private let tracer = Tracer()

    private var cache: UGRuleCache {
        return UGRuleCache.shared
    }

    /// 计算表达式树
    func caculateExpressionTree(ruleExp: RuleExpression,
                                actionInfo: RuleActionInfo) -> Bool {
        var result: Bool
        let ruleID = ruleExp.ruleID

        switch ruleExp.nodeType {
        case let .leaf(metaRule):
            guard let actionMetaRule = mapRuleActionIntoActionMetaRule(ruleExp: ruleExp, actionInfo: actionInfo) else {
                Self.log.error("[UGRule]: actionMeta is nil in leaf node!")
                return false
            }
            guard let expOperator = ruleExp.expOperator else {
                trackRuleError(ruleID: ruleID, errorCode: .no_exp_operator_error)
                Self.log.error("[UGRule]: expOperator is nil in leaf node!")
                return false
            }
            guard let nodeValueId = ruleExp.nodeValueId else {
                Self.log.error("[UGRule]: nodeValueId is nil in leaf node!")
                return false
            }
            result = caculateLeafExpressionResult(nodeValueId: nodeValueId,
                                                  expOperator: expOperator,
                                                  actionMetaRule: actionMetaRule,
                                                  leafMetaRule: metaRule)
        case let .parent(parentExp):
            result = caculateParentExpressionResult(parentExp: parentExp, actionInfo: actionInfo)
        case .singleParent:
            result = false
            trackRuleError(ruleID: ruleID, errorCode: .exp_tree_invalid_error)
            Self.log.error("[UGRule]: 规则计算 配置的规则是的单节点, ruleExp = \(ruleExp)")
        case .errorNoConditOperator(nodeValueId: let nodeValueId):
            result = false
            trackRuleError(ruleID: ruleID, errorCode: .no_exp_operator_error)
            Self.log.error("[UGRule]: 规则计算 无法解析，缺少条件操作符号, ruleExp = \(ruleExp)，nodeValueId = \(nodeValueId)")
        case .errorLeafNoRuleAction(nodeValueId: let nodeValueId):
            result = false
            trackRuleError(ruleID: ruleID, errorCode: .leaf_no_rule_action_error)
            Self.log.error("[UGRule]: 规则计算 无法解析，叶子节点缺少规则事件定义, ruleExp = \(ruleExp)，nodeValueId = \(nodeValueId)")
        case .errorLeafNoThresholdValue(nodeValueId: let nodeValueId):
            result = false
            trackRuleError(ruleID: ruleID, errorCode: .invalid_threshold_value_error)
            Self.log.error("[UGRule]: 规则计算 无法解析，叶子节点缺少阈值, ruleExp = \(ruleExp)，nodeValueId = \(nodeValueId)")
        }
        return result
    }

    private func trackRuleError(ruleID: String, errorCode: UGRuleErrorCode) {
        let eventKey = Homeric.UG_REACH_LOCAL_RULE_ERROR
        var msg: String
        switch errorCode {
        case .exp_tree_invalid_error:
            msg = "expression tree is invalid!"
        case .no_meta_rule_error:
            msg = "expression tree no meta rule!"
        case .no_exp_operator_error:
            msg = "expression tree no exp operator!"
        case .invalid_threshold_value_error:
            msg = "expression tree invalid threshold value!"
        case .leaf_no_rule_action_error:
            msg = "expression tree no ruleAction"
        case .rule_current_value_error:
            msg = "current value not exists!"
        }
        self.tracer
            .traceLog(msg: "\(msg), error = \(errorCode)")
            .traceMetric(
                eventKey: eventKey,
                category: ["isSuccess": "false",
                           "errorCode": "\(errorCode)",
                           "ruleId": ruleID],
                extra: ["errMsg": msg]
            )
    }

    /// 计算表达式父节点
    func caculateParentExpressionResult(parentExp: ParentExpression, actionInfo: RuleActionInfo) -> Bool {
        var result: Bool
        // 递归计算
        let leftResult = caculateExpressionTree(ruleExp: parentExp.leftExp,
                                                actionInfo: actionInfo)
        let rightResult = caculateExpressionTree(ruleExp: parentExp.rightExp,
                                                 actionInfo: actionInfo)
        // map operator
        switch parentExp.conditOperator {
        case .and:
            result = leftResult && rightResult
        case .or:
            result = leftResult || rightResult
        }
        Self.log.debug("[UGRule]: 规则计算 parent, leftResult = \(leftResult), rightResult = \(rightResult)")
        return result
    }

    /// 计算表达式叶子节点
    func caculateLeafExpressionResult(nodeValueId: String,
                                      expOperator: ExpressionOperator,
                                      actionMetaRule: MetaRule,
                                      leafMetaRule: MetaRule) -> Bool {
        // 处理条件操作符
        func handleExpOperator<T>(opType: ExpOperatorType, thresholdValue: T, currentValue: T) -> Bool {
            var result: Bool
            switch opType {
            case let .string(expOperator):
                guard let thresholdValue = thresholdValue as? String,
                      let currentValue = currentValue as? String else { return false }
                switch expOperator {
                case .equal:
                    result = currentValue == currentValue
                case .inside:
                    result = thresholdValue.contains(currentValue)
                default:
                    result = false
                    Self.log.error("[UGRule]: handleExpOperator [string] expOperator \(expOperator) is not valid in leaf node!")
                }
                Self.log.debug("[UGRule]: thresholdContent = \(thresholdValue), currentValue = \(currentValue)")
                return result
            case let .int(expOperator):
                guard let thresholdValue = thresholdValue as? Int,
                      let currentValue = currentValue as? Int else { return false }
                var result: Bool
                switch expOperator {
                case .equal:
                    result = currentValue == thresholdValue
                case .notEqual:
                    result = currentValue != thresholdValue
                case .greater:
                    result = currentValue > thresholdValue
                case .greaterOrEqual:
                    result = currentValue >= thresholdValue
                case .lessOrEqual:
                    result = currentValue <= thresholdValue
                case .lessThan:
                    result = currentValue < thresholdValue
                default:
                    Self.log.error("[UGRule]: handleExpOperator [int] expOperator \(expOperator) is not valid in leaf node!")
                    result = false
                }
                Self.log.debug("[UGRule]: thresholdCount = \(thresholdValue), currentValue = \(currentValue)")
                return result
            }
        }

        var result: Bool
        // 处理叶子表达式的规则类型
        switch leafMetaRule {
        case let .content(thresholdContent):
            if case let .content(currentValue) = actionMetaRule {
                result = handleExpOperator(opType: .string(expOperator),
                                           thresholdValue: thresholdContent,
                                           currentValue: currentValue)
                // update cache
                self.storeValueInCache(key: nodeValueId, value: currentValue)
            } else if let currentValue = getLocalValueOfMetaRule(key: nodeValueId) as? String {
                // 如果事件未触达该节点，则读取上次的值计算
                result = handleExpOperator(opType: .string(expOperator),
                                           thresholdValue: thresholdContent,
                                           currentValue: currentValue)
            } else {
                if actionMetaRule.type == leafMetaRule.type {
                    Self.log.error("[UGRule]: metaRule [content] type is not valid!",
                                   additionalData: [
                                    "actionMetaRule": "\(actionMetaRule)",
                                    "leafMetaRule": "\(leafMetaRule)"
                                   ])
                }
                result = false
            }
        case let .count(thresholdCount):
            if case let .count(currentValue) = actionMetaRule {
                result = handleExpOperator(opType: .int(expOperator),
                                           thresholdValue: thresholdCount,
                                           currentValue: currentValue)
                // update cache
                self.storeValueInCache(key: nodeValueId, value: currentValue)
            } else if let currentValue = getLocalValueOfMetaRule(key: nodeValueId) as? Int {
                // 如果事件未触达该节点，则读取上次的值计算
                result = handleExpOperator(opType: .int(expOperator),
                                           thresholdValue: thresholdCount,
                                           currentValue: currentValue)
            } else {
                if actionMetaRule.type == leafMetaRule.type {
                    Self.log.error("[UGRule]: metaRule [count] type is not valid!",
                                   additionalData: [
                                    "actionMetaRule": "\(actionMetaRule)",
                                    "leafMetaRule": "\(leafMetaRule)"
                                   ])
                }
                result = false
            }
        case let .duration(thresholdDuration):
            // 时间需要取出上次的时间戳计算得到耗时
            if case let .duration(currentTimeStamp) = actionMetaRule {
                if let storedValue = getLocalValueOfMetaRule(key: nodeValueId) as? Int,
                   currentTimeStamp >= storedValue {
                    let currentValue = currentTimeStamp - storedValue
                    result = handleExpOperator(opType: .int(expOperator),
                                               thresholdValue: thresholdDuration,
                                               currentValue: currentValue)
                } else {
                    result = false
                    Self.log.debug("[UGRule]: metaRule [duration] has not storedValue actionInfo = \(actionMetaRule)")
                }
                // update cache
                self.storeValueInCache(key: nodeValueId, value: currentTimeStamp)
            } else {
                Self.log.error("[UGRule]: metaRule is not valid in leaf [duration]! actionInfo = \(actionMetaRule)")
                result = false
            }
        }

        Self.log.debug("[UGRule]: caculate Leaf Node Result",
                       additionalData: [
                        "nodeValueId": "\(nodeValueId)",
                        "expOperator": "\(expOperator)",
                        "leafMetaRule": "\(leafMetaRule)",
                        "result": "\(result)"
                       ])
        return result
    }
    // swiftlint:enable function_body_length
}

// MARK: - Util

extension UGRuleCalulator {
    /// 转换RuleAction为元规则, 记录当前的值
    private func mapRuleActionIntoActionMetaRule(ruleExp: RuleExpression, actionInfo: RuleActionInfo) -> MetaRule? {
        guard let nodeValueId = ruleExp.nodeValueId else { return nil }

        var metaRule: MetaRule
        switch actionInfo.ruleAction {
        case .clickCount:
            var count: Int = 1
            if let previousValue = self.getLocalValueOfMetaRule(key: nodeValueId) as? Int {
                count = previousValue + 1
            }
            metaRule = .count(count)
        case .input:
            var result: String = ""
            if let actionValue = actionInfo.actionValue {
                result = actionValue
                if let previousValue = self.getLocalValueOfMetaRule(key: nodeValueId) as? String {
                    result = previousValue + actionValue
                }
            }
            metaRule = .content(result)
        case .showCount:
            var count: Int = 1
            if let previousValue = self.getLocalValueOfMetaRule(key: nodeValueId) as? Int {
                count = previousValue + 1
            }
            metaRule = .count(count)
        case .showTime:
            let currentTimeStamp = Date().timeIntervalSince1970 * 1_000
            let currentValue = Int(currentTimeStamp)
            metaRule = .duration(currentValue)
        }
        return metaRule
    }
}

// MARK: - Cache

extension UGRuleCalulator {

    // 从缓存中获取上次存储的值
    func getLocalValueOfMetaRule(key: String) -> Any? {
        guard !key.isEmpty else { return nil }
        let storedValue = cache.getValueForKey(key: key)
        return storedValue
    }

    // 设置值到存储
    func storeValueInCache(key: String, value: Any) {
        guard !key.isEmpty else { return }
        cache.setValueForKey(key: key, value: value)
    }
}
