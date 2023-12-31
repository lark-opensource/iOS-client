//
//  StrategyEngineSceneCache.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/17.

import Foundation
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkPolicyEngine
import LarkContainer
import LarkAccountInterface
import UniverseDesignToast
import LarkCache

fileprivate protocol CacheChangeActionContainer: AnyObject {
    /// 判断container中持有的实体是否为空
    var isNil: Bool { get }
    /// container实际持有的实体
    var action: SecurityPolicyCacheChangeAction? { get }
    var identifier: String? { get }
    func handleCacheAdd(newValues: [String: SceneLocalCache])
    func handleCacheUpdate(oldValues: [String: SceneLocalCache], overwriteValues: [String: SceneLocalCache])
    
}

extension WeakWrapper: CacheChangeActionContainer {
    fileprivate var isNil: Bool {
        action == nil
    }
    fileprivate var action: SecurityPolicyCacheChangeAction? {
        value as? SecurityPolicyCacheChangeAction
    }
    fileprivate var identifier: String? {
        action?.identifier
    }
    
    fileprivate func handleCacheAdd(newValues: [String: SceneLocalCache]) {
        action?.handleCacheAdd(newValues: newValues)
    }
    
    fileprivate func handleCacheUpdate(oldValues: [String: SceneLocalCache], overwriteValues: [String: SceneLocalCache]) {
        action?.handleCacheUpdate(oldValues: oldValues, overwriteValues: overwriteValues)
    }
}

final class StrategyEngineSceneCache: UserResolverWrapper, SecurityPolicyCacheProtocol {
    
    private let factory: DynamicCacheFactory
    let userResolver: UserResolver
    @SafeWrapper private var observers = [CacheChangeActionContainer]()
    
    init(resolver: UserResolver) throws {
        self.userResolver = resolver
        factory = try DynamicCacheFactory(userResolver: userResolver)
    }
    
    func isNeedDelete(policyModel: PolicyModel) -> Bool {
        let taskID = policyModel.taskID
        guard let policyModel = PolicyModel.policyModel(taskID: taskID),
              let storage = factory.cache(policyModel.pointKey),
              let reuslt: SceneLocalCache = storage.read(forKey: taskID) else { return false }
        return reuslt.needDelete ?? false
    }
    
    func getAllCache() -> [SceneLocalCache] {
        factory.caches.reduce([SceneLocalCache](), { $0 + $1.value.getAllRealCache() })
    }
    
    func read(policyModel: LarkSecurityComplianceInterface.PolicyModel) -> SceneLocalCache? {
        guard let cache = factory.cache(policyModel.pointKey) else { return nil }
        let key = policyModel.taskID
        return cache.read(forKey: key)
    }
    
    func merge(_ newValue: [String: ValidateResponse], expirationTime: CFTimeInterval? = nil) {
        guard !newValue.isEmpty else {
            return
        }
        var oldValues: [String: SceneLocalCache] = [:]
        var updateValues: [String: SceneLocalCache] = [:]
        var newValues: [String: SceneLocalCache] = [:]
        newValue.forEach { (taskID, value) in
            autoreleasepool {
                guard let policyModel = PolicyModel.policyModel(taskID: taskID),
                      let storage = factory.cache(policyModel.pointKey) else { return }
                let cache = SceneLocalCache(taskID: taskID, validateResponse: value, expirationTime: expirationTime)
                if let oldValue: SceneLocalCache = storage.read(forKey: taskID) {
                    oldValues[taskID] = oldValue
                    updateValues[taskID] = cache
                } else {
                    newValues[taskID] = cache
                }
                storage.write(value: cache, forKey: taskID)
            }
        }
        observers.forEach { observer in
            observer.handleCacheAdd(newValues: newValues)
            observer.handleCacheUpdate(oldValues: oldValues, overwriteValues: updateValues)
        }
    }
    
    func clear() {
        factory.caches.forEach { $0.value.cleanAll() }
    }
    
    func registerCacheChangeObserver(observer: SecurityPolicyCacheChangeAction) {
        guard !observers.contains(where: { $0.identifier == observer.identifier }) else {
            SCLogger.info("Security policy cache observer \(observer.identifier) has registered")
            return
        }
        let ob = observer as AnyObject
        observers.append(WeakWrapper(value: ob))
        SCLogger.info("Security policy cache observer \(observer.identifier) register success")
    }
    
    func removeCacheChangeObserver(observer: SecurityPolicyCacheChangeAction) {
        guard !observers.contains(where: { $0.identifier == observer.identifier }) else {
            SCLogger.info("Security policy cache observer \(observer.identifier) remove failed")
            return
        }
        observers.removeAll { $0.identifier == observer.identifier || $0.isNil }
        SCLogger.info("Security policy cache observer \(observer.identifier) remove success")
    }
    
    func markInvalid() {
        FIFOCache.writeCacheQueue.async { [weak self] in
            guard let self else { return }
            self.factory.caches.forEach { $0.value.markInvalid() }
        }
    }
    
    func getSceneCacheSize() -> Int {
        factory.caches.reduce(0, { $0 + $1.value.count })
    }
    
    func getSceneCacheHeadAndTail() -> String? {
        factory.caches.reduce("", { $0 + "\n\n" + $1.value.getSceneCacheHeadAndTail() })
    }
}
