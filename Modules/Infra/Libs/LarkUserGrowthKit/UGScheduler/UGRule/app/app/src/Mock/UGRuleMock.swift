//
//  UGRuleMock.swift
//  UGRule
//
//  Created by zhenning on 2021/1/21.
//

import Foundation
import RxSwift
import UGRule

public class UGRuleMock {

    public static var shared = UGRuleMock()

    let manager = UGRuleManager()
    let disposeBag = DisposeBag()

    /// 测试事件触发
    public func testTriggerSingleExpEvent(actionInfo: RuleActionInfo,
                                          thresholdValue: String,
                                          expOperator: ExpressionOperator) {
        let ruleID: String = "1"
        let ruleExp = LeafRuleExpression(ruleID: ruleID,
                                         actionInfo: actionInfo,
                                         thresholdValue: thresholdValue,
                                         expOperator: expOperator)
        let ruleInfo = LocalRuleInfo(ruleID: ruleID, ruleExp: ruleExp)
        self.manager.handleRuleEvent(ruleInfo: ruleInfo, actionInfo: actionInfo)
            .subscribe(onNext: { (displayInfos) in
                print("[UGRule]: rule mock displayInfos = \(displayInfos)")
            }).disposed(by: disposeBag)
    }

    /// 测试事件触发
    public func testTriggerParentExpEvent(actionInfo: RuleActionInfo) {
        let ruleID: String = "2"
        let leftExp = LeafRuleExpression(ruleID: ruleID,
                                         actionInfo: RuleActionInfo(ruleAction: .clickCount),
                                         thresholdValue: "1",
                                         expOperator: .lessOrEqual)
        let rightExp = LeafRuleExpression(ruleID: ruleID,
                                          actionInfo: RuleActionInfo(ruleAction: .input, actionValue: "he"),
                                          thresholdValue: "hello",
                                          expOperator: .inside)
        guard let conditOperator = ConditionOperator(rawValue: "&&") else { return }
        let ruleExp = ParentRuleExpression(ruleID: ruleID,
                                           leftExp: leftExp,
                                           rightExp: rightExp,
                                           conditOperator: conditOperator)

        let ruleInfo = LocalRuleInfo(ruleID: ruleID, ruleExp: ruleExp)

        self.manager.handleRuleEvent(ruleInfo: ruleInfo, actionInfo: actionInfo)
            .subscribe(onNext: { (displayInfos) in
                print("[UGRule]: rule mock displayInfos = \(displayInfos)")
            }).disposed(by: disposeBag)
    }

// MARK: - Test

    //    testSingleRuleKeepClicking()
    //    testSingleRuleShowTime()
    //    testSingleRuleKeepTyping()
    //
    //    UGRuleMock.shared.testTriggerParentExpEvent(ruleAction: .input("he"))
    //    UGRuleMock.shared.testTriggerParentExpEvent(ruleAction: .clickCount)
    //    UGRuleMock.shared.testTriggerParentExpEvent(ruleAction: .input("ll"))

}
