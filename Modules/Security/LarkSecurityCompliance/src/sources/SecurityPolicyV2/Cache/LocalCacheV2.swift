//
//  LocalCache.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/10/11.
//

import Foundation
import LarkAccountInterface
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkContainer
import LarkCache
import LarkPolicyEngine

extension SecurityPolicyV2 {
    final class LocalCache {

        private static let writeCacheQueue = DispatchQueue(label: "security_policy_local_cache", qos: .background)

        private let storage: SCKeyValueStorage

        private let cacheKey: String

        init(cacheKey: String, userID: String) {
            self.cacheKey = cacheKey
            self.storage = SCKeyValue.MMKVEncrypted(userId: userID)
        }

        func writeCache<T: Codable>(value: T) {
            Self.writeCacheQueue.async { [weak self] in
                guard let self else { return }
                SecurityPolicy.logger.info("security policy:local_cache: \(self.cacheKey) write local cache")
                self.storage.set(value, forKey: self.cacheKey)
            }
        }

        func readCache<T: Codable>() -> T? {
            let result: T? = storage.value(forKey: cacheKey)
            guard let result else {
                SecurityPolicy.logger.info("security policy:local_cache: \(cacheKey) local cache is empty")
                return nil
            }
            return result
        }

        func clear() {
            Self.writeCacheQueue.async { [weak self] in
                guard let self else { return }
                SecurityPolicy.logger.info("security policy:local_cache: \(self.cacheKey) clear local cache")
                self.storage.removeObject(forKey: self.cacheKey)
            }
        }
    }
}
