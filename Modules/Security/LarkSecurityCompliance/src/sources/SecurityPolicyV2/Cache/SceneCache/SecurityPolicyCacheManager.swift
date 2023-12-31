//
//  SecurityPolicyCacheManager.swift
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

fileprivate protocol CacheChangeEventContainer: AnyObject {
    /// 判断container中持有的实体是否为空
    var isNil: Bool { get }
    /// container实际持有的实体
    var action: SecurityPolicyCacheChangeEvent? { get }
    var identifier: String? { get }
    func handleCacheAdd(newValues: [String: SecurityPolicyValidateResultCache])
    func handleCacheUpdate(oldValues: [String: SecurityPolicyValidateResultCache], overwriteValues: [String: SecurityPolicyValidateResultCache])

}

extension WeakWrapper: CacheChangeEventContainer {
    fileprivate var isNil: Bool {
        action == nil
    }
    fileprivate var action: SecurityPolicyCacheChangeEvent? {
        value as? SecurityPolicyCacheChangeEvent
    }
    fileprivate var identifier: String? {
        action?.identifier
    }

    fileprivate func handleCacheAdd(newValues: [String: SecurityPolicyValidateResultCache]) {
        action?.handleCacheAdd(newValues: newValues)
    }

    fileprivate func handleCacheUpdate(oldValues: [String: SecurityPolicyValidateResultCache], overwriteValues: [String: SecurityPolicyValidateResultCache]) {
        action?.handleCacheUpdate(oldValues: oldValues, overwriteValues: overwriteValues)
    }
}

extension SecurityPolicyV2 {
    final class SecurityPolicyCacheManager {
        private let factory: CacheFactory
        @SafeWrapper private var observers = [CacheChangeEventContainer]()

        init(resolver: UserResolver) throws {
            factory = try CacheFactory(userResolver: resolver)
        }

        private func convertToIdentifier(pointKey: PointKey) -> String? {
            pointKey.isScene ? pointKey.rawValue : SecurityPolicyConstKey.staticCacheKey
        }
    }
}

extension SecurityPolicyV2.SecurityPolicyCacheManager: SecurityPolicyCacheService {
    func notify(validateResult: SecurityPolicyV2.StrategyEngineCallerObserverParam) {
        var successed: [String: SecurityPolicyValidateResultCache] = [:]
        validateResult.policyResponseMap.forEach {
            switch $0.value.type {
            case .downgrade:
                return
            default:
                successed.updateValue(SecurityPolicyValidateResultCache(taskID: $0.key, validateResponse: $0.value),
                                      forKey: $0.key)
            }
        }
        add(successed)
    }

    func add(_ newValue: [String: SecurityPolicyValidateResultCache]) {
        guard !newValue.isEmpty else { return }
        var oldValues: [String: SecurityPolicyValidateResultCache] = [:]
        var updateValues: [String: SecurityPolicyValidateResultCache] = [:]
        var newValues: [String: SecurityPolicyValidateResultCache] = [:]
        newValue.forEach { (taskID, value) in
            autoreleasepool {
                guard let policyModel = PolicyModel.policyModel(taskID: taskID),
                      let identifier = convertToIdentifier(pointKey: policyModel.pointKey),
                      let storage = factory.cache(identifier) else { return }
                if let oldValue: SecurityPolicyValidateResultCache = storage.read(forKey: taskID) {
                    oldValues[taskID] = oldValue
                    updateValues[taskID] = value
                } else {
                    newValues[taskID] = value
                }
                if identifier == PointKey.imFileRead.rawValue,
                   storage.count % 100 == 0 {
                    SecurityPolicyEventTrack.scsSecurityPolicyDynamicCapacity(pointKey: identifier,
                                                                              current: storage.count)
                }
                if identifier == SecurityPolicyV2.SecurityPolicyConstKey.staticCacheKey,
                   storage.count > 17 {
                    SecurityPolicyV2.SecurityPolicyEventTrack.larkStaticCacheCountError(count: storage.count)
                }
                storage.write(value: value, forKey: taskID)
            }
        }
        DispatchQueue.runOnMainQueue {
            self.observers.forEach { observer in
                observer.handleCacheAdd(newValues: newValues)
                observer.handleCacheUpdate(oldValues: oldValues, overwriteValues: updateValues)
            }
        }
    }

    func value(policyModel: PolicyModel) -> SecurityPolicyValidateResultCache? {
        guard let identifier = convertToIdentifier(pointKey: policyModel.pointKey),
              let cache = factory.cache(identifier) else { return nil }
        return cache.read(forKey: policyModel.taskID)
    }

    func removeValue(_ taskIDs: [String]) {
        taskIDs.forEach { taskID in
            autoreleasepool {
                guard let policyModel = PolicyModel.policyModel(taskID: taskID),
                      let identifier = convertToIdentifier(pointKey: policyModel.pointKey),
                      let cache = factory.cache(identifier) else { return }
                cache.removeValue(forKey: taskID)
            }
        }
    }

    func removeAll() {
        factory.caches.forEach {
            $0.value.cleanAll()
        }
    }

    func registerCacheChangeObserver(observer: SecurityPolicyCacheChangeEvent) {
        guard !observers.contains(where: { $0.identifier == observer.identifier }) else {
            SCLogger.info("Security policy cache observer \(observer.identifier) has registered")
            return
        }
        let ob = observer as AnyObject
        observers.append(WeakWrapper(value: ob))
        SCLogger.info("Security policy cache observer \(observer.identifier) register success")
    }

    func removeCacheChangeObserver(observer: SecurityPolicyCacheChangeEvent) {
        guard !observers.contains(where: { $0.identifier == observer.identifier }) else {
            SCLogger.info("Security policy cache observer \(observer.identifier) remove failed")
            return
        }
        observers.removeAll { $0.identifier == observer.identifier || $0.isNil }
        SCLogger.info("Security policy cache observer \(observer.identifier) remove success")
    }
}

extension SecurityPolicyV2.SecurityPolicyCacheManager {
    func markInvalid() {
        SecurityPolicyV2.FIFOCache.writeCacheQueue.async { [weak self] in
            guard let self else { return }
            let identifier = PointKey.imFileRead.rawValue
            let cache = self.factory.cache(identifier) as? SecurityPolicyV2.FIFOCache
            cache?.markInvalid()
            SecurityPolicy.logger.info("security policy mark result cache need deleted")
        }
    }
}
