//
//  SecurityPolicyLRUCache.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/6/16.
//

import Foundation
import LarkContainer
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface
import ThreadSafeDataStructure
import LarkCache

class LRUCache: CacheProtocol {
    var type: CacheType {
        .lru(maxSize: self.maxSize)
    }
    private let maxSize: Int
    private let cacheKey: String
    private let cache: CryptoCache
    
    required init(userID: String, maxSize: Int, cacheKey: String) {
        cache = securityComplianceCache(userID, .securityPolicy(subBiz: cacheKey))
        cache.memoryCache?.countLimit = UInt(maxSize)
        cache.diskCache?.countLimit = UInt(maxSize)
        self.cacheKey = cacheKey
        self.maxSize = maxSize
    }
    
    func write<T: Codable>(value: T, forKey rawKey: String) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(value)
            cache.set(object: data, forKey: rawKey.md5())
        } catch {
            SCLogger.info("failed to write cache value, error: \(error)", additionalData: ["cacheKey": cacheKey, "rawKey": rawKey])
        }
    }
    
    func read<T>(forKey rawKey: String) -> T? where T: Decodable, T: Encodable {
        let decoder = JSONDecoder()
        let key = rawKey.md5()
        guard let data: Data = cache.object(forKey: key) else { return nil }
        do {
            let response = try decoder.decode(T.self, from: data)
            return response
        } catch {
            SCLogger.info("failed to read cache value, error: \(error)", additionalData: ["cacheKey": cacheKey, "rawKey": rawKey])
            return nil
        }
    }
    
    /// 触发缓存清理
    func cleanAll() {
        cache.removeAllObjects()
    }
}
