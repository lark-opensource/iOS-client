//
//  SecurityPolicyCacheService.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/23.
//

import Foundation
import LarkPolicyEngine
import LarkSecurityComplianceInterface

public protocol SecurityPolicyCacheChangeEvent: AnyObject {
    var identifier: String { get }
    func handleCacheAdd(newValues: [String: SecurityPolicyValidateResultCache])
    func handleCacheUpdate(oldValues: [String: SecurityPolicyValidateResultCache], overwriteValues: [String: SecurityPolicyValidateResultCache])
}
public protocol SecurityPolicyCacheService: StrategyEngineCallerObserver {
    func value(policyModel: PolicyModel) -> SecurityPolicyValidateResultCache?
    func add(_ newValue: [String: SecurityPolicyValidateResultCache])
    func removeValue(_ taskIDs: [String])
    func removeAll()
    func registerCacheChangeObserver(observer: SecurityPolicyCacheChangeEvent)
    func removeCacheChangeObserver(observer: SecurityPolicyCacheChangeEvent)
}
