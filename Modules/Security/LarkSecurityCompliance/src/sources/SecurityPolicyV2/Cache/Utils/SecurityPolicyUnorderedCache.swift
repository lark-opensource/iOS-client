//
//  SecurityPolicyUnorderedCache.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/12/19.
//

import Foundation
import ThreadSafeDataStructure
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface
import LarkPolicyEngine

extension SecurityPolicyV2 {
    public class UnorderedCache: SecurityPolicyCache {
        let type = SecurityPolicyV2.CacheType.unordered
        let store: SCKeyValueStorage
        let count = 0
        
        public required init(userID: String, maxSize: Int, cacheKey: String) {
            self.store = SCKeyValue.MMKV(userId: userID, business: .securityPolicy(subBiz: cacheKey))
        }
        
        func write<T>(value: T, forKey rawKey: String) where T: Decodable, T: Encodable {
            store.set(value, forKey: rawKey)
        }
        
        func read<T>(forKey rawKey: String) -> T? where T: Decodable, T: Encodable {
            store.value(forKey: rawKey)
        }
        
        func removeValue(forKey rawKey: String) {
            store.removeObject(forKey: rawKey)
        }
        
        func cleanAll() {
            store.clearAll()
        }
        
        func contains(forKey rawKey: String) -> Bool {
            store.contains(key: rawKey)
        }
    }
}
