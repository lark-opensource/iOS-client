//
//  LarkDowngradeRule.swift
//  LarkDowngrade
//
//  Created by sniperYJ on 2023/9/1.
//

import Foundation
import ThreadSafeDataStructure

//具体规则
public class LarkDowngradeRuleInfo {
    var time: Double = 10
    var ruleList: SafeDictionary<LarkDowngradeIndex, Double> = SafeDictionary()
    
    public init() {}

    public init(ruleList:Dictionary<LarkDowngradeIndex, Double>,time:Double) {
        self.time = time
        self.ruleList =  SafeDictionary(ruleList)
    }

    func updateWithDic(dictionary: [String: Any]) {
        self.time = Double(dictionary["time"] as? Double ?? 10)
        for rule in dictionary {
            if let ruleKey = LarkDowngradeIndex(rawValue: rule.key){
                self.ruleList[ruleKey] =  Double(rule.value as? Double ?? 0)
            }
        }
    }
}

/// 整体规则
public class LarkDowngradeRule {
    //降级规则
    var rules: SafeDictionary<LarkDowngradeRuleType, [LarkDowngradeRuleInfo]> = SafeDictionary()

    public init() {
    }

    public init(rules: Dictionary<LarkDowngradeRuleType, [LarkDowngradeRuleInfo]>){
        self.rules = SafeDictionary(rules)
    }

    func updateWithDic(dictionary: [String: Any]) {
        for typeInfo in dictionary {
            if let typeKey = LarkDowngradeRuleType(rawValue: typeInfo.key) {
                var typeRules: [LarkDowngradeRuleInfo] = []
                if let overloadArr = dictionary[typeInfo.key] as? Array<Any> {
                    for ruleList in overloadArr {
                        if let ruleInfoDic = ruleList as? Dictionary<String,Any> {
                            let ruleInfo = LarkDowngradeRuleInfo()
                            ruleInfo.updateWithDic(dictionary: ruleInfoDic)
                            typeRules.append(ruleInfo)
                        }
                    }
                }
                self.rules[typeKey] = typeRules
            }
        }
    }
}
