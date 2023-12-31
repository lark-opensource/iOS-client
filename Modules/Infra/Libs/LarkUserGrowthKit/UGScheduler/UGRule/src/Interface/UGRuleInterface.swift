//
//  UGRuleInterface.swift
//  UGRule
//
//  Created by zhenning on 2021/1/21.
//

import Foundation
import RustPB

public typealias LocalRulePB = RustPB.Ugreach_V1_LocalRule
public typealias RuleExpPB = RustPB.Ugreach_V1_RuleExpression
public typealias CustomRuleBlock = () -> Bool

// 元规则
public enum MetaRule {
    // 次数规则
    case count(Int)
    // 计时规则-毫秒ms
    case duration(Int)
    // 内容规则
    case content(String)

    var type: String {
        switch self {
        case .count, .duration: return "Int"
        case .content: return "String"
        }
    }
}

// 规则触发事件
public struct RuleActionInfo {
    let ruleAction: RuleAction
    let actionValue: String?
    public init(ruleAction: RuleAction,
         actionValue: String? = nil) {
        self.ruleAction = ruleAction
        self.actionValue = actionValue
    }
}

// 规则触发事件
public enum RuleAction {
    // 点击次数
    case clickCount
    // 展示次数
    case showCount
    // 展示时间-ms
    case showTime
    // input
    case input

    public var description: String {
        switch self {
        case .clickCount: return "click_count"
        case .showCount: return "show_count"
        case .showTime: return "show_time"
        case .input: return "input"
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "click_count":
            self = .clickCount
        case "show_count":
            self = .showCount
        case "show_time":
            self = .showTime
        case "input":
            self = .input
        default:
            return nil
        }
    }
}

enum ExpressionNodeType {
    // 叶子节点
    case leaf(metaRule: MetaRule)
    // 分支节点-左右都有子节点
    case parent(parentExp: ParentExpression)
    // 分支节点-只有一个子节点，不符合预期,
    case singleParent
    // 无法解析，缺少条件操作符
    case errorNoConditOperator(nodeValueId: String)
    // 无法解析，叶子节点缺少规则事件定义
    case errorLeafNoRuleAction(nodeValueId: String)
    // 无法解析，叶子节点缺少规则阈值
    case errorLeafNoThresholdValue(nodeValueId: String)
}

// 表达式操作符类型
enum ExpOperatorType {
    // count / time ..
    case int(ExpressionOperator)
    // content
    case string(ExpressionOperator)
}

// 表达式操作符
public enum ExpressionOperator: Int {
    // for string
    case inside = 1
    // for string & Int
    case equal = 2
    // for Int
    case lessThan = 3
    // for Int
    case lessOrEqual = 4
    // for Int
    case notEqual = 5
    // for Int
    case greaterOrEqual = 6
    // for Int
    case greater = 7
    // unknown
    case unknown = 0

    public init(rawValue: Int) {
        switch rawValue {
        case 1:
            self = .inside
        case 2:
            self = .equal
        case 3:
            self = .lessThan
        case 4:
            self = .lessOrEqual
        case 5:
            self = .notEqual
        case 6:
            self = .greaterOrEqual
        case 7:
            self = .greater
        default:
            self = .unknown
        }
    }
}

// 条件操作符
public enum ConditionOperator: String {
    case and = "&&"
    case or = "||"

    public init?(rawValue: String) {
        switch rawValue {
        case "&&":
            self = .and
        case "||":
            self = .or
        default:
            return nil
        }
    }
}

// 父节点
struct ParentExpression {
    let ruleID: String
    let conditOperator: ConditionOperator
    let leftExp: RuleExpression
    let rightExp: RuleExpression
}

// leaf node
public final class LeafRuleExpression: RuleExpression {
    public init(ruleID: String,
         actionInfo: RuleActionInfo,
         thresholdValue: String,
         expOperator: ExpressionOperator) {
        let nodeValueId = RuleExpression.getExpValueUpdateID(ruleID: ruleID, ruleAction: actionInfo.ruleAction)
        super.init(ruleID: ruleID,
                   nodeValueId: nodeValueId,
                   leftExp: nil,
                   rightExp: nil,
                   actionInfo: actionInfo,
                   thresholdValue: thresholdValue,
                   expOperator: expOperator,
                   conditOperator: nil)
    }
}

// parent node
public final class ParentRuleExpression: RuleExpression {
    public init(ruleID: String,
                leftExp: RuleExpression,
                rightExp: RuleExpression,
                conditOperator: ConditionOperator) {
        super.init(ruleID: ruleID,
                   leftExp: leftExp,
                   rightExp: rightExp,
                   actionInfo: nil,
                   thresholdValue: nil,
                   expOperator: nil,
                   conditOperator: conditOperator)
    }
}

// 表达式定义
public class RuleExpression {

    let ruleID: String
    // 存储值，ruleID + action
    let nodeValueId: String?
    var leftExp: RuleExpression?
    var rightExp: RuleExpression?
    let actionInfo: RuleActionInfo?
    let thresholdValue: String?
    let expOperator: ExpressionOperator?
    var conditOperator: ConditionOperator?
    // 节点类型
    let nodeType: ExpressionNodeType

    // leaf node
    convenience init(ruleID: String,
                     actionInfo: RuleActionInfo,
                     thresholdValue: String,
                     expOperator: ExpressionOperator) {
        let nodeValueId = RuleExpression.getExpValueUpdateID(ruleID: ruleID, ruleAction: actionInfo.ruleAction)
        self.init(ruleID: ruleID,
                  nodeValueId: nodeValueId,
                  leftExp: nil,
                  rightExp: nil,
                  actionInfo: actionInfo,
                  thresholdValue: thresholdValue,
                  expOperator: expOperator,
                  conditOperator: nil)
    }

    // parent node
    convenience init(ruleID: String,
                     leftExp: RuleExpression,
                     rightExp: RuleExpression,
                     conditOperator: ConditionOperator) {
        self.init(ruleID: ruleID,
                  leftExp: leftExp,
                  rightExp: rightExp,
                  actionInfo: nil,
                  thresholdValue: nil,
                  expOperator: nil,
                  conditOperator: conditOperator)
    }

    public init(ruleID: String,
                nodeValueId: String? = nil,
                leftExp: RuleExpression? = nil,
                rightExp: RuleExpression? = nil,
                actionInfo: RuleActionInfo? = nil,
                thresholdValue: String? = nil,
                expOperator: ExpressionOperator? = nil,
                conditOperator: ConditionOperator? = nil) {
        self.ruleID = ruleID
        self.nodeValueId = nodeValueId
        self.leftExp = leftExp
        self.rightExp = rightExp
        self.actionInfo = actionInfo
        self.thresholdValue = thresholdValue
        self.expOperator = expOperator
        self.conditOperator = conditOperator

        let nodeValueIdValue = nodeValueId ?? ""
        // 定义节点类型
        if let leftExp = leftExp,
           let rightExp = rightExp {
            // 双子节点
            guard let conditOperator = conditOperator else {
                self.nodeType = .errorNoConditOperator(nodeValueId: nodeValueIdValue)
                return
            }
            let parentExp = ParentExpression(ruleID: ruleID,
                                             conditOperator: conditOperator,
                                             leftExp: leftExp,
                                             rightExp: rightExp)
            self.nodeType = .parent(parentExp: parentExp)
        } else if (leftExp == nil) && (rightExp == nil) {
            // 叶子节点
            guard let ruleAction = actionInfo?.ruleAction else {
                self.nodeType = .errorLeafNoRuleAction(nodeValueId: nodeValueIdValue)
                return
            }
            var metaRule: MetaRule
            switch ruleAction {
            case .clickCount, .showCount:
                guard let thresholdValue = self.thresholdValue,
                      let thresholdIntValue = Int(thresholdValue) as Int? else {
                    self.nodeType = .errorLeafNoThresholdValue(nodeValueId: nodeValueIdValue)
                    return
                }
                metaRule = .count(thresholdIntValue)
            case .showTime:
                guard let thresholdValue = self.thresholdValue,
                      let thresholdIntValue = Int(thresholdValue) as Int? else {
                    self.nodeType = .errorLeafNoThresholdValue(nodeValueId: nodeValueIdValue)
                    return
                }
                metaRule = .duration(thresholdIntValue)
            case .input:
                guard let thresholdValue = self.thresholdValue else {
                    self.nodeType = .errorLeafNoThresholdValue(nodeValueId: nodeValueIdValue)
                    return
                }
                metaRule = .content(thresholdValue)
            }
            self.nodeType = .leaf(metaRule: metaRule)
        } else {
            // 单子节点
            self.nodeType = .singleParent
        }
    }

    // 获取表达式值更新的id
    static func getExpValueUpdateID(ruleID: String, ruleAction: RuleAction) -> String {
        return ruleID + "_" + ruleAction.description
    }
}

// 本地规则结构
public struct LocalRuleInfo {
    // 规则ID
    let ruleID: String
    // 表达式
    let ruleExp: RuleExpression

    public init(ruleID: String,
         ruleExp: RuleExpression) {
        self.ruleID = ruleID
        self.ruleExp = ruleExp
    }
}
