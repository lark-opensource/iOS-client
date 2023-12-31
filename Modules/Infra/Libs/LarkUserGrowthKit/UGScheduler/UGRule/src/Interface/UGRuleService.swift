//
//  UGRuleService.swift
//  UGCoordinator
//
//  Created by zhenning on 2021/3/13.
//

import Foundation
import RxSwift

public protocol UGRuleService {
    /// 处理事件消息, rules: 外部注入规则，actionInfo: 规则触发事件
    /// 返回本地规则处理结果信号
    func handleRuleEvent(ruleInfoPB: LocalRulePB, actionInfo: RuleActionInfo) -> Observable<Bool>

    // 注册自定义规则
    func registerCustomRule(ruleID: String, customRule: @escaping CustomRuleBlock)

    /// 处理事件消息自定义规则事件
    func handleCustomRuleEvent(ruleID: String, actionInfo: RuleActionInfo) -> Observable<Bool>
}
