//
//  LarkDowngradeConfig.swift
//  LarkDowngrade
//
//  Created by SniperYJ on 2023/9/1.
//

import Foundation
import ThreadSafeDataStructure

/// downgradeConfig
public class LarkDowngradeConfig {
    private var rwlock = pthread_rwlock_t()
    //降级参数配置
    var enableDowngrade: Bool = false
    //间隔配置
    var downgradeIntervalTime: Double = 10 /// 降级间隔
    var normalInervalTime: Double = 20///升级间隔
    var isNormal: Bool = false
    //降级项配置 setting使用
    //TODO:修改名字 禁止使用的rule
    var normalLevel: [String] = []
    //通用规则
    var normalRules: SafeDictionary<LarkDowngradeLevel, Dictionary<LarkDowngradeIndex, LarkDowngradeRule>> = SafeDictionary()
    //自定义相关规则
    var rules: [LarkDowngradeRule] = []
    public init() {
        pthread_rwlock_init(&self.rwlock, nil)
    }

    public init(isNormal: Bool) {
        self.isNormal = isNormal
        pthread_rwlock_init(&self.rwlock, nil)
    }

    public init(rules: [LarkDowngradeRule]) {
        self.rules = rules
        pthread_rwlock_init(&self.rwlock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&self.rwlock)
    }

    func getNormalLevel() -> [String] {
        pthread_rwlock_wrlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        return self.normalLevel
    }

    public func getRules(indexes: [LarkDowngradeIndex] = [],//关注指标，默认不用填
                         level: LarkDowngradeLevel = .high)//降级级别,扩展用,默认不用填写
    -> [LarkDowngradeRule] {
        pthread_rwlock_wrlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        var rules: [LarkDowngradeRule] = []
        if self.isNormal {
            if let type_rule = self.normalRules[level] {
                if indexes.isEmpty {
                    rules = Array(type_rule.values)
                } else {
                    for index in indexes {
                        if let rule = type_rule[index] {
                            rules.append(rule)
                        }
                    }
                }
            }
            
        } else {
            rules = self.rules
        }
        return rules
    }
    
    /**
     defultconfig =  {
         "enable_downgrade": False,
         "rules": {
             "high": {
                 "lowDevice": {
                     "overload": [
                         {
                             "lowDevice": 7.8
                         }
                     ],
                     "normal": [
                         {
                             "lowDevice": 10.0
                         }
                     ]
                 },
                 "overCPU": {
                     "overload": [
                         {
                             "overCPU": 0.8,
                             "overDeviceCPU": 0.9,
                             "time": 30.0
                         }
                     ],
                     "normal": [
                         {
                             "overCPU": 0.3,
                             "overDeviceCPU": 0.5,
                             "time": 30.0
                         }
                     ]
                 },
                 "overMemory": {
                     "overload": [
                         {
                             "overMemory": 100.0
                         }
                     ],
                     "normal": [
                         {
                             "overMemory": 300.0
                         }
                     ]
                 },
                 "overTemperature": {
                     "overload": [
                         {
                             "overTemperature": 1.0,
                             "time": 30.0
                         }
                     ],
                     "normal": [
                         {
                             "overTemperature": 0.0,
                             "time": 30.0
                         }
                     ]
                 }
             }
         },
         "normal_level": [
             "test"
         ],
     }
     */
    /// updateConfigInfo
    /// - Parameter dictionary: Settings
    public func updateWithDic(dictionary: [String: Any]) {
        pthread_rwlock_wrlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        self.enableDowngrade = dictionary["enable_downgrade"] as? Bool ?? false
        self.normalLevel = dictionary["normal_level"] as? [String] ?? []
        self.downgradeIntervalTime  = dictionary["downgradeIntervalTime"] as? Double ?? 10 //降级间隔
        self.normalInervalTime  = dictionary["normalInervalTime"] as? Double ?? 20 //升级间隔
        //防止无法关闭问题
        if !self.enableDowngrade { return }
        //遍历级别
        for rules in dictionary["rules"] as? Dictionary<String,Any> ?? [:] {
            if let levelRulesk = LarkDowngradeLevel(rawValue: rules.key) {
                var levelRule: Dictionary<LarkDowngradeIndex,LarkDowngradeRule> = [:]
                for rules_info in rules.value as? Dictionary<String, [String: Any]> ?? [:] {
                    if let rulesInfoIndex = LarkDowngradeIndex(rawValue: rules_info.key) {
                        let gradeRule = LarkDowngradeRule()
                        gradeRule.updateWithDic(dictionary: rules_info.value)
                        levelRule[rulesInfoIndex] = gradeRule
                    }
                }
                self.normalRules[levelRulesk] = levelRule
            }
        }
    }
}
