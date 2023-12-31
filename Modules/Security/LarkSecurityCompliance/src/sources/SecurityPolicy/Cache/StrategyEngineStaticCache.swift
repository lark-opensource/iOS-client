//
//  StrategyEngineStaticCache.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/10/20.
//

import Foundation
import LarkPolicyEngine
import LarkSecurityComplianceInfra
import LarkContainer
import LarkAccountInterface
import ThreadSafeDataStructure

final class StrategyEngineStaticCache {

    private var safeMemoryCache: SafeAtomic<[String: ValidateResponse]> = [:] + .readWriteLock
    private var memoryCache: [String: ValidateResponse] {
        get { safeMemoryCache.value }
        set { safeMemoryCache.value = newValue }
    }

    private let localCache: LocalCache

    init(userResolver: UserResolver) {
        let service = try? userResolver.resolve(assert: PassportUserService.self)
        localCache = LocalCache(cacheKey: SecurityPolicyConstKey.staticCacheCacheKey,
                                userID: service?.user.userID ?? "")
        memoryCache = localCache.readCache() ?? [:]
    }

    subscript(key: String) -> ValidateResponse? {
        memoryCache[key]
    }

    func getAllCache() -> [String: ValidateResponse] {
        memoryCache
    }

    func merge(_ newValue: [String: ValidateResponse]) {
        if newValue.isEmpty { return }
        memoryCache.merge(newValue) { _, newValue in newValue }
        writeLocalCache()
    }

    private func writeLocalCache() {
        localCache.writeCache(value: memoryCache)
    }

    func clear() {
        memoryCache = [:]
        localCache.clear()
    }

    func clearByTaskID(needClear: [String]) {
        needClear.forEach { memoryCache.removeValue(forKey: $0) }
        writeLocalCache()
    }
}
