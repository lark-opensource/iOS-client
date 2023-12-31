//
//  UGRuleDataManager.swift
//  UGRule
//
//  Created by zhenning on 2021/1/21.
//

import Foundation
import RxSwift
import RxRelay
import LKCommonsLogging
import Swinject

/// 本地规则数据中心
final class UGRuleDataManager {

    private let disposeBag = DisposeBag()

    private static let log = Logger.log(UGRuleDataManager.self, category: "UGScheduler")
    private lazy var ruleCaculator: UGRuleCalulator = {
        let ruleCaculator = UGRuleCalulator()
        return ruleCaculator
    }()

    private var customRules: [String: CustomRuleBlock] = [:]

    func registerCustomRule(ruleID: String, customRule: @escaping CustomRuleBlock) {
        customRules[ruleID] = customRule
    }

    /// 外部接口，获取规则展示结果
    func getDisplayResultOfEvent(ruleInfo: LocalRuleInfo, actionInfo: RuleActionInfo) -> Bool? {
        // 调用RuleCaculator计算，组装ScenarioDisplayInfo
        let displayResult = self.getRuleResultOnAction(ruleInfo: ruleInfo, actionInfo: actionInfo)
        Self.log.debug("[UGRule]: displayResult = \(displayResult)")
        return displayResult
    }

    func handleCustomRuleEvent(ruleID: String, actionInfo: RuleActionInfo) -> Bool? {
        guard customRules.keys.contains(ruleID) else { return nil }
        if let customRule = customRules[ruleID] {
            return customRule()
        } else {
            return false
        }
    }
}

// MARK: - Util

extension UGRuleDataManager {

    /// 通过rule和action获取计算结果
    private func getRuleResultOnAction(ruleInfo: LocalRuleInfo, actionInfo: RuleActionInfo) -> Bool {
        // caculate result of expression tree
        let display = self.ruleCaculator.caculateExpressionTree(ruleExp: ruleInfo.ruleExp,
                                                                actionInfo: actionInfo)
        Self.log.debug("[UGRule]: getRuleResultOnAction, LocalRuleInfo = \(ruleInfo), display = \(display)")
        return display
    }
}
