//
//  SecurityPolicyDataRetrievalProtocol.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/12/21.
//

import Foundation
import LarkContainer
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface
import ThreadSafeDataStructure
import LarkPolicyEngine

protocol SecurityPolicyDataRetrievalProtocol {
    static var identifier: String { get }
    
    var isEmpty: Bool { get }

    init(userResolver: UserResolver)

    func read(key: String) -> SecurityPolicyValidateResultCache?
    
    func cleanAll()
}

extension SecurityPolicyV2 {
    public struct SecurityPolicyV1DataRetriever: SecurityPolicyDataRetrievalProtocol {
        public static let identifier = "V1"
        let staticResultCache: [String: ValidateResponse]
        let isEmpty: Bool
        private let localCache: LocalCache
        
        public init(userResolver: UserResolver) {
            localCache = LocalCache(cacheKey: SecurityPolicyV2.SecurityPolicyConstKey.staticCacheLocalCachePath, 
                                    userID: userResolver.userID)
            staticResultCache = localCache.readCache() ?? [:]
            isEmpty = staticResultCache.isEmpty
        }
        
        public func read(key: String) -> SecurityPolicyValidateResultCache? {
            guard let response = staticResultCache[key] else { return nil }
            return SecurityPolicyValidateResultCache(taskID: key, validateResponse: response)
        }
        
        func cleanAll() {
            localCache.clear()
        }
    }
    
    public struct SecurityPolicyV2DataRetriever: SecurityPolicyDataRetrievalProtocol {
        public static let identifier = "V2"
        let isEmpty: Bool
        private let localCache: LRUCache
        
        public init(userResolver: UserResolver) {
            self.localCache = LRUCache(userID: userResolver.userID,
                                       maxSize: SecurityPolicyV2.SecurityPolicyConstKey.staticCacheMaxCapacity,
                                       cacheKey: SecurityPolicyV2.SecurityPolicyConstKey.staticCacheKey)
            isEmpty = localCache.isEmpty
        }
        
        public func read(key: String) -> SecurityPolicyValidateResultCache? {
            localCache.read(forKey: key)
        }
        
        func cleanAll() {
            localCache.cleanAll()
        }
    }
}
