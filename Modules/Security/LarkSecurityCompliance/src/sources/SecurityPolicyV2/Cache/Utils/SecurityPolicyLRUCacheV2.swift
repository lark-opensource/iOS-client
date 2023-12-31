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

extension SecurityPolicyV2 {
    // 底层使用 LarkCache，通过 LarkCache 缓存的数据可以通过通用设置清除缓存来清除，无豁免路径
    class LRUCache: SecurityPolicyCache {
        var type: CacheType {
            .lru(maxSize: self.maxSize)
        }
        var count: Int { cache.diskCache?.totalCount() ?? 0 }

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
                SCLogger.error("failed to write cache value, error: \(error)", additionalData: ["cacheKey": cacheKey, "rawKey": rawKey])
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
                SCLogger.error("failed to read cache value, error: \(error)", additionalData: ["cacheKey": cacheKey, "rawKey": rawKey])
                return nil
            }
        }

        func removeValue(forKey rawKey: String) {
            let key = rawKey.md5()
            cache.removeObject(forKey: key)
        }
        
        func contains(forKey rawKey: String) -> Bool {
            cache.containsObject(forKey: rawKey)
        }

        /// 触发缓存清理
        func cleanAll() {
            cache.removeAllObjects()
        }
        
        var isEmpty: Bool {
            cache.totalDiskSize == 0
        }
    }
}
