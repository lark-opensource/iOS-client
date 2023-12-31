//
//  LarkDowngradeStrategy.swift
//  DowngradeTest
//
//  Created by ByteDance on 2023/9/11.
//

import Foundation
import LKCommonsLogging

public protocol LarkUniversalDowngradeRule {
    var ruleKey: String { get set }
    func shouldDowngrade(context: Any?) -> Bool
    func shouldUpgrade(context: Any?) -> Bool
}

/// strategy status
public enum LarkUniversalDowngradeStrategyStatus {
    case normal((Bool, Any?)) ///bool is true means isDowngrade or isUpgrade, Any is strategy data
    case ignore
    case error(String)
}


/// strategy key is only
public protocol LarkUniversalDowngradeStrategy {
    var strategyKey: String { get set }
    /// rules all meet
    var allMeetStrategys: [LarkUniversalDowngradeRule]? { get set }
    /// Just satisfy one rule
    var oneOfMeetStrategys: [LarkUniversalDowngradeRule]? { get set }
    /// should downgrade
    /// - Parameter effectRules: Rules that have taken effect in this poll
    /// - Returns: Rules that have taken effect in this strategy
    func shouldDowngrade(effectRules: Set<String>?) -> (LarkUniversalDowngradeStrategyStatus, Set<String>?)
    /// should upgrade
    /// - Parameter effectRules: Rules that have taken effect in this poll
    /// - Returns: Rules that have taken effect in this strategy
    func shouldUpgrade(effectRules: Set<String>?) -> (LarkUniversalDowngradeStrategyStatus, Set<String>?)
    /// get this strategy's data
    /// - Returns: strategy data
    func getData() -> Any?
}

extension LarkUniversalDowngradeStrategy {
    private func judgeRuleAvailable() -> Bool {
        if allMeetStrategys == nil,
           oneOfMeetStrategys == nil {
            assertionFailure("allMeetStrategyList and OneOfStrategyList all nil")
            return false
        }
        if let _ = allMeetStrategys,
           let _ = oneOfMeetStrategys {
            assertionFailure("allMeetStrategyList or OneOfStrategyList just have one")
            return false
        }
        return true
    }
    
    public func shouldUpgrade(effectRules: Set<String>?) -> (LarkUniversalDowngradeStrategyStatus, Set<String>?) {
        if !judgeRuleAvailable() {
            return (.error("\(self) allMeetList && one of MeetList conflict"), nil)
        }
        var currentEffectRules: Set<String> = []
        let tempEffectRules: Set<String> = effectRules ?? []
        if let oneOfMeetStrategys = oneOfMeetStrategys {
            for rule in oneOfMeetStrategys {
                if tempEffectRules.contains(rule.ruleKey) {
                    return (.ignore, nil)
                }
                if rule.shouldUpgrade(context: getData()) {
                    currentEffectRules.insert(rule.ruleKey)
                } else {
                    return (.normal((false, getData())), nil)
                }
            }
            return (.normal((true, getData())), currentEffectRules)
        }
        if let allMeetStrategys = allMeetStrategys {
            var isNormal = true
            for rule in allMeetStrategys {
                if rule.shouldUpgrade(context: getData()) {
                    if !tempEffectRules.contains(rule.ruleKey) {
                        currentEffectRules.insert(rule.ruleKey)
                        return (.normal((true, getData())), currentEffectRules)
                    } else {
                        isNormal = false
                    }
                }
            }
            if isNormal {
                return (.normal((false, getData())), nil)
            } else {
                return (.ignore, nil)
            }
        }
        return (.error("\(self) allMeetList && one of MeetList is null"), nil)
    }

    
    public func shouldDowngrade(effectRules: Set<String>?) -> (LarkUniversalDowngradeStrategyStatus, Set<String>?) {
        if !judgeRuleAvailable() {
            return (.error("\(self) allMeetList && one of MeetList conflict"), nil)
        }
        var currentEffectRules: Set<String> = []
        let tempEffectRules: Set<String> = effectRules ?? []
        if let allMeetStrategys = allMeetStrategys {
            for rule in allMeetStrategys {
                if tempEffectRules.contains(rule.ruleKey) {
                    return (.ignore, nil)
                }
                if rule.shouldDowngrade(context: getData()) {
                    currentEffectRules.insert(rule.ruleKey)
                } else {
                    return (.normal((false, getData())), nil)
                }
            }
            return (.normal((true, getData())), currentEffectRules)
        }
        if let oneOfMeetStrategys = oneOfMeetStrategys {
            var isNormal = true
            for rule in oneOfMeetStrategys {
                if rule.shouldDowngrade(context: getData()) {
                    if !tempEffectRules.contains(rule.ruleKey) {
                        currentEffectRules.insert(rule.ruleKey)
                        return (.normal((true, getData())), currentEffectRules)
                    } else {
                        isNormal = false
                    }
                }
            }
            if isNormal {
                return (.normal((false, getData())), nil)
            } else {
                return (.ignore, nil)
            }
        }
        return (.error("\(self) allMeetList && one of MeetList is null"), nil)
    }
}

//postfix operator |
infix operator |||: AdditionPrecedence
public func ||| (operand1: LarkUniversalDowngradeRule, operand2: LarkUniversalDowngradeRule) -> [LarkUniversalDowngradeRule] {
    return [operand1, operand2]
}

public func ||| (operand1: [LarkUniversalDowngradeRule], operand2: LarkUniversalDowngradeRule) -> [LarkUniversalDowngradeRule] {
    var result = operand1
    result.append(operand2)
    return result
}

public func ||| (operand1: LarkUniversalDowngradeStrategy, operand2: LarkUniversalDowngradeStrategy) -> [LarkUniversalDowngradeStrategy] {
    return [operand1, operand2]
}

public func ||| (operand1: [LarkUniversalDowngradeStrategy], operand2: LarkUniversalDowngradeStrategy) -> [LarkUniversalDowngradeStrategy] {
    var result = operand1
    result.append(operand2)
    return result
}

infix operator |&|: AdditionPrecedence
public func |&| (operand1: LarkUniversalDowngradeRule, operand2: LarkUniversalDowngradeRule) -> [String: LarkUniversalDowngradeRule] {
    if operand1.ruleKey == operand2.ruleKey {
        assertionFailure("LarkUniversalDowngradeRule add same rules \(operand1.ruleKey)")
    }
    var result = [operand1.ruleKey: operand1]
    result[operand2.ruleKey] = operand2
    return result
}

public func |&| (operand1: [String: LarkUniversalDowngradeRule], operand2: LarkUniversalDowngradeRule) -> [String: LarkUniversalDowngradeRule] {
    if let v = operand1[operand2.ruleKey] {
        assertionFailure("LarkUniversalDowngradeRule add same rules \(v.ruleKey)")
    }
    var result = operand1
    result[operand2.ruleKey] = operand2
    return result
}

public func |&| (operand1: LarkUniversalDowngradeStrategy, operand2: LarkUniversalDowngradeStrategy) -> [String: LarkUniversalDowngradeStrategy] {
    if operand1.strategyKey == operand2.strategyKey {
        assertionFailure("LarkUniversalDowngradeStrategy add same strategy \(operand1.strategyKey)")
    }
    var result = [operand1.strategyKey: operand1]
    result[operand2.strategyKey] = operand2
    return result
}

public func |&| (operand1: [String: LarkUniversalDowngradeStrategy], operand2: LarkUniversalDowngradeStrategy) -> [String: LarkUniversalDowngradeStrategy] {
    if let v = operand1[operand2.strategyKey] {
        assertionFailure("LarkUniversalDowngradeStrategy add same strategy \(v.strategyKey)")
    }
    var result = operand1
    result[operand2.strategyKey] = operand2
    return result
}
