//
//  SecurityPolicyCacheProtocol.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/23.
//

import Foundation
import LarkPolicyEngine
import LarkSecurityComplianceInterface

public protocol SecurityPolicyCacheChangeAction: AnyObject {
    var identifier: String { get }
    func handleCacheAdd(newValues: [String: SceneLocalCache])
    func handleCacheUpdate(oldValues: [String: SceneLocalCache], overwriteValues: [String: SceneLocalCache])
}
public protocol SecurityPolicyCacheProtocol {
    func read(policyModel: PolicyModel) -> SceneLocalCache?
    func merge(_ newValue: [String: ValidateResponse], expirationTime: CFTimeInterval?)
    func clear()
    func markInvalid()
    func isNeedDelete(policyModel: PolicyModel) -> Bool
    func registerCacheChangeObserver(observer: SecurityPolicyCacheChangeAction)
    func removeCacheChangeObserver(observer: SecurityPolicyCacheChangeAction)
    
    // For debug,之后迁移
    func getSceneCacheSize() -> Int
    func getSceneCacheHeadAndTail() -> String?
    func getAllCache() -> [SceneLocalCache]
}
