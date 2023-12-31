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

final class DynamicCacheFactory {
    let userResolver: UserResolver
    private var disableDynamicCache: Bool
    private var dynamicPointkeyMaxCacheSize: [PointKey: Int] = [:]
    private var lruCacheSize: [PointKey: Int] = [:]
    @SafeWrapper private(set) var caches: [PointKey: CacheProtocol] = [:]
    private var cacheTypeMap: [PointKey: CacheProtocol.Type] = [:]
    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        let scSettings = try userResolver.resolve(type: SCSettingService.self)
        let settings = try? userResolver.resolve(assert: Settings.self)
        disableDynamicCache = (settings?.disableDynamicCache).isTrue
        let key = SCSettingKey.dynamicPointkeyMaxCacheSize
        dynamicPointkeyMaxCacheSize = getDynamicPointkeyMaxCacheSize(cacheSizeMap: scSettings.dictionary(key))
        lruCacheSize = getDynamicPointkeyMaxCacheSize(cacheSizeMap: scSettings.dictionary(SCSettingKey.lruCacheSize) )

        guard !disableDynamicCache else { return }
        let service = try userResolver.resolve(assert: PassportUserService.self)
        dynamicPointkeyMaxCacheSize.forEach {
            let storage = FIFOCache(userID: service.user.userID, maxSize: $0.value, cacheKey: $0.key.rawValue)
            caches.updateValue(storage, forKey: $0.key)
            cacheTypeMap[$0.key] = FIFOCache.self
        }
        
        lruCacheSize.forEach {
            cacheTypeMap[$0.key] = LRUCache.self
        }
    }
    
    func cache(_ pointKey: PointKey) -> CacheProtocol? {
        guard !disableDynamicCache else {
            return nil
        }
        
        guard let userService = try? userResolver.resolve(assert: PassportUserService.self)  else {
            return nil
        }
        
        // caches中存在cache，直接返回cache
        if let cache = caches[pointKey] {
            return cache
        }
        
        // 不存在cache，创建cache并返回，同时将cache放入caches中
        guard let cacheType = cacheTypeMap[pointKey] else {
            SCLogger.info("get cache type failed", additionalData: ["pointKey": pointKey.rawValue])
            return nil
        }
        let cache = cacheType.init(userID: userService.user.userID, maxSize: maxSize(pointKey), cacheKey: pointKey.rawValue)
        caches[pointKey] = cache
        return cache
    }
    
    func maxSize(_ pointkey: PointKey) -> Int {
        if let maxSize = dynamicPointkeyMaxCacheSize[pointkey] {
            return maxSize
        } else if let maxSize = lruCacheSize[pointkey] {
            return maxSize
        }
        return Int.max
    }
    
    private func getDynamicPointkeyMaxCacheSize(cacheSizeMap: [String: Int]) -> [PointKey: Int] {
        var cacheSize: [PointKey: Int] = [:]
        cacheSizeMap.forEach({ (key, value) in
            guard let pointKey = PointKey(rawValue: SecurityPolicyConstKey.pointKeyPrefix + key) else {
                return
            }
            cacheSize[pointKey] = value
        })
        return cacheSize
    }
}
