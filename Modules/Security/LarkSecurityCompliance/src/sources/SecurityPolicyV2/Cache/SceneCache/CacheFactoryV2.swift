//
//  CacheFactory.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/23.
//

import Foundation
import LarkContainer
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkAccountInterface

extension SecurityPolicyV2 {
    final class CacheFactory {
        let userResolver: UserResolver
        private let userService: PassportUserService
        private var maxCacheSize: [String: Int] = [:]
        private var cacheTypeMap: [String: SecurityPolicyCache.Type] = [:]
        @SafeWrapper private(set) var caches: [String: SecurityPolicyCache] = [:]

        init(userResolver: UserResolver) throws {
            self.userResolver = userResolver
            userService = try userResolver.resolve(assert: PassportUserService.self)
            let scSettings = try userResolver.resolve(type: SCSettingService.self)

            cacheTypeMap[SecurityPolicyConstKey.staticCacheKey] = UnorderedCache.self
            maxCacheSize[SecurityPolicyConstKey.staticCacheKey] = SecurityPolicyConstKey.staticCacheMaxCapacity
            let disableShareCache = scSettings.bool(.disableFileStrategyShareCache)
            let disableDynamicCache = scSettings.bool(.disableDynamicCache)
            if !disableDynamicCache {
                var pointKeyAndSizeAndTypeMap: [[String: Int]: SecurityPolicyCache.Type] = [
                    getDynamicPointkeyMaxCacheSize(cacheSizeMap: scSettings.dictionary(.lruCacheSize)): LRUCache.self
                ]
                if !disableShareCache {
                    pointKeyAndSizeAndTypeMap.updateValue(FIFOCache.self,
                                                          forKey: getDynamicPointkeyMaxCacheSize(cacheSizeMap: scSettings.dictionary(.dynamicPointkeyMaxCacheSize)))
                }
                pointKeyAndSizeAndTypeMap.forEach { (pointKeySizeMap, cacheType) in
                    pointKeySizeMap.forEach {
                        cacheTypeMap[$0.key] = cacheType
                        maxCacheSize[$0.key] = $0.value
                    }
                }
            }
        }

        func cache(_ identifier: String) -> SecurityPolicyCache? {
            // caches中存在cache，直接返回cache
            if let cache = caches[identifier] {
                return cache
            }
            // 不存在cache，创建cache并返回，同时将cache放入caches中
            if let cacheType = cacheTypeMap[identifier] {
                let cache = cacheType.init(userID: userService.user.userID,
                                           maxSize: maxCacheSize[identifier] ?? Int.max,
                                           cacheKey: identifier)
                caches[identifier] = cache
                return cache
            }
            SCLogger.info("get cache type failed", additionalData: ["identifier": identifier])
            return nil
        }

        private func getDynamicPointkeyMaxCacheSize(cacheSizeMap: [String: Int]) -> [String: Int] {
            var cacheSize: [String: Int] = [:]
            cacheSizeMap.forEach({ (key, value) in
                let rawPointKey = SecurityPolicyConstKey.pointKeyPrefix + key
                cacheSize[rawPointKey] = value
            })
            return cacheSize
        }
    }
}
