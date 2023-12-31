//
//  UGRule.swift
//  UGRuleManager
//
//  Created by zhenning on 2021/1/21.
//

import Foundation
import RxSwift
import RustPB

public final class UGRuleManager {

    private lazy var dataManager: UGRuleDataManager = {
        let dataManager = UGRuleDataManager()
        return dataManager
    }()

    public init() { }
}

// MARK: - Service
extension UGRuleManager: UGRuleService {
    /// 处理事件消息
    /// 返回本地规则处理结果信号
    public func handleRuleEvent(ruleInfoPB: LocalRulePB, actionInfo: RuleActionInfo) -> Observable<Bool> {
        let ruleInfo = praserRuleInfoPBToRuleInfo(ruleInfoPB: ruleInfoPB, actionInfo: actionInfo)

        guard let displayInfo = self.dataManager
                .getDisplayResultOfEvent(ruleInfo: ruleInfo, actionInfo: actionInfo) else {
            return Observable.empty()
        }
        return Observable.of(displayInfo)
    }

    public func registerCustomRule(ruleID: String, customRule: @escaping CustomRuleBlock) {
        self.dataManager.registerCustomRule(ruleID: ruleID, customRule: customRule)
    }

    /// 处理事件消息自定义规则事件
    public func handleCustomRuleEvent(ruleID: String, actionInfo: RuleActionInfo) -> Observable<Bool> {
        guard let displayInfo = self.dataManager
                .handleCustomRuleEvent(ruleID: ruleID, actionInfo: actionInfo) else {
            return Observable.empty()
        }
        return Observable.of(displayInfo)
    }
}

// MARK: - Util
extension UGRuleManager {
    private func praserRuleInfoPBToRuleInfo(ruleInfoPB: LocalRulePB,
                                            actionInfo: RuleActionInfo) -> LocalRuleInfo {
        let ruleID = "\(ruleInfoPB.ruleID)"
        let ruleExp = praserRuleExpToExpression(ruleID: ruleID,
                                                ruleExpPB: ruleInfoPB.rootExpNode,
                                                actionInfo: actionInfo)
        let ruleInfo = LocalRuleInfo(ruleID: "\(ruleInfoPB.ruleID)", ruleExp: ruleExp)
        return ruleInfo
    }

    private func praserRuleExpToExpression(ruleID: String,
                                           ruleExpPB: RuleExpPB,
                                           actionInfo: RuleActionInfo) -> RuleExpression {

        let ruleExp = RuleExpression(ruleID: ruleID)
        // 无左右子节点，为叶子节点
        if !ruleExpPB.hasLeft && !ruleExpPB.hasRight {
            let LeafExp = LeafRuleExpression(ruleID: ruleID,
                                             actionInfo: actionInfo,
                                             thresholdValue: ruleExpPB.value,
                                             expOperator: ExpressionOperator(rawValue: ruleExpPB.expOperator.rawValue))
            return LeafExp
        }
        // 遍历左子节点
        if ruleExpPB.hasLeft {
            let leftExp = praserRuleExpToExpression(ruleID: ruleID, ruleExpPB: ruleExpPB.left, actionInfo: actionInfo)
            ruleExp.leftExp = leftExp
            if let conditOperator = ruleExp.conditOperator {
                ruleExp.conditOperator = conditOperator
            }
        }
        // 遍历右子节点
        if ruleExpPB.hasRight {
            let rightExp = praserRuleExpToExpression(ruleID: ruleID, ruleExpPB: ruleExpPB.right, actionInfo: actionInfo)
            ruleExp.rightExp = rightExp
            if let conditOperator = ruleExp.conditOperator {
                ruleExp.conditOperator = conditOperator
            }
        }
        return ruleExp
    }
}

// MARK: - Mock
extension UGRuleManager {
    /// 处理事件消息
    /// 返回本地规则处理结果信号
    public func handleRuleEvent(ruleInfo: LocalRuleInfo, actionInfo: RuleActionInfo) -> Observable<Bool> {
        guard let displayInfo = self.dataManager
                .getDisplayResultOfEvent(ruleInfo: ruleInfo, actionInfo: actionInfo) else {
            return Observable.empty()
        }
        return Observable.of(displayInfo)
    }
}
